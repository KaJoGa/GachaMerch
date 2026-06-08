const db = require("../config/db");

const ITEM_TYPES = ["weapon", "food"];

// Gabungkan baris listing + data item master (name, image, kategori) menjadi
// satu objek datar yang enak dipakai frontend.
function mapRow(r) {
    const isWeapon = r.item_type === "weapon";
    return {
        id: r.id,
        item_type: r.item_type,
        item_id: r.item_id,
        price: r.price,
        stock: r.stock,
        initial_stock: r.initial_stock,
        created_at: r.created_at,
        name: isWeapon ? r.w_name : r.f_name,
        image: isWeapon ? r.w_image : r.f_image,
        category: isWeapon ? (r.w_type || "Weapon") : (r.f_type || "Food"),
        description: isWeapon ? r.w_effect : r.f_effect,
        quality: isWeapon ? r.w_quality : r.f_quality,
    };
}

const SELECT_JOIN = `
    SELECT l.id, l.item_type, l.item_id, l.price, l.stock, l.initial_stock, l.created_at,
           w.name AS w_name, w.image AS w_image, w.type AS w_type, w.passive AS w_effect, w.rarity AS w_quality,
           f.name AS f_name, f.image AS f_image, f.type AS f_type, f.effect AS f_effect, f.quality AS f_quality
      FROM listings l
      LEFT JOIN weapons w ON l.item_type = 'weapon' AND l.item_id = w.id
      LEFT JOIN foods   f ON l.item_type = 'food'   AND l.item_id = f.id`;

async function getListings() {
    const [rows] = await db.execute(`${SELECT_JOIN} ORDER BY l.id DESC`);
    return rows.map(mapRow);
}

async function getListingById(id) {
    const [rows] = await db.execute(`${SELECT_JOIN} WHERE l.id = ?`, [id]);
    return rows[0] ? mapRow(rows[0]) : null;
}

// Katalog gabungan semua item master (weapons + foods), ditandai item_type.
// Dipakai admin untuk memilih item yang mau dijadikan listing.
async function getCatalog() {
    const [weapons] = await db.execute(
        "SELECT id, name, image, type FROM weapons ORDER BY name"
    );
    const [foods] = await db.execute(
        "SELECT id, name, image, type FROM foods ORDER BY name"
    );

    return [
        ...weapons.map((w) => ({
            item_type: "weapon",
            item_id: w.id,
            name: w.name,
            image: w.image,
            category: w.type || "Weapon",
        })),
        ...foods.map((f) => ({
            item_type: "food",
            item_id: f.id,
            name: f.name,
            image: f.image,
            category: f.type || "Food",
        })),
    ];
}

// Cek item master ada. itemType dijamin sudah divalidasi (∈ ITEM_TYPES) oleh
// controller, jadi pemilihan nama tabel di sini aman dari injeksi.
async function itemExists(itemType, itemId) {
    const table = itemType === "weapon" ? "weapons" : "foods";
    const [rows] = await db.execute(`SELECT id FROM ${table} WHERE id = ?`, [itemId]);
    return rows.length > 0;
}

async function isItemListed(itemType, itemId) {
    const [rows] = await db.execute(
        "SELECT id FROM listings WHERE item_type = ? AND item_id = ?",
        [itemType, itemId]
    );
    return rows.length > 0;
}

async function createListing({ item_type, item_id, price, stock }) {
    // Saat create, stok awal = stok yang diisi (jadi baseline indikator warna).
    const [result] = await db.execute(
        "INSERT INTO listings (item_type, item_id, price, stock, initial_stock) VALUES (?, ?, ?, ?, ?)",
        [item_type, item_id, price, stock, stock]
    );
    return getListingById(result.insertId);
}

async function updateListing(id, { price, stock }) {
    // Admin set ulang stok = baseline baru → reset initial_stock juga, supaya
    // indikator warna dihitung dari stok terbaru (restock).
    await db.execute(
        "UPDATE listings SET price = ?, stock = ?, initial_stock = ? WHERE id = ?",
        [price, stock, stock, id]
    );
    return getListingById(id);
}

async function deleteListing(id) {
    const [result] = await db.execute("DELETE FROM listings WHERE id = ?", [id]);
    return result.affectedRows > 0;
}

module.exports = {
    ITEM_TYPES,
    getListings,
    getListingById,
    getCatalog,
    itemExists,
    isItemListed,
    createListing,
    updateListing,
    deleteListing,
};
