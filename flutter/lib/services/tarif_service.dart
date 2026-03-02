import '../config/api_config.dart';
import '../models/tarif_model.dart';
import 'api_service.dart';

// Service untuk mengelola data Tarif Parkir melalui API
// Menyediakan operasi CRUD: baca semua tarif, tambah, ubah, dan hapus tarif
class TarifService {
  // Mengambil semua data tarif parkir dari server (termasuk nama jenis kendaraan dari JOIN)
  // Tidak memerlukan autentikasi
  // Mengembalikan List<Tarif> dengan informasi tarif per jam per jenis kendaraan
  static Future<List<Tarif>> getAllTarif() async {
    final response = await ApiService.get(ApiConfig.tarif);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      // Konversi list JSON menjadi list objek Tarif
      return (data['data'] as List)
          .map((json) => Tarif.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data tarif');
    }
  }

  // Menambahkan tarif baru untuk sebuah jenis kendaraan
  // Memerlukan autentikasi (hanya admin yang dapat mengelola tarif)
  // Parameter: [idKendaraan] jenis kendaraan, [tarifPerJam] besaran tarif dalam Rupiah
  static Future<void> createTarif({
    required int idKendaraan,
    required double tarifPerJam,
  }) async {
    final response = await ApiService.post(
      ApiConfig.tarif,
      {
        'id_kendaraan': idKendaraan,
        'tarif_per_jam': tarifPerJam,
      },
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan tarif');
    }
  }

  // Memperbarui tarif parkir yang sudah ada
  // Memerlukan autentikasi
  // [idKendaraan] bersifat opsional - hanya dikirim jika jenis kendaraan juga diubah
  static Future<void> updateTarif({
    required int idTarif,
    int? idKendaraan,
    required double tarifPerJam,
  }) async {
    // Mulai dengan field wajib
    final body = <String, dynamic>{
      'tarif_per_jam': tarifPerJam,
    };
    
    // Tambahkan id_kendaraan hanya jika diisi (field opsional)
    if (idKendaraan != null) {
      body['id_kendaraan'] = idKendaraan;
    }

    final response = await ApiService.put(
      '${ApiConfig.tarif}/$idTarif', // Endpoint dengan ID tarif di URL
      body,
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate tarif');
    }
  }

  // Menghapus tarif parkir berdasarkan ID
  // Memerlukan autentikasi
  // Parameter: [idTarif] ID tarif yang akan dihapus
  static Future<void> deleteTarif(int idTarif) async {
    final response = await ApiService.delete(
      '${ApiConfig.tarif}/$idTarif', // Endpoint dengan ID tarif di URL
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus tarif');
    }
  }
}
