// const express = require('express');
// const router = express.Router();
// const tarifController = require('../controller/tarifController');
// const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// // 🔓 Public: ambil semua tarif
// router.get('/', tarifController.getAllTarif);

// // 🔓 Public: ambil tarif by ID
// router.get('/:id', tarifController.getTarifById);

// // 🔐 Protected + Admin only: update tarif
// router.put('/:id', authMiddleware, roleMiddleware('admin'), tarifController.updateTarif);

// module.exports = router;
