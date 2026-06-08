const cheerio = require("cheerio");
const db = require("../config/db");

function cleanImage(url) {
    if (!url) return null;
    const match = url.match(/https:\/\/.*?\.(png|jpg)/);
    return match ? match[0] : url;
}

async function fetchFoods() {

    const response = await fetch(
        "https://genshin-impact.fandom.com/api.php?action=parse&page=Food/List&format=json"
    );

    const json = await response.json();
    const html = json.parse.text["*"];

    const $ = cheerio.load(html);
    const foods = [];

    $("table tbody tr").each((i, row) => {

        const cols = $(row).find("td");
        if (cols.length < 5) return;

        let image =
            $(cols[0]).find("img").attr("data-src") ||
            $(cols[0]).find("img").attr("src");

        image = cleanImage(image);

        const name = $(cols[1]).text().trim();

        let quality =
            $(cols[2]).find("img").attr("alt") ||
            $(cols[2]).text().trim();

        // convert "3 Stars" -> 3
        const qualityNumber = quality.match(/\d+/)
            ? parseInt(quality.match(/\d+/)[0])
            : null;

        const type = $(cols[3]).text().trim();

        const effect = $(cols[4])
            .text()
            .replace(/\s+/g, " ")
            .trim();

        foods.push({
            name,
            quality: qualityNumber,
            type,
            effect,
            image
        });

    });

    // INSERT / UPDATE DATABASE
    for (const food of foods) {
        await db.execute(
            `INSERT INTO foods (name, quality, type, effect, image)
             VALUES (?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
             quality = VALUES(quality),
             type = VALUES(type),
             effect = VALUES(effect),
             image = VALUES(image)`,
            [
                food.name,
                food.quality,
                food.type,
                food.effect,
                food.image
            ]
        );
    }

    return foods;
}

module.exports = {
    fetchFoods
};