const db = require("../config/db");

async function getFoods() {
    // Mengambil data langsung dari database tanpa scraping
    const [rows] = await db.execute("SELECT * FROM foods");
    return rows;
}

module.exports = {
    getFoods
};

