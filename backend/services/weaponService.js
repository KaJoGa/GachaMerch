const cheerio = require("cheerio");
const cleanImage = require("../utils/cleanImage");
const weaponModel = require("../models/weaponModel");

async function fetchWeapons() {

    const response = await fetch(
        "https://genshin-impact.fandom.com/api.php?action=parse&page=Weapon/List&format=json",
        {
            headers: {
                "User-Agent":
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
            }
        }
    );

    const json = await response.json();
    const html = json.parse.text["*"];

    const $ = cheerio.load(html);
    const weapons = [];

    $("table tbody tr").each((i, row) => {

        const cols = $(row).find("td");
        if (cols.length < 6) return;

        let image =
            $(cols[0]).find("img").attr("data-src") ||
            $(cols[0]).find("img").attr("src");

        image = cleanImage(image);

        const name = $(cols[1]).text().trim();
        const rarity =
            $(cols[2]).find("img").attr("alt") ||
            $(cols[2]).text().trim();

        const baseAtk = $(cols[3]).text().trim();
        const substat = $(cols[4]).text().trim();

        const passive = $(cols[5])
            .text()
            .replace(/\s+/g, " ")
            .trim();

        weapons.push({
            name,
            rarity,
            baseAtk,
            substat,
            passive,
            image
        });

    });

    for (const w of weapons) {

        const rarity = w.rarity.match(/\d+/)
            ? parseInt(w.rarity.match(/\d+/)[0])
            : null;

        const baseAtk = w.baseAtk.match(/\d+/)
            ? parseInt(w.baseAtk.match(/\d+/)[0])
            : null;

        await weaponModel.insertOrUpdateWeapon({
            name: w.name,
            rarity,
            baseAtk,
            substat: w.substat,
            passive: w.passive,
            image: w.image
        });
    }

    return weapons;
}

module.exports = {
    fetchWeapons
};