const express = require("express");
const router = express.Router();
const kendaraanController = require("../controller/kendaraanController");

router.get("/", kendaraanController.getAll);
router.post("/", kendaraanController.create);
router.get("/:id", kendaraanController.getById);
router.put("/:id", kendaraanController.update);
router.delete("/:id", kendaraanController.remove);

module.exports = router;
