const db = require("../config/db");

async function insertOrUpdateArtifact(artifactData) {
    const { name, set_name, type, rarity, main_stat, description, image } = artifactData;

    await db.execute(
        `INSERT INTO artifacts (name, set_name, type, rarity, main_stat, description, image) 
         VALUES (?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         set_name=VALUES(set_name), type=VALUES(type), rarity=VALUES(rarity), 
         main_stat=VALUES(main_stat), description=VALUES(description), image=VALUES(image)`,
        [name, set_name, type, rarity, main_stat, description, image]
    );
}

module.exports = {
    insertOrUpdateArtifact
};
