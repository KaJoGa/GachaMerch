require("dotenv").config();
const express = require("express");
const cors = require("cors");

const weaponRoutes = require("./routes/weaponRoutes");
const foodRoutes = require("./routes/foodRoutes");
const authRoutes = require("./routes/authRoutes");
const listingRoutes = require("./routes/listingRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const verifyToken = require("./middleware/authMiddleware");
const dbGuard = require("./middleware/dbGuard");
const db = require("./config/db");
const { isDbDownError, dbDownMessage } = require("./utils/dbError");

const app = express();

app.use(cors());
app.use(express.json());

// Cek koneksi DB sebelum tiap request masuk ke controller.
// Kalau XAMPP/MySQL mati → balas 503 jelas, bukan 500 kriptik.
app.use(dbGuard);

app.use("/", weaponRoutes);
app.use("/", foodRoutes);
app.use("/", listingRoutes);
app.use("/", transactionRoutes);
app.use("/auth", authRoutes);

app.get("/profile", verifyToken, (req, res) => {
    res.json({
        message: "Protected route",
        user: req.user
    });
});

// Error handler terakhir: nangkap error DB yang lolos saat request berjalan
// (misal MySQL mati di tengah jalan, dalam window cache dbGuard).
app.use((err, req, res, next) => {
    if (isDbDownError(err)) {
        console.error(`[app] DB error during request (${err.code}): ${err.message}`);
        return res.status(503).json({ error: dbDownMessage(err) });
    }
    console.error("[app] Unhandled error:", err);
    res.status(500).json({ error: "Internal server error" });
});

app.listen(3000, () => {
    console.log("Server running http://127.0.0.1:3000");

    // Cek koneksi DB saat startup → kasih peringatan jelas kalau XAMPP belum jalan.
    db.getConnection()
        .then((conn) => {
            conn.release();
            console.log("Database connected (XAMPP MySQL OK).");
        })
        .catch((err) => {
            if (isDbDownError(err)) {
                console.warn("\n[WARNING] " + dbDownMessage(err));
                console.warn("Server is up, but every request will return 503 until the database is reachable.\n");
            } else {
                console.error("[startup] Unexpected DB error:", err);
            }
        });
});