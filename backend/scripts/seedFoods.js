const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const foodService = require("../services/foodService");
const db = require("../config/db");

(async () => {
  try {
    console.log("Fetching foods from Fandom wiki...");
    const foods = await foodService.fetchFoods();
    console.log(`Seeded ${foods.length} foods into DB.`);
  } catch (err) {
    console.error("Seed failed:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
