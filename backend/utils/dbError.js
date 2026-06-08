// Deteksi & terjemahkan error koneksi MySQL menjadi pesan yang jelas.
// Paling sering kepakai saat XAMPP belum di-start (port 3306 nolak koneksi).

// Kode error mysql2/driver yang menandakan DB tidak bisa dihubungi / salah konfigurasi.
const DB_DOWN_CODES = new Set([
    "ECONNREFUSED",            // MySQL mati / port salah → XAMPP belum di-start
    "PROTOCOL_CONNECTION_LOST", // koneksi putus di tengah jalan
    "ETIMEDOUT",               // host hidup tapi tidak merespons
    "ENOTFOUND",               // DB_HOST salah
    "ER_ACCESS_DENIED_ERROR",  // DB_USER / DB_PASSWORD salah
    "ER_BAD_DB_ERROR",         // DB_NAME tidak ada (belum import dump)
]);

// True kalau error berasal dari koneksi DB (bukan error logika biasa).
function isDbDownError(err) {
    return !!err && DB_DOWN_CODES.has(err.code);
}

// Pesan ramah (bahasa Inggris untuk user, sesuai standar UI) per jenis error.
function dbDownMessage(err) {
    switch (err && err.code) {
        case "ER_ACCESS_DENIED_ERROR":
            return "Database access denied. Check DB_USER/DB_PASSWORD in backend/.env.";
        case "ER_BAD_DB_ERROR":
            return `Database "${process.env.DB_NAME}" was not found. Import the SQL dump first.`;
        case "ENOTFOUND":
            return `Database host "${process.env.DB_HOST}" was not found. Check DB_HOST in backend/.env.`;
        default:
            return "Cannot reach the database. Make sure XAMPP MySQL is running (start it from the XAMPP Control Panel).";
    }
}

module.exports = { isDbDownError, dbDownMessage, DB_DOWN_CODES };
