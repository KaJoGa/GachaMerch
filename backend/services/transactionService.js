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
        let table = "weapons";
        if (listing.item_type === "food") table = "foods";
        if (listing.item_type === "artifact") table = "artifacts";
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
        `SELECT t.id, t.listing_id, t.item_name, t.quantity, t.unit_price, t.total_price, t.created_at,
                COALESCE(w.image, f.image, a.image) as item_image
           FROM transactions t
           LEFT JOIN listings l ON t.listing_id = l.id
           LEFT JOIN weapons w ON l.item_type = 'weapon' AND l.item_id = w.id
           LEFT JOIN foods f ON l.item_type = 'food' AND l.item_id = f.id
           LEFT JOIN artifacts a ON l.item_type = 'artifact' AND l.item_id = a.id
          WHERE t.user_id = ?
          ORDER BY t.id DESC`,
        [userId]
    );
    return rows;
}

module.exports = {
    createTransaction,
    getUserTransactions,
};
