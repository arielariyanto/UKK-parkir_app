import '../config/api_config.dart';
import '../models/jenis_kendaraan_model.dart';
import 'api_service.dart';

class JenisKendaraanService {
  // Get all jenis kendaraan
  static Future<List<JenisKendaraan>> getAllJenisKendaraan() async {
    final response = await ApiService.get(ApiConfig.kendaraan);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      return (data['data'] as List)
          .map((json) => JenisKendaraan.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data jenis kendaraan');
    }
  }

  // Create jenis kendaraan
  static Future<void> createJenisKendaraan({
    required String jenisKendaraan,
  }) async {
    final response = await ApiService.post(
      ApiConfig.kendaraan,
      {
        'jenis_kendaraan': jenisKendaraan,
      },
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan jenis kendaraan');
    }
  }

  // Update jenis kendaraan
  static Future<void> updateJenisKendaraan({
    required int idKendaraan,
    required String jenisKendaraan,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.kendaraan}/$idKendaraan',
      {
        'jenis_kendaraan': jenisKendaraan,
      },
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate jenis kendaraan');
    }
  }

  // Delete jenis kendaraan
  static Future<void> deleteJenisKendaraan(int idKendaraan) async {
    final response = await ApiService.delete(
      '${ApiConfig.kendaraan}/$idKendaraan',
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus jenis kendaraan');
    }
  }
}
