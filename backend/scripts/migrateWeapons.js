const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

// Migrasi idempotent: menambahkan kolom yang diwajibkan target.md
// (type, description, stock, price) ke tabel `weapons` bila belum ada.
// MySQL 8 tidak mendukung "ADD COLUMN IF NOT EXISTS", jadi kita cek dulu
// lewat information_schema sebelum ALTER.
const COLUMNS = [
  { name: "type", ddl: "ADD COLUMN type VARCHAR(50) NOT NULL DEFAULT 'Sword'" },
  { name: "description", ddl: "ADD COLUMN description TEXT NULL" },
  { name: "stock", ddl: "ADD COLUMN stock INT NOT NULL DEFAULT 0" },
  { name: "price", ddl: "ADD COLUMN price INT NOT NULL DEFAULT 0" },
];

async function columnExists(column) {
  const [rows] = await db.execute(
    `SELECT COUNT(*) AS n
       FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'weapons'
        AND COLUMN_NAME = ?`,
    [process.env.DB_NAME, column]
  );
  return rows[0].n > 0;
}

(async () => {
  try {
    for (const col of COLUMNS) {
      if (await columnExists(col.name)) {
        console.log(`- kolom "${col.name}" sudah ada, dilewati`);
        continue;
      }
      await db.query(`ALTER TABLE weapons ${col.ddl}`);
      console.log(`+ kolom "${col.name}" ditambahkan`);
    }
    console.log("Migrasi weapons selesai.");
  } catch (err) {
    console.error("Migrasi gagal:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
