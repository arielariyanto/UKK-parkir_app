// src/controller/kendaraanController.js
const pool = require('../config/database');

// Get all jenis kendaraan
const getAllJenisKendaraan = async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT * FROM tb_kendaraan ORDER BY jenis_kendaraan ASC');
        res.json({
            success: true,
            data: rows
        });
    } catch (error) {
        console.error('Get jenis kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data jenis kendaraan'
        });
    }
};

// Create jenis kendaraan
const createJenisKendaraan = async (req, res) => {
    try {
        const { jenis_kendaraan } = req.body;

        if (!jenis_kendaraan) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan harus diisi'
            });
        }

        // Cek apakah jenis sudah ada
        const [existing] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE jenis_kendaraan = ?',
            [jenis_kendaraan]
        );

        if (existing.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan sudah ada'
            });
        }

        // Insert dengan atau tanpa id_user tergantung apakah user tersedia
        const userId = req.user?.id_user || null;
        const [result] = await pool.query(
            'INSERT INTO tb_kendaraan (jenis_kendaraan' + (userId ? ', id_user' : '') + ') VALUES (?' + (userId ? ', ?' : '') + ')',
            userId ? [jenis_kendaraan, userId] : [jenis_kendaraan]
        );

        // Log aktivitas jika user tersedia
        if (userId) {
            await pool.query(
                'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
                [userId, `Menambah jenis kendaraan: ${jenis_kendaraan}`]
            );
        }

        res.status(201).json({
            success: true,
            message: 'Jenis kendaraan berhasil ditambahkan',
            data: {
                id_kendaraan: result.insertId,
                jenis_kendaraan
            }
        });
    } catch (error) {
        console.error('Create jenis kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menambahkan jenis kendaraan'
        });
    }
};

// Update jenis kendaraan
const updateJenisKendaraan = async (req, res) => {
    try {
        const { id } = req.params;
        const { jenis_kendaraan } = req.body;

        if (!jenis_kendaraan) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan harus diisi'
            });
        }

        const [existing] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE id_kendaraan = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Jenis kendaraan tidak ditemukan'
            });
        }

        // Cek apakah jenis baru sudah dipakai jenis lain
        const [duplicate] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE jenis_kendaraan = ? AND id_kendaraan != ?',
            [jenis_kendaraan, id]
        );

        if (duplicate.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan sudah ada'
            });
        }

        await pool.query(
            'UPDATE tb_kendaraan SET jenis_kendaraan = ? WHERE id_kendaraan = ?',
            [jenis_kendaraan, id]
        );

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Mengupdate jenis kendaraan: ${existing[0].jenis_kendaraan} → ${jenis_kendaraan}`]
        );

        res.json({
            success: true,
            message: 'Jenis kendaraan berhasil diupdate'
        });
    } catch (error) {
        console.error('Update jenis kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengupdate jenis kendaraan'
        });
    }
};

// Delete jenis kendaraan
const deleteJenisKendaraan = async (req, res) => {
    try {
        const { id } = req.params;

        const [existing] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE id_kendaraan = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Jenis kendaraan tidak ditemukan'
            });
        }

        // Cek apakah jenis dipakai di tb_tarif
        const [tarif] = await pool.query(
            'SELECT COUNT(*) as count FROM tb_tarif WHERE id_kendaraan = ?',
            [id]
        );

        if (tarif[0].count > 0) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan tidak dapat dihapus karena masih digunakan di tarif'
            });
        }

        // Cek apakah jenis dipakai di tb_transaksi
        const [transaksi] = await pool.query(
            'SELECT COUNT(*) as count FROM tb_transaksi WHERE id_kendaraan = ?',
            [id]
        );

        if (transaksi[0].count > 0) {
            return res.status(400).json({
                success: false,
                message: 'Jenis kendaraan tidak dapat dihapus karena masih digunakan di transaksi'
            });
        }

        await pool.query('DELETE FROM tb_kendaraan WHERE id_kendaraan = ?', [id]);

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Menghapus jenis kendaraan: ${existing[0].jenis_kendaraan}`]
        );

        res.json({
            success: true,
            message: 'Jenis kendaraan berhasil dihapus'
        });
    } catch (error) {
        console.error('Delete jenis kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menghapus jenis kendaraan'
        });
    }
};

module.exports = {
    getAllJenisKendaraan,
    createJenisKendaraan,
    updateJenisKendaraan,
    deleteJenisKendaraan
};
