const express = require('express');
const router = express.Router();
const {
  getDashboard,
  getLaporanPendapatan,
  getLaporanKendaraan,
  getLaporanArea,
  getLaporanTransaksiDetail,
  getLaporanLogAktivitas,
} = require('../controllers/laporanController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

router.use(authMiddleware);

// Dashboard - semua role bisa akses
router.get('/dashboard', getDashboard);

// Laporan - hanya admin dan owner
router.get('/pendapatan', roleMiddleware('admin', 'owner'), getLaporanPendapatan);
router.get('/kendaraan', roleMiddleware('admin', 'owner'), getLaporanKendaraan);
router.get('/area', roleMiddleware('admin', 'owner'), getLaporanArea);
router.get('/transaksi-detail', roleMiddleware('admin', 'owner'), getLaporanTransaksiDetail);
router.get('/log-aktivitas', roleMiddleware('admin'), getLaporanLogAktivitas);

module.exports = router;