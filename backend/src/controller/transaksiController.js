const pool = require("../config/database");

// Get all transaksi
exports.getAll = async (req, res) => {
    try {
        const [rows] = await pool.query(`
      SELECT t.*, 
             k.jenis_kendaraan,
             a.nama_area, 
             u.nama_lengkap
      FROM tb_transaksi t
      LEFT JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
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
             k.jenis_kendaraan,
             a.nama_area,
             tar.tarif_per_jam
      FROM tb_transaksi t
      LEFT JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_area_parkir a ON t.id_area = a.id_area
      LEFT JOIN tb_tarif tar ON t.id_kendaraan = tar.id_kendaraan
      WHERE t.plat_nomor = ? AND t.status = 'masuk'
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
            id_kendaraan, // FK to tb_kendaraan (master jenis)
            jenis_kendaraan, // Backward compatibility (string)
            warna,
            pemilik,
            id_area
        } = req.body;

        console.log('Parkir masuk request:', { plat_nomor, id_kendaraan, jenis_kendaraan, warna, pemilik, id_area });

        if (!plat_nomor) {
            return res.status(400).json({
                success: false,
                message: 'Plat nomor harus diisi'
            });
        }

        // Determine id_kendaraan (FK to master jenis)
        let kendaraanId = id_kendaraan;

        // Backward compatibility: if jenis_kendaraan string provided, find id
        if (!kendaraanId && jenis_kendaraan) {
            const [jenisData] = await pool.query(
                'SELECT id_kendaraan FROM tb_kendaraan WHERE jenis_kendaraan = ? LIMIT 1',
                [jenis_kendaraan]
            );

            if (jenisData.length > 0) {
                kendaraanId = jenisData[0].id_kendaraan;
            }
        }

        if (!kendaraanId) {
            console.log('Error: id_kendaraan not found');
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan harus diisi'
            });
        }

        // Check area capacity if id_area provided
        if (id_area) {
            const [areaData] = await pool.query(
                'SELECT kapasitas, terisi FROM tb_area_parkir WHERE id_area = ?',
                [id_area]
            );

            if (areaData.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Area parkir tidak ditemukan'
                });
            }

            const area = areaData[0];
            if (area.terisi >= area.kapasitas) {
                return res.status(400).json({
                    success: false,
                    message: `Area parkir penuh! Kapasitas: ${area.kapasitas}, Terisi: ${area.terisi}`
                });
            }
        }

        // Create transaksi directly (plat_nomor, warna, pemilik stored in tb_transaksi)
        const [result] = await pool.query(
            `INSERT INTO tb_transaksi 
      (id_kendaraan, plat_nomor, warna, pemilik, id_area, waktu_masuk, status, id_user)
      VALUES (?, ?, ?, ?, ?, NOW(), 'masuk', ?)`,
            [kendaraanId, plat_nomor.toUpperCase(), warna || null, pemilik || null, id_area || null, req.user.id_user]
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

// Update transaksi (parkir keluar)
exports.processKeluar = async (req, res) => {
    try {
        const { id } = req.params;

        // Get transaksi data
        const [transaksi] = await pool.query(`
      SELECT t.*, 
             k.jenis_kendaraan,
             tar.tarif_per_jam
      FROM tb_transaksi t
      LEFT JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      LEFT JOIN tb_tarif tar ON t.id_kendaraan = tar.id_kendaraan
      WHERE t.id_parkir = ?
    `, [id]);

        if (transaksi.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const data = transaksi[0];

        // Calculate duration and cost
        const waktuMasuk = new Date(data.waktu_masuk);
        const waktuKeluar = new Date();
        const durasiMs = waktuKeluar - waktuMasuk;
        const durasiJam = Math.ceil(durasiMs / (1000 * 60 * 60)); // Round up to nearest hour
        const biayaTotal = durasiJam * (data.tarif_per_jam || 0);

        // Update transaksi
        await pool.query(`
      UPDATE tb_transaksi 
      SET waktu_keluar = NOW(),
          durasi_jam = ?,
          biaya_total = ?,
          status = 'keluar'
      WHERE id_parkir = ?
    `, [durasiJam, biayaTotal, id]);

        // Update area terisi
        if (data.id_area) {
            await pool.query(
                'UPDATE tb_area_parkir SET terisi = terisi - 1 WHERE id_area = ?',
                [data.id_area]
            );
        }

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Parkir keluar: ${data.plat_nomor} - ${biayaTotal}`]
        );

        res.json({
            success: true,
            message: 'Transaksi parkir keluar berhasil',
            data: {
                id_parkir: id,
                plat_nomor: data.plat_nomor,
                waktu_masuk: waktuMasuk,
                waktu_keluar: waktuKeluar,
                durasi_jam: durasiJam,
                biaya_total: biayaTotal
            }
        });
    } catch (err) {
        console.error('Update transaksi error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// Delete transaksi
exports.delete = async (req, res) => {
    try {
        const { id } = req.params;

        // Get transaksi data first
        const [transaksi] = await pool.query(
            'SELECT * FROM tb_transaksi WHERE id_parkir = ?',
            [id]
        );

        if (transaksi.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const data = transaksi[0];

        // If status is 'masuk', update area terisi
        if (data.status === 'masuk' && data.id_area) {
            await pool.query(
                'UPDATE tb_area_parkir SET terisi = terisi - 1 WHERE id_area = ?',
                [data.id_area]
            );
        }

        // Delete transaksi
        await pool.query('DELETE FROM tb_transaksi WHERE id_parkir = ?', [id]);

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Hapus transaksi: ${data.plat_nomor}`]
        );

        res.json({
            success: true,
            message: 'Transaksi berhasil dihapus'
        });
    } catch (err) {
        console.error('Delete transaksi error:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};
