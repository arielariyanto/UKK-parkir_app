const db = require("../config/database");

exports.getAll = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT t.*, 
             k.plat_nomor, 
             a.nama_area, 
             u.nama_lengkap
      FROM tb_transaksi t
      JOIN tb_kendaraan k ON t.id_kendaraan = k.id_kendaraan
      JOIN tb_area_parkir a ON t.id_area = a.id_area
      JOIN tb_user u ON t.id_user = u.id_user
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const {
      id_kendaraan,
      id_area,
      waktu_masuk,
      waktu_keluar,
      durasi_jam,
      biaya_total,
      status,
      id_user,
    } = req.body;

    const [result] = await db.query(
      `INSERT INTO tb_transaksi 
      (id_kendaraan, id_area, waktu_masuk, waktu_keluar, durasi_jam, biaya_total, status, id_user)
      VALUES (?,?,?,?,?,?,?,?)`,
      [id_kendaraan, id_area, waktu_masuk, waktu_keluar, durasi_jam, biaya_total, status, id_user]
    );

    res.json({ message: "Transaksi berhasil", id: result.insertId });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
