const pool = require("../config/database");

// Get all transaksi
exports.getAll = async (req, res) => {
    try {
        const [rows] = await pool.query(`
      SELECT t.*, 
             k.plat_nomor, 
             k.jenis_kendaraan,
             k.warna,
             k.pemilik,
             a.nama_area, 
             u.nama_lengkap
      FROM tb_transaksi t
      JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_area_parkir a ON t.id_area = a.id_area
      LEFT JOIN tb_user u ON t.id_user = u.id_user
      ORDER BY t.waktu_masuk DESC
    `);

        res.json({
            success: true,
            data: rows
        });
    } catch (err) {
        console.error('Get transaksi error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// Get active transaksi by plat nomor
exports.getActiveByPlat = async (req, res) => {
    try {
        const { plat } = req.params;

        const [rows] = await pool.query(`
      SELECT t.*, 
             k.plat_nomor, 
             k.jenis_kendaraan,
             k.warna,
             k.pemilik,
             a.nama_area,
             tar.tarif_per_jam
      FROM tb_transaksi t
      JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_area_parkir a ON t.id_area = a.id_area
      LEFT JOIN tb_tarif tar ON k.jenis_kendaraan = tar.jenis_kendaraan
      WHERE k.plat_nomor = ? AND t.status = 'masuk'
      ORDER BY t.waktu_masuk DESC
      LIMIT 1
    `, [plat]);

        if (rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Tidak ada transaksi aktif untuk plat nomor ini'
            });
        }

        res.json({
            success: true,
            data: rows[0]
        });
    } catch (err) {
        console.error('Get active transaksi error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// Create transaksi (parkir masuk)
exports.create = async (req, res) => {
    try {
        const {
            plat_nomor,
            jenis_kendaraan,
            warna,
            pemilik,
            id_area
        } = req.body;

        if (!plat_nomor || !jenis_kendaraan) {
            return res.status(400).json({
                success: false,
                message: 'Plat nomor dan jenis kendaraan harus diisi'
            });
        }

        // Check or create kendaraan
        let [kendaraan] = await pool.query(
            'SELECT id_kendaraan FROM tb_kendaraan WHERE plat_nomor = ?',
            [plat_nomor]
        );

        let id_kendaraan;
        if (kendaraan.length === 0) {
            // Create new kendaraan
            const [result] = await pool.query(
                'INSERT INTO tb_kendaraan (plat_nomor, jenis_kendaraan, warna, pemilik) VALUES (?, ?, ?, ?)',
                [plat_nomor, jenis_kendaraan, warna || null, pemilik || null]
            );
            id_kendaraan = result.insertId;
        } else {
            id_kendaraan = kendaraan[0].id_kendaraan;
        }

        // Create transaksi
        const [result] = await pool.query(
            `INSERT INTO tb_transaksi 
      (id_kendaraan, id_area, waktu_masuk, status, id_user)
      VALUES (?, ?, NOW(), 'masuk', ?)`,
            [id_kendaraan, id_area || null, req.user.id_user]
        );

        // Update area terisi if id_area provided
        if (id_area) {
            await pool.query(
                'UPDATE tb_area_parkir SET terisi = terisi + 1 WHERE id_area = ?',
                [id_area]
            );
        }

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Parkir masuk: ${plat_nomor}`]
        );

        res.status(201).json({
            success: true,
            message: "Transaksi parkir masuk berhasil",
            data: {
                id_parkir: result.insertId,
                plat_nomor,
                waktu_masuk: new Date()
            }
        });
    } catch (err) {
        console.error('Create transaksi error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// Process parkir keluar
exports.processKeluar = async (req, res) => {
    try {
        const { id } = req.params;

        // Get transaksi detail
        const [transaksi] = await pool.query(`
      SELECT t.*, 
             k.plat_nomor,
             k.jenis_kendaraan,
             tar.tarif_per_jam
      FROM tb_transaksi t
      JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_tarif tar ON k.jenis_kendaraan = tar.jenis_kendaraan
      WHERE t.id_parkir = ? AND t.status = 'masuk'
    `, [id]);

        if (transaksi.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan atau sudah selesai'
            });
        }

        const data = transaksi[0];
        const waktuMasuk = new Date(data.waktu_masuk);
        const waktuKeluar = new Date();

        // Calculate duration in hours (minimum 1 hour)
        const durasiMs = waktuKeluar - waktuMasuk;
        const durasiJam = Math.ceil(durasiMs / (1000 * 60 * 60));

        // Calculate total biaya
        const tarifPerJam = data.tarif_per_jam || 0;
        const biayaTotal = durasiJam * tarifPerJam;

        // Update transaksi
        await pool.query(
            `UPDATE tb_transaksi 
       SET waktu_keluar = ?, durasi_jam = ?, biaya_total = ?, status = 'keluar'
       WHERE id_parkir = ?`,
            [waktuKeluar, durasiJam, biayaTotal, id]
        );

        // Update area terisi if id_area exists
        if (data.id_area) {
            await pool.query(
                'UPDATE tb_area_parkir SET terisi = terisi - 1 WHERE id_area = ?',
                [data.id_area]
            );
        }

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Parkir keluar: ${data.plat_nomor} - Rp ${biayaTotal}`]
        );

        res.json({
            success: true,
            message: 'Transaksi parkir keluar berhasil',
            data: {
                id_parkir: id,
                plat_nomor: data.plat_nomor,
                jenis_kendaraan: data.jenis_kendaraan,
                waktu_masuk: waktuMasuk,
                waktu_keluar: waktuKeluar,
                durasi_jam: durasiJam,
                tarif_per_jam: tarifPerJam,
                biaya_total: biayaTotal
            }
        });
    } catch (err) {
        console.error('Process keluar error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};
