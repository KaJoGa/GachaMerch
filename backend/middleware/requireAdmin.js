// Middleware role admin.
// WAJIB dipasang SETELAH authMiddleware, karena bergantung pada req.user yang
// diisi authMiddleware dari token. Dipakai untuk endpoint khusus admin
// (mis. create/update/delete weapon).
//
// Contoh pakai di route:
//   router.post("/weapons", verifyToken, requireAdmin, weaponController.create);
module.exports = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: "Token required" });
    }

    if (req.user.role !== "admin") {
        return res.status(403).json({ error: "Access denied: admin only" });
    }

    next();
};
