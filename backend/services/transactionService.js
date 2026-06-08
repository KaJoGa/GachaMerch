const db = require("../config/db");

// Buat transaksi pembelian secara ATOMIK:
// kunci baris listing (FOR UPDATE) → cek stok → kurangi stok → insert transaksi,
// semuanya dalam satu DB transaction supaya stok tidak bisa minus saat race.
async function createTransaction(userId, listingId, quantity) {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        const [rows] = await conn.execute(
            "SELECT id, item_type, item_id, price, stock FROM listings WHERE id = ? FOR UPDATE",
            [listingId]
        );

        if (rows.length === 0) {
            await conn.rollback();
            return { ok: false, status: 404, error: "Listing not found" };
        }

        const listing = rows[0];

        if (quantity > listing.stock) {
            await conn.rollback();
            return {
                ok: false,
                status: 400,
                error: `Not enough stock (only ${listing.stock} left)`,
            };
        }

        // Snapshot nama item dari tabel master.
        const table = listing.item_type === "weapon" ? "weapons" : "foods";
        const [itemRows] = await conn.execute(
            `SELECT name FROM ${table} WHERE id = ?`,
            [listing.item_id]
        );
        const itemName = itemRows.length ? itemRows[0].name : "Unknown";

        const unitPrice = listing.price;
        const totalPrice = unitPrice * quantity;

        await conn.execute(
            "UPDATE listings SET stock = stock - ? WHERE id = ?",
            [quantity, listingId]
        );

        const [result] = await conn.execute(
            `INSERT INTO transactions
                (user_id, listing_id, item_name, quantity, unit_price, total_price)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, listingId, itemName, quantity, unitPrice, totalPrice]
        );

        await conn.commit();

        return {
            ok: true,
            data: {
                id: result.insertId,
                item_name: itemName,
                quantity,
                unit_price: unitPrice,
                total_price: totalPrice,
            },
        };
    } catch (err) {
        await conn.rollback();
        throw err;
    } finally {
        conn.release();
    }
}

async function getUserTransactions(userId) {
    const [rows] = await db.execute(
        `SELECT id, listing_id, item_name, quantity, unit_price, total_price, created_at
           FROM transactions
          WHERE user_id = ?
          ORDER BY id DESC`,
        [userId]
    );
    return rows;
}

module.exports = {
    createTransaction,
    getUserTransactions,
};
