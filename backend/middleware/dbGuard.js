const db = require("../config/db");
const { isDbDownError, dbDownMessage } = require("../utils/dbError");

// Cache hasil ping biar tidak ping DB di setiap request saat DB sehat.
// Kalau ping terakhir sukses < TTL lalu, langsung lewat.
const PING_TTL_MS = 5000;
let lastOkAt = 0;

// Middleware: pastikan DB bisa dihubungi sebelum request masuk ke controller.
// Kalau XAMPP/MySQL mati → balas 503 dengan pesan jelas, bukan 500 kriptik.
async function dbGuard(req, res, next) {
    if (Date.now() - lastOkAt < PING_TTL_MS) return next();

    let conn;
    try {
        conn = await db.getConnection();
        await conn.ping();
        lastOkAt = Date.now();
        next();
    } catch (err) {
        if (isDbDownError(err)) {
            console.error(`[dbGuard] DB unreachable (${err.code}): ${err.message}`);
            return res.status(503).json({ error: dbDownMessage(err) });
        }
        next(err); // error lain → biarkan controller/handler lain yang urus
    } finally {
        if (conn) conn.release();
    }
}

module.exports = dbGuard;
