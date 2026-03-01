const express = require('express');
const router = express.Router();
const transaksiController = require('../controller/transaksiController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// Get all transaksi (admin / petugas / owner)
router.get('/', authMiddleware, roleMiddleware('admin', 'petugas', 'owner'), transaksiController.getAll);

// Get transaksi by petugas (riwayat per petugas) - admin only
router.get('/petugas/:id_user', authMiddleware, roleMiddleware('admin'), transaksiController.getByPetugas);

// Get active transaksi by plat nomor (petugas)
router.get('/aktif/:plat', authMiddleware, roleMiddleware('admin', 'petugas'), transaksiController.getActiveByPlat);

// Create transaksi (parkir masuk) - petugas
router.post('/', authMiddleware, roleMiddleware('admin', 'petugas'), transaksiController.create);

// Update transaksi (parkir keluar) - petugas
router.put('/:id/keluar', authMiddleware, roleMiddleware('admin', 'petugas'), transaksiController.processKeluar);

module.exports = router;
