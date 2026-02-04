const pool = require('../config/database');

// Get all tarif
const getAllTarif = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tb_tarif ORDER BY jenis_kendaraan ASC');

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

// Update tarif
const updateTarif = async (req, res) => {
  try {
    const { id } = req.params;
    const { tarif_per_jam } = req.body;

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

    await pool.query(
      'UPDATE tb_tarif SET tarif_per_jam = ? WHERE id_tarif = ?',
      [tarif_per_jam, id]
    );

    // Log aktivitas
    await pool.query(
      'INSERT INTO tb_log_aktivitas (id_user, aktivitas) VALUES (?, ?)',
      [req.user.id_user, `Mengupdate tarif ${existing[0].jenis_kendaraan}: Rp ${tarif_per_jam}`]
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

module.exports = {
  getAllTarif,
  getTarifById,
  updateTarif,
};