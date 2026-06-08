const db = require("../config/db");

module.exports = async (req, res, next) => {
    try {

        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({ error: "Token required" });
        }

        const token = authHeader.split(" ")[1];

        const [rows] = await db.execute(
            "SELECT * FROM users WHERE token=?",
            [token]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: "Invalid token" });
        }

        req.user = rows[0];

        next();

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};