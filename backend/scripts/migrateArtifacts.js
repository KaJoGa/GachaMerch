const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

async function migrateArtifacts() {
    try {
        console.log("Migrating artifacts table...");
        
        await db.query(`
            CREATE TABLE IF NOT EXISTS \`artifacts\` (
              \`id\` int(11) NOT NULL AUTO_INCREMENT,
              \`name\` varchar(255) NOT NULL,
              \`set_name\` varchar(255) NOT NULL,
              \`type\` varchar(100) NOT NULL,
              \`rarity\` varchar(50) DEFAULT NULL,
              \`main_stat\` varchar(255) DEFAULT NULL,
              \`description\` text DEFAULT NULL,
              \`image\` varchar(255) DEFAULT NULL,
              PRIMARY KEY (\`id\`),
              UNIQUE KEY \`name\` (\`name\`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        `);
        console.log("Created table artifacts.");

        await db.query(`
            ALTER TABLE \`listings\` 
            MODIFY \`item_type\` enum('weapon','food','artifact') NOT NULL;
        `);
        console.log("Updated listings item_type enum to include 'artifact'.");

    } catch (err) {
        console.error("Migration failed:", err);
        process.exitCode = 1;
    } finally {
        await db.end();
    }
}

migrateArtifacts();
