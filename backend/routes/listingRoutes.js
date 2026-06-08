const express = require("express");
const router = express.Router();

const listingController = require("../controllers/listingController");
const verifyToken = require("../middleware/authMiddleware");
const requireAdmin = require("../middleware/requireAdmin");

// ===== User / public =====
router.get("/listings", listingController.getListings); // item yang sedang dijual

// ===== Admin only =====
router.get("/catalog", verifyToken, requireAdmin, listingController.getCatalog); // pilih item
router.post("/listings", verifyToken, requireAdmin, listingController.createListing);
router.put("/listings/:id", verifyToken, requireAdmin, listingController.updateListing);
router.delete("/listings/:id", verifyToken, requireAdmin, listingController.removeListing);

module.exports = router;
