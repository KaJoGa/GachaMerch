const express = require("express");
const router = express.Router();
const artifactDbController = require("../controllers/artifactDbController");

router.get("/artifacts", artifactDbController.getAllArtifacts);
router.get("/artifacts/:id", artifactDbController.getArtifactById);

module.exports = router;
