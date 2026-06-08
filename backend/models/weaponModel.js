const db = require("../config/db");

async function insertOrUpdateWeapon(weapon) {
    const rarity = weapon.rarity;
    const baseAtk = weapon.baseAtk;

    await db.execute(
        `INSERT INTO weapons (name, rarity, base_atk, substat, passive, image)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
             rarity = VALUES(rarity),
             base_atk = VALUES(base_atk),
             substat = VALUES(substat),
             passive = VALUES(passive),
             image = VALUES(image)`,
        [
            weapon.name,
            rarity,
            baseAtk,
            weapon.substat,
            weapon.passive,
            weapon.image
        ]
    );
}

module.exports = {
    insertOrUpdateWeapon
};