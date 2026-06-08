const express = require("express");
const router = express.Router();

// Menggunakan controller baru (DB) agar menghindari scraping web Wikia
const foodController = require("../controllers/foodDbController");

router.get("/fetch/foods", foodController.fetchFoods);

module.exports = router;