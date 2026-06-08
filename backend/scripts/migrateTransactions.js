const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

// Tabel `transactions` = riwayat pembelian user.
// Menyimpan SNAPSHOT item_name & unit_price agar riwayat tetap utuh walau
// listing-nya nanti diubah harga / dihapus. listing_id boleh NULL kalau
// listing aslinya sudah tidak ada.
const CREATE_SQL = `
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  listing_id INT NULL,
  item_name VARCHAR(150) NOT NULL,
  quantity INT NOT NULL,
  unit_price INT NOT NULL,
  total_price INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)`;

(async () => {
  try {
    await db.query(CREATE_SQL);
    console.log("Tabel `transactions` siap.");
  } catch (err) {
    console.error("Migrasi transactions gagal:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
