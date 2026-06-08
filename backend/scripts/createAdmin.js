const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const bcrypt = require("bcrypt");
const db = require("../config/db");

(async () => {
    try {
        const email = "admin@gachamerch.com";
        const password = "admin";
        
        const [rows] = await db.execute("SELECT * FROM users WHERE email=?", [email]);
        if (rows.length > 0) {
            console.log("Akun admin@gachamerch.com sudah ada. Update role ke admin...");
            await db.execute("UPDATE users SET role='admin' WHERE email=?", [email]);
            // Also upgrade reiikierana@gmail.com
            await db.execute("UPDATE users SET role='admin' WHERE email=?", ["reiikierana@gmail.com"]);
            console.log("Berhasil.");
        } else {
            const hash = await bcrypt.hash(password, 10);
            await db.execute(
                "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)",
                ["Administrator", email, hash, "admin"]
            );
            console.log("Akun admin baru berhasil dibuat:");
            console.log("Email: admin@gachamerch.com");
            console.log("Password: admin");
            
            // Also try to upgrade reiikierana@gmail.com if it exists
            const [rows2] = await db.execute("UPDATE users SET role='admin' WHERE email=?", ["reiikierana@gmail.com"]);
            if (rows2.affectedRows > 0) {
                console.log("Akun reiikierana@gmail.com juga telah diupgrade menjadi admin.");
            }
        }
    } catch (err) {
        console.error("Gagal membuat admin:", err);
    } finally {
        await db.end();
    }
})();
