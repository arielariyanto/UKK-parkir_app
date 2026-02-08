import '../config/api_config.dart';
import '../models/area_model.dart';
import 'api_service.dart';

class AreaService {
  // Get all areas
  static Future<List<Area>> getAllAreas() async {
    final response = await ApiService.get(ApiConfig.area, auth: false);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      return (data['data'] as List)
          .map((json) => Area.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data area');
    }
  }

  // Create area
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
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan area');
    }
  }

  // Update area
  static Future<void> updateArea({
    required int idArea,
    required String namaArea,
    required int kapasitas,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.area}/$idArea',
      {
        'nama_area': namaArea,
        'kapasitas': kapasitas,
      },
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate area');
    }
  }

  // Delete area
  static Future<void> deleteArea(int idArea) async {
    final response = await ApiService.delete(
      '${ApiConfig.area}/$idArea',
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus area');
    }
  }
}
