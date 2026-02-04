const db = require("../config/database");

exports.getAll = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT k.*, u.nama_lengkap 
      FROM tb_kendaraan k
      JOIN tb_user u ON k.id_user = u.id_user
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const { plat_nomor, jenis_kendaraan, warna, pemilik, id_user } = req.body;

    const [result] = await db.query(
      `INSERT INTO tb_kendaraan (plat_nomor, jenis_kendaraan, warna, pemilik, id_user)
       VALUES (?,?,?,?,?)`,
      [plat_nomor, jenis_kendaraan, warna, pemilik, id_user]
    );

    res.json({ message: "Kendaraan berhasil ditambahkan", id: result.insertId });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
