import '../config/api_config.dart';
import '../models/area_model.dart';
import 'api_service.dart';

// Service untuk mengelola data Area Parkir melalui API
// Menyediakan operasi CRUD: baca semua area, tambah, ubah, dan hapus area
class AreaService {
  // Mengambil semua data area parkir dari server
  // Tidak memerlukan autentikasi (data area bersifat publik)
  // Mengembalikan List<Area> yang berisi semua area yang terdaftar
  static Future<List<Area>> getAllAreas() async {
    final response = await ApiService.get(ApiConfig.area, auth: false);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      // Konversi list JSON menjadi list objek Area menggunakan factory constructor
      return (data['data'] as List)
          .map((json) => Area.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data area');
    }
  }

  // Menambahkan area parkir baru ke database melalui API
  // Memerlukan autentikasi (hanya admin yang dapat menambah area)
  // Parameter: [namaArea] nama area baru, [kapasitas] jumlah slot maksimum
  static Future<void> createArea({
    required String namaArea,
    required int kapasitas,
  }) async {
    final response = await ApiService.post(
      ApiConfig.area,
      {
        'nama_area': namaArea,
        'kapasitas': kapasitas,
      },
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan area');
    }
  }

  // Memperbarui data area parkir yang sudah ada
  // Memerlukan autentikasi (hanya admin yang dapat mengubah area)
  // Parameter: [idArea] area yang akan diubah, [namaArea] dan [kapasitas] data baru
  static Future<void> updateArea({
    required int idArea,
    required String namaArea,
    required int kapasitas,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.area}/$idArea', // Endpoint dengan ID area di URL
      {
        'nama_area': namaArea,
        'kapasitas': kapasitas,
      },
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate area');
    }
  }

  // Menghapus area parkir berdasarkan ID
  // Memerlukan autentikasi (hanya admin yang dapat menghapus area)
  // Parameter: [idArea] ID area yang akan dihapus
  static Future<void> deleteArea(int idArea) async {
    final response = await ApiService.delete(
      '${ApiConfig.area}/$idArea', // Endpoint dengan ID area di URL
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus area');
    }
  }
}
