// const express = require('express');
// const router = express.Router();
// const transaksiController = require('../controller/transaksiController');
// const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// // 🔐 Get semua transaksi (admin / petugas)
// router.get('/', authMiddleware, roleMiddleware('admin', 'petugas'), transaksiController.getAll);

// // 🔐 Buat transaksi baru (petugas)
// router.post('/', authMiddleware, roleMiddleware('admin', 'petugas'), transaksiController.create);

// module.exports = router;
