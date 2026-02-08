import '../config/api_config.dart';
import '../models/tarif_model.dart';
import 'api_service.dart';

class TarifService {
  // Get all tarif
  static Future<List<Tarif>> getAllTarif() async {
    final response = await ApiService.get(ApiConfig.tarif);
    final data = ApiService.handleResponse(response);
    
    if (data['success']) {
      return (data['data'] as List)
          .map((json) => Tarif.fromJson(json))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data tarif');
    }
  }

  // Create tarif
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
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan tarif');
    }
  }

  // Update tarif
  static Future<void> updateTarif({
    required int idTarif,
    int? idKendaraan,
    required double tarifPerJam,
  }) async {
    final body = <String, dynamic>{
      'tarif_per_jam': tarifPerJam,
    };
    
    if (idKendaraan != null) {
      body['id_kendaraan'] = idKendaraan;
    }

    final response = await ApiService.put(
      '${ApiConfig.tarif}/$idTarif',
      body,
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate tarif');
    }
  }

  // Delete tarif
  static Future<void> deleteTarif(int idTarif) async {
    final response = await ApiService.delete(
      '${ApiConfig.tarif}/$idTarif',
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus tarif');
    }
  }
}
