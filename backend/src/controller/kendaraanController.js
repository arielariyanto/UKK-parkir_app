// // src/controller/kendaraanController.js
// const pool = require('../config/database');

// const getAllKendaraan = async (req, res) => {
//   const [rows] = await pool.query('SELECT * FROM tb_kendaraan');
//   res.json(rows);
// };

// const createKendaraan = async (req, res) => {
//   const { plat_nomor, jenis_kendaraan } = req.body;
//   await pool.query(
//     'INSERT INTO tb_kendaraan (plat_nomor, jenis_kendaraan) VALUES (?, ?)',
//     [plat_nomor, jenis_kendaraan]
//   );
//   res.json({ message: 'Kendaraan berhasil ditambahkan' });
// };

// module.exports = {
//   getAllKendaraan,
//   createKendaraan,
// };
