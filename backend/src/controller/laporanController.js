const pool = require('../config/database');

// Dashboard summary
const getDashboard = async (req, res) => {
    try {
        // Total kendaraan masuk hari ini
        const [masukHariIni] = await pool.query(
            `SELECT COUNT(*) as total FROM tb_transaksi 
       WHERE DATE(waktu_masuk) = CURDATE()`
        );

        // Total kendaraan keluar hari ini
        const [keluarHariIni] = await pool.query(
            `SELECT COUNT(*) as total FROM tb_transaksi 
       WHERE DATE(waktu_keluar) = CURDATE() AND status = 'keluar'`
        );

        // Kendaraan sedang parkir
        const [sedangParkir] = await pool.query(
            `SELECT COUNT(*) as total FROM tb_transaksi WHERE status = 'masuk'`
        );

        // Total pendapatan hari ini
        const [pendapatanHariIni] = await pool.query(
            `SELECT COALESCE(SUM(biaya_total), 0) as total FROM tb_transaksi 
       WHERE DATE(waktu_keluar) = CURDATE() AND status = 'keluar'`
        );

        // Total pendapatan bulan ini
        const [pendapatanBulanIni] = await pool.query(
            `SELECT COALESCE(SUM(biaya_total), 0) as total FROM tb_transaksi 
       WHERE MONTH(waktu_keluar) = MONTH(CURDATE()) 
       AND YEAR(waktu_keluar) = YEAR(CURDATE()) 
       AND status = 'keluar'`
        );

        // Total pendapatan tahun ini
        const [pendapatanTahunIni] = await pool.query(
            `SELECT COALESCE(SUM(biaya_total), 0) as total FROM tb_transaksi 
       WHERE YEAR(waktu_keluar) = YEAR(CURDATE()) 
       AND status = 'keluar'`
        );

        // Grafik pendapatan 7 hari terakhir (per hari)
        const [grafik7Hari] = await pool.query(
            `SELECT 
         DATE(waktu_keluar) as tanggal,
         COALESCE(SUM(biaya_total), 0) as total
       FROM tb_transaksi
       WHERE status = 'keluar'
         AND waktu_keluar >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(waktu_keluar)
       ORDER BY tanggal ASC`
        );

        // Grafik pendapatan 12 bulan terakhir (per bulan)
        const [grafik12Bulan] = await pool.query(
            `SELECT 
         DATE_FORMAT(waktu_keluar, '%Y-%m') as bulan,
         DATE_FORMAT(waktu_keluar, '%b %Y') as label,
         COALESCE(SUM(biaya_total), 0) as total
       FROM tb_transaksi
       WHERE status = 'keluar'
         AND waktu_keluar >= DATE_SUB(CURDATE(), INTERVAL 11 MONTH)
       GROUP BY DATE_FORMAT(waktu_keluar, '%Y-%m'), DATE_FORMAT(waktu_keluar, '%b %Y')
       ORDER BY bulan ASC`
        );

        // Kapasitas area parkir
        const [kapasitasArea] = await pool.query(
            `SELECT 
        SUM(kapasitas) as total_kapasitas,
        SUM(terisi) as total_terisi,
        SUM(kapasitas) - SUM(terisi) as tersedia
       FROM tb_area_parkir`
        );

        // Statistik per area
        const [statistikArea] = await pool.query(
            `SELECT 
        a.nama_area,
        a.kapasitas,
        a.terisi,
        a.kapasitas - a.terisi as tersedia,
        ROUND((a.terisi / a.kapasitas) * 100, 2) as persentase_terisi
       FROM tb_area_parkir a
       ORDER BY a.nama_area`
        );

        res.json({
            success: true,
            data: {
                hari_ini: {
                    kendaraan_masuk: masukHariIni[0]?.total ?? 0,
                    kendaraan_keluar: keluarHariIni[0]?.total ?? 0,
                    sedang_parkir: sedangParkir[0]?.total ?? 0,
                    pendapatan: pendapatanHariIni[0]?.total ?? 0,
                },
                bulan_ini: {
                    pendapatan: pendapatanBulanIni[0]?.total ?? 0,
                },
                tahun_ini: {
                    pendapatan: pendapatanTahunIni[0]?.total ?? 0,
                },
                grafik: {
                    tujuh_hari: grafik7Hari,
                    dua_belas_bulan: grafik12Bulan,
                },
                kapasitas: {
                    total: kapasitasArea[0]?.total_kapasitas || 0,
                    terisi: kapasitasArea[0]?.total_terisi || 0,
                    tersedia: kapasitasArea[0]?.tersedia || 0,
                },
                area: statistikArea,
            },
        });
    } catch (error) {
        console.error('Get dashboard error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data dashboard',
        });
    }
};

