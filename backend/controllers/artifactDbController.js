const db = require("../config/db");

exports.getAllArtifacts = async (req, res) => {
    try {
        const [rows] = await db.query("SELECT * FROM artifacts");
        res.json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to get artifacts" });
    }
};

exports.getArtifactById = async (req, res) => {
    try {
        const [rows] = await db.query("SELECT * FROM artifacts WHERE id = ?", [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: "Artifact not found" });
        }
        res.json(rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to get artifact" });
    }
};
