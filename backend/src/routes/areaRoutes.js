const express = require("express");
const router = express.Router();
const areaController = require("../controller/areaController");
const { authMiddleware, roleMiddleware } = require("../middleware/authMiddleware");

// Get all areas (public or protected based on your needs)
router.get("/", areaController.getAllArea);

// Get area by ID
router.get("/:id", areaController.getAreaById);

// Create area (admin only)
router.post("/", authMiddleware, roleMiddleware("admin"), areaController.createArea);

// Update area (admin only)
router.put("/:id", authMiddleware, roleMiddleware("admin"), areaController.updateArea);

// Delete area (admin only)
router.delete("/:id", authMiddleware, roleMiddleware("admin"), areaController.deleteArea);

module.exports = router;
