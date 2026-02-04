const pool = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Login
const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validasi input
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username dan password harus diisi',
      });
    }

    // Cari user
    const [rows] = await pool.query(
      'SELECT * FROM tb_user WHERE username = ? AND status_aktif = 1',
      [username]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Username atau password salah',
      });
    }

    const user = rows[0];

    // Verifikasi password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Username atau password salah',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id_user: user.id_user,
        username: user.username,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    // Log aktivitas
    await pool.query(
      'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
      [user.id_user, 'Login ke sistem']
    );

    res.json({
      success: true,
      message: 'Login berhasil',
      data: {
        token,
        user: {
          id_user: user.id_user,
          nama_lengkap: user.nama_lengkap,
          username: user.username,
          role: user.role,
        },
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat login',
    });
  }
};

// Get Profile
const getProfile = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id_user, nama_lengkap, username, role, status_aktif FROM tb_user WHERE id_user = ?',
      [req.user.id_user]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan',
      });
    }

    res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat mengambil profil',
    });
  }
};

// Register (hanya untuk admin)
const register = async (req, res) => {
  try {
    const { nama_lengkap, username, password, role } = req.body;

    // Validasi input
    if (!username || !password || !role) {
      return res.status(400).json({
        success: false,
        message: 'Username, password, dan role harus diisi',
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
      'INSERT INTO tb_user (nama_lengkap, username, password, role) VALUES (?, ?, ?, ?)',
      [nama_lengkap, username, hashedPassword, role]
    );

    // Log aktivitas
    await pool.query(
      'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
      [req.user.id_user, `Menambahkan user baru: ${username}`]
    );

    res.status(201).json({
      success: true,
      message: 'User berhasil didaftarkan',
      data: {
        id_user: result.insertId,
        username,
        role,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat mendaftarkan user',
    });
  }
};

module.exports = {
  login,
  getProfile,
  register,
};