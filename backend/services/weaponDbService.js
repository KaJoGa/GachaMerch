const db = require("../config/db");

async function getWeapons() {
    // Mengambil data langsung dari database tanpa scraping
    const [rows] = await db.execute("SELECT * FROM weapons ORDER BY id DESC");
    return rows;
}

async function getWeaponById(id) {
    const [rows] = await db.execute("SELECT * FROM weapons WHERE id=?", [id]);
    return rows[0] || null;
}

module.exports = {
    getWeapons,
    getWeaponById,
};
