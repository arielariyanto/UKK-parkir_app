const pool = require('../config/database');

// Get all area
const getAllArea = async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM tb_area_parkir ORDER BY nama_area ASC'
        );

        res.json({
            success: true,
            data: rows,
        });
    } catch (error) {
        console.error('Get area error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data area',
        });
    }
};

// Get area by ID
const getAreaById = async (req, res) => {
    try {
        const { id } = req.params;

        const [rows] = await pool.query(
            'SELECT * FROM tb_area_parkir WHERE id_area = ?',
            [id]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Area tidak ditemukan',
            });
        }

        res.json({
            success: true,
            data: rows[0],
        });
    } catch (error) {
        console.error('Get area by ID error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data area',
        });
    }
};

// Create area
const createArea = async (req, res) => {
    try {
        const { nama_area, kapasitas } = req.body;

        if (!nama_area || !kapasitas) {
            return res.status(400).json({
                success: false,
                message: 'Nama area dan kapasitas harus diisi',
            });
        }

        const [result] = await pool.query(
            'INSERT INTO tb_area_parkir (nama_area, kapasitas, terisi) VALUES (?, ?, 0)',
            [nama_area, kapasitas]
        );

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Menambahkan area parkir: ${nama_area}`]
        );

        res.status(201).json({
            success: true,
            message: 'Area parkir berhasil ditambahkan',
            data: {
                id_area: result.insertId,
                nama_area,
                kapasitas,
            },
        });
    } catch (error) {
        console.error('Create area error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menambahkan area',
        });
    }
};

// Update area
const updateArea = async (req, res) => {
    try {
        const { id } = req.params;
        const { nama_area, kapasitas } = req.body;

        const [existing] = await pool.query(
            'SELECT * FROM tb_area_parkir WHERE id_area = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Area tidak ditemukan',
            });
        }

        // Validasi kapasitas tidak boleh lebih kecil dari terisi
        if (kapasitas < existing[0].terisi) {
            return res.status(400).json({
                success: false,
                message: `Kapasitas tidak boleh lebih kecil dari jumlah kendaraan yang sedang parkir (${existing[0].terisi})`,
            });
        }

        await pool.query(
            'UPDATE tb_area_parkir SET nama_area = ?, kapasitas = ? WHERE id_area = ?',
            [nama_area, kapasitas, id]
        );

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Mengupdate area parkir: ${nama_area}`]
        );

        res.json({
            success: true,
            message: 'Area parkir berhasil diupdate',
        });
    } catch (error) {
        console.error('Update area error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengupdate area',
        });
    }
};

// Delete area
const deleteArea = async (req, res) => {
    try {
        const { id } = req.params;

        const [existing] = await pool.query(
            'SELECT * FROM tb_area_parkir WHERE id_area = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Area tidak ditemukan',
            });
        }

        if (existing[0].terisi > 0) {
            return res.status(400).json({
                success: false,
                message: 'Tidak dapat menghapus area yang masih ada kendaraan parkir',
            });
        }

        await pool.query('DELETE FROM tb_area_parkir WHERE id_area = ?', [id]);

        // Log aktivitas
        await pool.query(
            'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
            [req.user.id_user, `Menghapus area parkir: ${existing[0].nama_area}`]
        );

        res.json({
            success: true,
            message: 'Area parkir berhasil dihapus',
        });
    } catch (error) {
        console.error('Delete area error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menghapus area',
        });
    }
};

module.exports = {
    getAllArea,
    getAreaById,
    createArea,
    updateArea,
    deleteArea,
};