import '../config/api_config.dart';
import '../models/jenis_kendaraan_model.dart';
import 'api_service.dart';

// Service untuk mengelola data Jenis Kendaraan melalui API
// Jenis kendaraan adalah master data yang digunakan untuk menentukan tarif parkir
// Contoh jenis kendaraan: "Motor", "Mobil", "Truk"
class JenisKendaraanService {
  // Mengambil semua jenis kendaraan yang terdaftar di sistem
  // Tidak memerlukan autentikasi (master data bersifat umum)
  // Mengembalikan List<JenisKendaraan>
  static Future<List<JenisKendaraan>> getAllJenisKendaraan() async {
    final response = await ApiService.get(ApiConfig.kendaraan);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      // Konversi list JSON menjadi list objek JenisKendaraan
      return (data['data'] as List)
          .map((json) => JenisKendaraan.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data jenis kendaraan');
    }
  }

  // Menambahkan jenis kendaraan baru ke database
  // Memerlukan autentikasi (hanya admin yang dapat mengelola master data)
  // Parameter: [jenisKendaraan] nama jenis kendaraan yang akan ditambahkan
  static Future<void> createJenisKendaraan({
    required String jenisKendaraan,
  }) async {
    final response = await ApiService.post(
      ApiConfig.kendaraan,
      {
        'jenis_kendaraan': jenisKendaraan,
      },
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan jenis kendaraan');
    }
  }

  // Memperbarui nama jenis kendaraan yang sudah ada
  // Memerlukan autentikasi
  // Parameter: [idKendaraan] ID yang akan diubah, [jenisKendaraan] nama baru
  static Future<void> updateJenisKendaraan({
    required int idKendaraan,
    required String jenisKendaraan,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.kendaraan}/$idKendaraan', // Endpoint dengan ID di URL
      {
        'jenis_kendaraan': jenisKendaraan,
      },
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate jenis kendaraan');
    }
  }

  // Menghapus jenis kendaraan berdasarkan ID
  // Memerlukan autentikasi
  // Catatan: hapus tarif yang terkait terlebih dahulu jika ada foreign key constraint
  static Future<void> deleteJenisKendaraan(int idKendaraan) async {
    final response = await ApiService.delete(
      '${ApiConfig.kendaraan}/$idKendaraan', // Endpoint dengan ID di URL
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus jenis kendaraan');
    }
  }
}