// Laporan pendapatan
const getLaporanPendapatan = async (req, res) => {
    try {
        const { tanggal_mulai, tanggal_akhir, group_by = 'day' } = req.query;

        let query = '';
        const params = [];

        if (group_by === 'day') {
            query = `
        SELECT 
          DATE(waktu_keluar) as tanggal,
          COUNT(*) as jumlah_transaksi,
          SUM(biaya_total) as total_pendapatan
        FROM tb_transaksi
        WHERE status = 'keluar'
      `;
        } else if (group_by === 'month') {
            query = `
        SELECT 
          DATE_FORMAT(waktu_keluar, '%Y-%m') as bulan,
          COUNT(*) as jumlah_transaksi,
          SUM(biaya_total) as total_pendapatan
        FROM tb_transaksi
        WHERE status = 'keluar'
      `;
        }

        if (tanggal_mulai && tanggal_akhir) {
            query += ' AND DATE(waktu_keluar) BETWEEN ? AND ?';
            params.push(tanggal_mulai, tanggal_akhir);
        }

        query += group_by === 'day'
            ? ' GROUP BY DATE(waktu_keluar) ORDER BY tanggal DESC'
            : ' GROUP BY DATE_FORMAT(waktu_keluar, "%Y-%m") ORDER BY bulan DESC';

        const [rows] = await pool.query(query, params);

        // Total keseluruhan
        const [total] = await pool.query(
            `SELECT 
        COUNT(*) as total_transaksi,
        SUM(biaya_total) as total_pendapatan
       FROM tb_transaksi
       WHERE status = 'keluar'
       ${tanggal_mulai && tanggal_akhir ? 'AND DATE(waktu_keluar) BETWEEN ? AND ?' : ''}`,
            params
        );

        res.json({
            success: true,
            data: {
                detail: rows,
                summary: total[0],
            },
        });
    } catch (error) {
        console.error('Get laporan pendapatan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil laporan pendapatan',
        });
    }
};

// Laporan kendaraan
const getLaporanKendaraan = async (req, res) => {
    try {
        const { tanggal_mulai, tanggal_akhir } = req.query;

        let query = `
      SELECT 
        k.jenis_kendaraan,
        COUNT(DISTINCT t.id_parkir) as jumlah_transaksi,
        COUNT(DISTINCT k.id_kendaraan) as jumlah_kendaraan,
        SUM(CASE WHEN t.status = 'keluar' THEN t.biaya_total ELSE 0 END) as total_pendapatan
      FROM tb_kendaraan k
      LEFT JOIN tb_transaksi t ON k.id_kendaraan = t.id_kendaraan
      WHERE 1=1
    `;
        const params = [];

        if (tanggal_mulai && tanggal_akhir) {
            query += ' AND DATE(t.waktu_masuk) BETWEEN ? AND ?';
            params.push(tanggal_mulai, tanggal_akhir);
        }

        query += ' GROUP BY k.jenis_kendaraan ORDER BY jumlah_transaksi DESC';

        const [rows] = await pool.query(query, params);

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get laporan kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil laporan kendaraan',
        });
    }
};

// Laporan area
const getLaporanArea = async (req, res) => {
    try {
        const { tanggal_mulai, tanggal_akhir } = req.query;

        let query = `
      SELECT 
        a.nama_area,
        a.kapasitas,
        a.terisi as sedang_terisi,
        COUNT(t.id_parkir) as total_transaksi,
        SUM(CASE WHEN t.status = 'keluar' THEN t.biaya_total ELSE 0 END) as total_pendapatan
      FROM tb_area_parkir a
      LEFT JOIN tb_transaksi t ON a.id_area = t.id_area
      WHERE 1=1
    `;
        const params = [];

        if (tanggal_mulai && tanggal_akhir) {
            query += ' AND DATE(t.waktu_masuk) BETWEEN ? AND ?';
            params.push(tanggal_mulai, tanggal_akhir);
        }

        query += ' GROUP BY a.id_area, a.nama_area, a.kapasitas, a.terisi ORDER BY total_transaksi DESC';

        const [rows] = await pool.query(query, params);

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get laporan area error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil laporan area',
        });
    }
};

// Laporan transaksi detail
const getLaporanTransaksiDetail = async (req, res) => {
    try {
        const { tanggal_mulai, tanggal_akhir, status } = req.query;

        let query = `
      SELECT 
        t.id_parkir,
        t.waktu_masuk,
        t.waktu_keluar,
        t.durasi_jam,
        t.biaya_total,
        t.status,
        k.plat_nomor,
        k.jenis_kendaraan,
        k.warna,
        k.pemilik,
        a.nama_area,
        u.nama_lengkap as petugas
      FROM tb_transaksi t
      JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_area_parkir a ON t.id_area = a.id_area
      LEFT JOIN tb_user u ON t.id_user = u.id_user
      WHERE 1=1
    `;
        const params = [];

        if (tanggal_mulai && tanggal_akhir) {
            query += ' AND DATE(t.waktu_masuk) BETWEEN ? AND ?';
            params.push(tanggal_mulai, tanggal_akhir);
        }

        if (status) {
            query += ' AND t.status = ?';
            params.push(status);
        }

        query += ' ORDER BY t.waktu_masuk DESC';

        const [rows] = await pool.query(query, params);

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get laporan transaksi detail error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil laporan transaksi detail',
        });
    }
};

// Laporan log aktivitas
const getLaporanLogAktivitas = async (req, res) => {
    try {
        const { tanggal_mulai, tanggal_akhir, id_user } = req.query;

        let query = `
      SELECT 
        l.id_log,
        l.aktivitas,
        l.created_at as waktu_aktivitas,
        u.nama_lengkap,
        u.username,
        u.role
      FROM tb_log_aktivitas l
      LEFT JOIN tb_user u ON l.id_user = u.id_user
      WHERE 1=1
    `;
        const params = [];

        if (tanggal_mulai && tanggal_akhir) {
            query += ' AND DATE(l.created_at) BETWEEN ? AND ?';
            params.push(tanggal_mulai, tanggal_akhir);
        }

        if (id_user) {
            query += ' AND l.id_user = ?';
            params.push(id_user);
        }

        query += ' ORDER BY l.created_at DESC LIMIT 100';

        const [rows] = await pool.query(query, params);

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get laporan log aktivitas error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil log aktivitas',
        });
    }
};

module.exports = {
    getDashboard,
    getLaporanPendapatan,
    getLaporanKendaraan,
    getLaporanArea,
    getLaporanTransaksiDetail,
    getLaporanLogAktivitas,
};