const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const weaponService = require("../services/weaponService");
const db = require("../config/db");

(async () => {
  try {
    console.log("Fetching weapons from Fandom wiki...");
    const weapons = await weaponService.fetchWeapons();
    console.log(`Seeded ${weapons.length} weapons into DB.`);
  } catch (err) {
    console.error("Seed failed:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
