const transactionService = require("../services/transactionService");

// Beli item (user login). req.user diisi oleh authMiddleware.
async function buy(req, res) {
    try {
        const userId = req.user.id;
        const listingId = Number(req.body.listing_id);
        const quantity = Number(req.body.quantity);

        if (!Number.isInteger(listingId) || listingId <= 0) {
            return res.status(400).json({ error: "Invalid listing_id" });
        }
        if (!Number.isInteger(quantity) || quantity <= 0) {
            return res.status(400).json({ error: "Quantity must be an integer > 0" });
        }

        const result = await transactionService.createTransaction(
            userId,
            listingId,
            quantity
        );

        if (!result.ok) {
            return res.status(result.status).json({ error: result.error });
        }

        res.status(201).json({ message: "Purchase successful", data: result.data });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

// Riwayat transaksi milik user yang sedang login.
async function history(req, res) {
    try {
        const data = await transactionService.getUserTransactions(req.user.id);
        res.json({ total: data.length, data });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { buy, history };
