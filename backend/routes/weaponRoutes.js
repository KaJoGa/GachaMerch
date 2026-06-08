const express = require("express");
const router = express.Router();

// Controller DB (read-only). Senjata = katalog; penjualan diatur lewat /listings.
const weaponController = require("../controllers/weaponDbController");

router.get("/fetch/weapons", weaponController.fetchWeapons); // list (legacy path)
router.get("/weapons", weaponController.fetchWeapons);        // list (REST)
router.get("/weapons/:id", weaponController.getWeapon);       // detail

module.exports = router;
