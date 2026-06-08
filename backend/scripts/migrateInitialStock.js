const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

// Tambah kolom `initial_stock` ke listings = stok awal saat listing dibuat /
// terakhir di-set admin. Dipakai untuk warna indikator stok di UI admin
// (hijau → kuning di 50% → merah di 20% ke bawah). Stok jalan tetap di `stock`;
// pembelian hanya mengurangi `stock`, bukan `initial_stock`.
// Idempotent: cek information_schema dulu sebelum ALTER.
(async () => {
  try {
    const [cols] = await db.execute(
      `SELECT COLUMN_NAME FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'listings'
          AND COLUMN_NAME = 'initial_stock'`,
      [process.env.DB_NAME]
    );

    if (cols.length === 0) {
      await db.query(
        "ALTER TABLE listings ADD COLUMN initial_stock INT NOT NULL DEFAULT 0 AFTER stock"
      );
      // Backfill: baris lama belum punya baseline → pakai stok saat ini.
      await db.query("UPDATE listings SET initial_stock = stock");
      console.log("Kolom `initial_stock` ditambahkan + di-backfill dari stock.");
    } else {
      console.log("Kolom `initial_stock` sudah ada — tidak ada perubahan.");
    }
  } catch (err) {
    console.error("Migrasi initial_stock gagal:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
