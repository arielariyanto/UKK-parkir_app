const express = require('express');
const router = express.Router();
const tarifController = require('../controller/tarifController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// 🔓 Public: ambil semua tarif
router.get('/', tarifController.getAllTarif);

// 🔓 Public: ambil tarif by ID
router.get('/:id', tarifController.getTarifById);

// 🔐 Protected + Admin only: create tarif
router.post('/', authMiddleware, roleMiddleware('admin'), tarifController.createTarif);

// 🔐 Protected + Admin only: update tarif
router.put('/:id', authMiddleware, roleMiddleware('admin'), tarifController.updateTarif);

// 🔐 Protected + Admin only: delete tarif
router.delete('/:id', authMiddleware, roleMiddleware('admin'), tarifController.deleteTarif);

module.exports = router;
