const express = require("express");
const router = express.Router();

const transactionController = require("../controllers/transactionController");
const verifyToken = require("../middleware/authMiddleware");

// Keduanya butuh bearer token (user yang login).
router.post("/transactions", verifyToken, transactionController.buy);
router.get("/transactions", verifyToken, transactionController.history);

module.exports = router;
