const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const db = require("../config/db");

// Tipe senjata tidak tersedia di halaman Weapon/List, jadi diambil dari
// category pages wiki. Map: nama kategori (jamak) -> nilai type (tunggal).
const CAT_TO_TYPE = {
  Swords: "Sword",
  Claymores: "Claymore",
  Polearms: "Polearm",
  Bows: "Bow",
  Catalysts: "Catalyst",
};

async function members(cat) {
  const url =
    "https://genshin-impact.fandom.com/api.php?action=query&list=categorymembers" +
    `&cmtitle=Category:${encodeURIComponent(cat)}&cmlimit=500&cmtype=page&format=json`;
  const res = await fetch(url, {
    headers: { "User-Agent": "Mozilla/5.0 (enrich script)" },
  });
  const json = await res.json();
  return ((json.query && json.query.categorymembers) || []).map((m) => m.title);
}

(async () => {
  try {
    // 1) Bangun map nama -> type dari semua kategori.
    const nameToType = new Map();
    for (const [cat, type] of Object.entries(CAT_TO_TYPE)) {
      const titles = await members(cat);
      for (const t of titles) nameToType.set(t, type);
      console.log(`Category:${cat} (${type}) -> ${titles.length} member`);
    }

    // 2) Update kolom type tiap weapon berdasarkan name (data lain tetap).
    const [weapons] = await db.execute("SELECT id, name FROM weapons");
    let updated = 0;
    const unmatched = [];
    for (const w of weapons) {
      const type = nameToType.get(w.name);
      if (!type) {
        unmatched.push(w.name);
        continue;
      }
      await db.execute("UPDATE weapons SET type=? WHERE id=?", [type, w.id]);
      updated++;
    }

    console.log(`\nUpdated ${updated}/${weapons.length} weapon.`);
    if (unmatched.length) {
      console.log(`Tidak cocok (${unmatched.length}):`);
      console.log(unmatched);
    }
  } catch (err) {
    console.error("Enrich gagal:", err);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
