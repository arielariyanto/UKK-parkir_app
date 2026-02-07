// src/controller/kendaraanController.js
const pool = require('../config/database');

const getAllKendaraan = async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT * FROM tb_kendaraan ORDER BY plat_nomor ASC');
        res.json({
            success: true,
            data: rows
        });
    } catch (error) {
        console.error('Get kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengambil data kendaraan'
        });
    }
};

const createKendaraan = async (req, res) => {
    try {
        const { plat_nomor, jenis_kendaraan, warna, pemilik } = req.body;

        if (!plat_nomor || !jenis_kendaraan) {
            return res.status(400).json({
                success: false,
                message: 'Plat nomor dan jenis kendaraan harus diisi'
            });
        }

        const [result] = await pool.query(
            'INSERT INTO tb_kendaraan (plat_nomor, jenis_kendaraan, warna, pemilik) VALUES (?, ?, ?, ?)',
            [plat_nomor, jenis_kendaraan, warna || null, pemilik || null]
        );

        res.status(201).json({
            success: true,
            message: 'Kendaraan berhasil ditambahkan',
            data: {
                id_kendaraan: result.insertId,
                plat_nomor,
                jenis_kendaraan
            }
        });
    } catch (error) {
        console.error('Create kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menambahkan kendaraan'
        });
    }
};

const updateKendaraan = async (req, res) => {
    try {
        const { id } = req.params;
        const { plat_nomor, jenis_kendaraan, warna, pemilik } = req.body;

        const [existing] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE id_kendaraan = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kendaraan tidak ditemukan'
            });
        }

        await pool.query(
            'UPDATE tb_kendaraan SET plat_nomor = ?, jenis_kendaraan = ?, warna = ?, pemilik = ? WHERE id_kendaraan = ?',
            [plat_nomor, jenis_kendaraan, warna, pemilik, id]
        );

        res.json({
            success: true,
            message: 'Kendaraan berhasil diupdate'
        });
    } catch (error) {
        console.error('Update kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat mengupdate kendaraan'
        });
    }
};

const deleteKendaraan = async (req, res) => {
    try {
        const { id } = req.params;

        const [existing] = await pool.query(
            'SELECT * FROM tb_kendaraan WHERE id_kendaraan = ?',
            [id]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kendaraan tidak ditemukan'
            });
        }

        await pool.query('DELETE FROM tb_kendaraan WHERE id_kendaraan = ?', [id]);

        res.json({
            success: true,
            message: 'Kendaraan berhasil dihapus'
        });
    } catch (error) {
        console.error('Delete kendaraan error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat menghapus kendaraan'
        });
    }
};

module.exports = {
    getAllKendaraan,
    createKendaraan,
    updateKendaraan,
    deleteKendaraan
};
