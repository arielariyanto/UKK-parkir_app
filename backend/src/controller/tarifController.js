const pool = require('../config/database');

// Get all tarif
const getAllTarif = async (req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT t.*, k.jenis_kendaraan 
            FROM tb_tarif t
            JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
            ORDER BY k.jenis_kendaraan ASC
        `);

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get tarif error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data tarif',
        });
    }
};

// Get tarif by ID
const getTarifById = async (req, res) => {
    try {
        const { id } = req.params;

        const [rows] = await pool.query('SELECT * FROM tb_tarif WHERE id_tarif = ?', [id]);

        if (rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Tarif tidak ditemukan',
            });
        }

        res.json({
            success: true,
            data: rows[0],
        });
    } catch (error) {
        console.error('Get tarif by ID error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data tarif',
        });
    }
};

// Create tarif
const createTarif = async (req, res) => {
    try {
        const { id_kendaraan, tarif_per_jam } = req.body;

        // Validasi input
        if (!id_kendaraan || !tarif_per_jam) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan dan tarif per jam harus diisi',
            });
        }

        if (tarif_per_jam <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Tarif per jam harus lebih dari 0',
            });
        }

        // Cek apakah jenis kendaraan sudah ada tarifnya
        const [existing] = await pool.query(
            'SELECT * FROM tb_tarif WHERE id_kendaraan = ?',
            [id_kendaraan]
        );

        if (existing.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Tarif untuk jenis kendaraan ini sudah ada',
            });
        }

        // Get jenis kendaraan name for logging
        const [kendaraan] = await pool.query(
            'SELECT jenis_kendaraan FROM tb_kendaraan WHERE id_kendaraan = ?',
            [id_kendaraan]
        );

        // Insert tarif baru
        await pool.query(
            'INSERT INTO tb_tarif (id_kendaraan, tarif_per_jam, id_user) VALUES (?, ?, ?)',
            [id_kendaraan, tarif_per_jam, req.user.id_user]
        );

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Menambah tarif ${kendaraan[0].jenis_kendaraan}: Rp ${tarif_per_jam}`]
        );

        res.json({
            success: true,
            message: 'Tarif berhasil ditambahkan',
        });
    } catch (error) {
        console.error('Create tarif error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menambah tarif',
        });
    }
};

// Update tarif
const updateTarif = async (req, res) => {
    try {
        const { id } = req.params;
        const { id_kendaraan, tarif_per_jam } = req.body;

        if (!tarif_per_jam || tarif_per_jam <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Tarif per jam harus diisi dan lebih dari 0',
            });
        }

        const [existing] = await pool.query('SELECT * FROM tb_tarif WHERE id_tarif = ?', [id]);

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Tarif tidak ditemukan',
            });
        }

        // Cek apakah jenis kendaraan baru sudah dipakai tarif lain
        if (id_kendaraan && id_kendaraan !== existing[0].id_kendaraan) {
            const [duplicate] = await pool.query(
                'SELECT * FROM tb_tarif WHERE id_kendaraan = ? AND id_tarif != ?',
                [id_kendaraan, id]
            );

            if (duplicate.length > 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Tarif untuk jenis kendaraan ini sudah ada',
                });
            }
        }

        // Get jenis kendaraan name for logging
        const updateIdKendaraan = id_kendaraan || existing[0].id_kendaraan;
        const [kendaraan] = await pool.query(
            'SELECT jenis_kendaraan FROM tb_kendaraan WHERE id_kendaraan = ?',
            [updateIdKendaraan]
        );

        // Update tarif
        await pool.query(
            'UPDATE tb_tarif SET id_kendaraan = ?, tarif_per_jam = ? WHERE id_tarif = ?',
            [updateIdKendaraan, tarif_per_jam, id]
        );

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Mengupdate tarif ${kendaraan[0].jenis_kendaraan}: Rp ${tarif_per_jam}`]
        );

        res.json({
            success: true,
            message: 'Tarif berhasil diupdate',
        });
    } catch (error) {
        console.error('Update tarif error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengupdate tarif',
        });
    }
};

// Delete tarif
const deleteTarif = async (req, res) => {
    try {
        const { id } = req.params;

        const [existing] = await pool.query('SELECT * FROM tb_tarif WHERE id_tarif = ?', [id]);

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Tarif tidak ditemukan',
            });
        }

        // Cek apakah tarif sedang digunakan di tb_kendaraan
        const [kendaraan] = await pool.query(
            'SELECT COUNT(*) as count FROM tb_kendaraan WHERE jenis_kendaraan = ?',
            [existing[0].jenis_kendaraan]
        );

        if (kendaraan[0].count > 0) {
            return res.status(400).json({
                success: false,
                message: 'Tarif tidak dapat dihapus karena masih digunakan oleh kendaraan',
            });
        }

        // Delete tarif
        await pool.query('DELETE FROM tb_tarif WHERE id_tarif = ?', [id]);

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Menghapus tarif ${existing[0].jenis_kendaraan}`]
        );

        res.json({
            success: true,
            message: 'Tarif berhasil dihapus',
        });
    } catch (error) {
        console.error('Delete tarif error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menghapus tarif',
        });
    }
};

module.exports = {
    getAllTarif,
    getTarifById,
    createTarif,
    updateTarif,
    deleteTarif,
};