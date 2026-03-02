import '../config/api_config.dart';
import '../models/transaksi_model.dart';
import 'api_service.dart';

// Service untuk mengelola transaksi parkir melalui API
// Menangani proses kendaraan masuk, cek status aktif, dan kendaraan keluar
class TransaksiService {
  // Mengambil semua data transaksi parkir (termasuk yang sudah selesai)
  // Memerlukan autentikasi
  // Mengembalikan List<Transaksi> dengan data lengkap dari JOIN beberapa tabel
  static Future<List<Transaksi>> getAllTransaksi() async {
    final response = await ApiService.get(ApiConfig.transaksi, auth: true);
    final data = ApiService.handleResponse(response);
    
    // Konversi list JSON menjadi list objek Transaksi
    return (data['data'] as List)
        .map((json) => Transaksi.fromJson(json))
        .toList();
  }

  // Mencari transaksi aktif berdasarkan plat nomor kendaraan
  // Digunakan saat petugas memproses kendaraan keluar untuk mendapatkan data masuk
  // Mengembalikan objek Transaksi jika ditemukan, atau null jika tidak ada / error
  static Future<Transaksi?> getActiveByPlat(String plat) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.transaksiAktif}/$plat', // Endpoint: /transaksi/aktif/{plat_nomor}
        auth: true,
      );
      final data = ApiService.handleResponse(response);
      return Transaksi.fromJson(data['data']); // Parse data kendaraan yang sedang parkir
    } catch (e) {
      // Kembalikan null jika kendaraan tidak ditemukan atau terjadi error
      return null;
    }
  }

  // Memproses kendaraan masuk parkir (membuat transaksi baru)
  // [data] berisi: id_kendaraan, id_area, id_user, dan waktu_masuk
  // Memerlukan autentikasi
  // Mengembalikan Map data transaksi yang baru dibuat
  static Future<Map<String, dynamic>> parkirMasuk(Map<String, dynamic> data) async {
    final response = await ApiService.post(
      ApiConfig.transaksi, // POST /transaksi
      data,
      auth: true,
    );
    return ApiService.handleResponse(response);
  }

  // Memproses kendaraan keluar parkir (menutup transaksi)
  // [idParkir] adalah ID transaksi yang akan ditutup
  // Server akan menghitung durasi dan biaya secara otomatis berdasarkan waktu masuk
  // Memerlukan autentikasi
  static Future<Map<String, dynamic>> parkirKeluar(int idParkir) async {
    final response = await ApiService.put(
      '${ApiConfig.transaksiKeluar}/$idParkir/keluar', // PUT /transaksi/{id}/keluar
      {}, // Body kosong karena server menghitung sendiri
      auth: true,
    );
    return ApiService.handleResponse(response);
  }
}
