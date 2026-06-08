const listingService = require("../services/listingService");

// Validasi harga & stok. requireItem=true juga memvalidasi item_type/item_id
// (dipakai saat create; saat update item-nya tidak boleh diganti).
function validatePayload(body, { requireItem }) {
    const price = Number(body.price);
    const stock = Number(body.stock);

    if (requireItem) {
        const itemType = (body.item_type ?? "").toString();
        if (!listingService.ITEM_TYPES.includes(itemType)) {
            return { ok: false, error: "item_type must be 'weapon' or 'food'" };
        }
        const itemId = Number(body.item_id);
        if (!Number.isInteger(itemId) || itemId <= 0) {
            return { ok: false, error: "Invalid item_id" };
        }
    }

    if (!Number.isInteger(price) || price <= 0) {
        return { ok: false, error: "Price must be an integer > 0" };
    }
    if (!Number.isInteger(stock) || stock < 0) {
        return { ok: false, error: "Stock must be an integer ≥ 0" };
    }

    return { ok: true };
}

async function getListings(req, res) {
    try {
        const data = await listingService.getListings();
        res.json({ total: data.length, data });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function getCatalog(req, res) {
    try {
        const data = await listingService.getCatalog();
        res.json({ total: data.length, data });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function createListing(req, res) {
    try {
        const v = validatePayload(req.body, { requireItem: true });
        if (!v.ok) return res.status(400).json({ error: v.error });

        const itemType = req.body.item_type;
        const itemId = Number(req.body.item_id);

        if (!(await listingService.itemExists(itemType, itemId))) {
            return res.status(404).json({ error: "Item not found in catalog" });
        }
        if (await listingService.isItemListed(itemType, itemId)) {
            return res.status(409).json({ error: "This item is already on sale (already listed)" });
        }

        const listing = await listingService.createListing({
            item_type: itemType,
            item_id: itemId,
            price: Number(req.body.price),
            stock: Number(req.body.stock),
        });
        res.status(201).json({ message: "Listing created", data: listing });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function updateListing(req, res) {
    try {
        const existing = await listingService.getListingById(req.params.id);
        if (!existing) {
            return res.status(404).json({ error: "Listing not found" });
        }

        const v = validatePayload(req.body, { requireItem: false });
        if (!v.ok) return res.status(400).json({ error: v.error });

        const listing = await listingService.updateListing(req.params.id, {
            price: Number(req.body.price),
            stock: Number(req.body.stock),
        });
        res.json({ message: "Listing updated", data: listing });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function removeListing(req, res) {
    try {
        const deleted = await listingService.deleteListing(req.params.id);
        if (!deleted) {
            return res.status(404).json({ error: "Listing not found" });
        }
        res.json({ message: "Listing deleted" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    getListings,
    getCatalog,
    createListing,
    updateListing,
    removeListing,
};
