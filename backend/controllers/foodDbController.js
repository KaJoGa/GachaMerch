const foodDbService = require("../services/foodDbService");

async function fetchFoods(req, res) {
    try {
        // Menggunakan service baru untuk memanggil data langsung dari MySQL
        const foods = await foodDbService.getFoods();

        res.json({
            total: foods.length,
            data: foods
        });

    } catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
}

module.exports = {
    fetchFoods
};

