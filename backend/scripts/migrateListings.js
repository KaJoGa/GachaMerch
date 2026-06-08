const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

// Tabel `listings` = daftar item yang sedang DIJUAL.
// Item master (weapons/foods) tetap jadi katalog read-only; admin membuat
// listing dari item yang ada (polymorphic via item_type + item_id), lalu
// mengatur harga & stok jual sendiri. UNIQUE(item_type,item_id) mencegah
// satu item dilisting dua kali.
const CREATE_SQL = `
CREATE TABLE IF NOT EXISTS listings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_type ENUM('weapon','food') NOT NULL,
  item_id INT NOT NULL,
  price INT NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_item (item_type, item_id)
)`;

(async () => {
  try {
    await db.query(CREATE_SQL);
    console.log("Tabel `listings` siap.");
  } catch (err) {
    console.error("Migrasi listings gagal:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
