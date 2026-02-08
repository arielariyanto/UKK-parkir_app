const express = require('express');
const router = express.Router();
const kendaraanController = require('../controller/kendaraanController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// 🔓 Public: ambil semua jenis kendaraan (untuk dropdown)
router.get('/', kendaraanController.getAllJenisKendaraan);

// 🔐 Protected + Admin only: create jenis kendaraan
router.post('/', authMiddleware, roleMiddleware('admin'), kendaraanController.createJenisKendaraan);

// 🔐 Protected + Admin only: update jenis kendaraan
router.put('/:id', authMiddleware, roleMiddleware('admin'), kendaraanController.updateJenisKendaraan);

// 🔐 Protected + Admin only: delete jenis kendaraan
router.delete('/:id', authMiddleware, roleMiddleware('admin'), kendaraanController.deleteJenisKendaraan);

module.exports = router;
