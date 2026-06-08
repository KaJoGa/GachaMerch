const weaponDbService = require("../services/weaponDbService");

async function fetchWeapons(req, res) {
    try {
        const weapons = await weaponDbService.getWeapons();
        res.json({ total: weapons.length, data: weapons });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function getWeapon(req, res) {
    try {
        const weapon = await weaponDbService.getWeaponById(req.params.id);
        if (!weapon) {
            return res.status(404).json({ error: "Weapon not found" });
        }
        res.json({ data: weapon });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    fetchWeapons,
    getWeapon,
};
