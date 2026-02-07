import '../config/api_config.dart';
import '../models/transaksi_model.dart';
import 'api_service.dart';

class TransaksiService {
  static Future<List<Transaksi>> getAllTransaksi() async {
    final response = await ApiService.get(ApiConfig.transaksi, auth: true);
    final data = ApiService.handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => Transaksi.fromJson(json))
        .toList();
  }

  static Future<Transaksi?> getActiveByPlat(String plat) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.transaksiAktif}/$plat',
        auth: true,
      );
      final data = ApiService.handleResponse(response);
      return Transaksi.fromJson(data['data']);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> parkirMasuk(Map<String, dynamic> data) async {
    final response = await ApiService.post(
      ApiConfig.transaksi,
      data,
      auth: true,
    );
    return ApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> parkirKeluar(int idParkir) async {
    final response = await ApiService.put(
      '${ApiConfig.transaksiKeluar}/$idParkir/keluar',
      {},
      auth: true,
    );
    return ApiService.handleResponse(response);
  }
}
