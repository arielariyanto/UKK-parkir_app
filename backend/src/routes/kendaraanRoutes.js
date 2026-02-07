// src/routes/kendaraanRoutes.js
const express = require('express');
const router = express.Router();
const kendaraanController = require('../controller/kendaraanController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// Get all kendaraan
router.get('/', kendaraanController.getAllKendaraan);

// Create kendaraan
router.post('/', authMiddleware, roleMiddleware('admin', 'petugas'), kendaraanController.createKendaraan);

// Update kendaraan (admin only)
router.put('/:id', authMiddleware, roleMiddleware('admin'), kendaraanController.updateKendaraan);

// Delete kendaraan (admin only)
router.delete('/:id', authMiddleware, roleMiddleware('admin'), kendaraanController.deleteKendaraan);

module.exports = router;
