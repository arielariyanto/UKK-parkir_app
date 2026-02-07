const bcrypt = require('bcrypt');
const pool = require('../config/database');

// Public registration (untuk testing/demo)
const publicRegister = async (req, res) => {
    try {
        const { nama_lengkap, username, password, role = 'petugas' } = req.body;

        // Validasi input
        if (!nama_lengkap || !username || !password) {
            return res.status(400).json({
                success: false,
                message: 'Nama lengkap, username, dan password harus diisi',
            });
        }

        // Cek username sudah ada
        const [existing] = await pool.query(
            'SELECT id_user FROM tb_user WHERE username = ?',
            [username]
        );

        if (existing.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Username sudah digunakan',
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert user baru
        const [result] = await pool.query(
            'INSERT INTO tb_user (nama_lengkap, username, password, role, status_aktif) VALUES (?, ?, ?, ?, 1)',
            [nama_lengkap, username, hashedPassword, role]
        );

        res.status(201).json({
            success: true,
            message: 'Registrasi berhasil',
            data: {
                id_user: result.insertId,
                nama_lengkap,
                username,
                role,
            },
        });
    } catch (error) {
        console.error('Public register error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat registrasi',
        });
    }
};

module.exports = {
    publicRegister,
};
