const db = require("../config/db");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const { OAuth2Client } = require("google-auth-library");

// Client OAuth Google Cloud — dipakai untuk memverifikasi token dari frontend.
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

// Audience access token boleh salah satu dari client ID ini.
// Web pakai GOOGLE_CLIENT_ID; Android pakai GOOGLE_ANDROID_CLIENT_ID (isi bila perlu).
const ALLOWED_CLIENT_IDS = [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_ANDROID_CLIENT_ID,
].filter(Boolean);

exports.register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Validasi wajib isi.
        if (!name || !email || !password) {
            return res.status(400).json({ error: "Name, email, and password are required" });
        }

        // Validasi panjang: name & email maksimal 100 karakter.
        if (name.length > 100) {
            return res.status(400).json({ error: "Name must be at most 100 characters" });
        }
        if (email.length > 100) {
            return res.status(400).json({ error: "Email must be at most 100 characters" });
        }

        const hash = await bcrypt.hash(password, 10);

        // Generate Token saat register
        const token = crypto.randomBytes(20).toString("hex");

        // role default 'user'. Admin diset manual lewat DB.
        await db.execute(
            "INSERT INTO users (name,email,password,token,role) VALUES (?,?,?,?,?)",
            [name, email, hash, token, "user"]
        );

        res.json({ message: "User registered", token: token, role: "user" });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const [rows] = await db.execute(
            "SELECT * FROM users WHERE email=?",
            [email]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: "User not found" });
        }

        const user = rows[0];

        const match = await bcrypt.compare(password, user.password);

        if (!match) {
            return res.status(401).json({ error: "Wrong password" });
        }

        const token = crypto.randomBytes(20).toString("hex");

        await db.execute(
            "UPDATE users SET token=? WHERE id=?",
            [token, user.id]
        );

        res.json({
            message: "Login success",
            token: token,
            role: user.role
        });

    } catch (err) {
        console.error("[login] ERROR:", err);
        res.status(500).json({ error: err.message });
    }
};

exports.googleLogin = async (req, res) => {
    try {
        const { accessToken } = req.body;
        console.log("[google-login] request masuk, accessToken:", accessToken ? "ada" : "KOSONG");

        if (!accessToken) {
            return res.status(400).json({ error: "accessToken required" });
        }

        // 1) Verifikasi access token ke Google. getTokenInfo memanggil endpoint
        //    tokeninfo Google, jadi token dipastikan valid & belum kedaluwarsa.
        let tokenInfo;
        try {
            tokenInfo = await googleClient.getTokenInfo(accessToken);
        } catch (verifyErr) {
            console.warn("[google-login] DITOLAK: getTokenInfo gagal -", verifyErr.message);
            return res.status(401).json({ error: "Invalid Google access token" });
        }

        // Cegah token-substitution: token harus dikeluarkan untuk client kita.
        const audience = tokenInfo.aud || tokenInfo.azp;
        console.log("[google-login] token valid. aud=%s email=%s verified=%s", audience, tokenInfo.email, tokenInfo.email_verified);
        if (!ALLOWED_CLIENT_IDS.includes(audience)) {
            console.warn("[google-login] DITOLAK: audience tidak terdaftar di ALLOWED_CLIENT_IDS");
            return res.status(401).json({ error: "Token audience mismatch" });
        }

        // Email wajib ada & terverifikasi Google.
        if (!tokenInfo.email || tokenInfo.email_verified === false) {
            console.warn("[google-login] DITOLAK: email tidak ada / belum terverifikasi");
            return res.status(401).json({ error: "Google account email not verified" });
        }

        const email = tokenInfo.email;

        // 2) Ambil nama dari endpoint userinfo (cosmetic). Fallback ke prefix email.
        let name = email.split("@")[0];
        try {
            const profileRes = await fetch(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );
            if (profileRes.ok) {
                const profile = await profileRes.json();
                if (profile.name) name = profile.name;
            }
        } catch (_) {
            // abaikan — pakai fallback nama dari email
        }

        // Cek apakah user sudah ada
        const [rows] = await db.execute(
            "SELECT * FROM users WHERE email=?",
            [email]
        );

        let user;
        if (rows.length === 0) {
            // Jika belum ada, register otomatis
            // Password dikasih random karena login via google
            const randomPassword = crypto.randomBytes(16).toString("hex");
            const hash = await bcrypt.hash(randomPassword, 10);

            const [result] = await db.execute(
                "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
                [name, email, hash]
            );

            const [newUser] = await db.execute(
                "SELECT * FROM users WHERE id=?",
                [result.insertId]
            );
            user = newUser[0];
            console.log("[google-login] AUTO-REGISTER user baru: %s (id=%s)", email, user.id);
        } else {
            user = rows[0];
            console.log("[google-login] user lama ditemukan: %s (id=%s)", email, user.id);
        }

        // Generate Token (sesuai standar requirements: 20 chars alphanumeric)
        const token = crypto.randomBytes(20).toString("hex");

        await db.execute(
            "UPDATE users SET token=? WHERE id=?",
            [token, user.id]
        );
        console.log("[google-login] SUKSES, token diset untuk id=%s", user.id);

        res.json({
            message: "Login success",
            token: token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (err) {
        console.error("[google-login] ERROR:", err);
        res.status(500).json({ error: err.message });
    }
};