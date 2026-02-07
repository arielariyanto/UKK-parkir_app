import '../config/api_config.dart';
import 'api_service.dart';

class LaporanService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiService.get(ApiConfig.dashboard, auth: true);
    return ApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLaporanTransaksiDetail({
    String? tanggalMulai,
    String? tanggalAkhir,
    String? status,
  }) async {
    String endpoint = ApiConfig.laporanTransaksiDetail;
    List<String> params = [];
    
    if (tanggalMulai != null) params.add('tanggal_mulai=$tanggalMulai');
    if (tanggalAkhir != null) params.add('tanggal_akhir=$tanggalAkhir');
    if (status != null) params.add('status=$status');
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await ApiService.get(endpoint, auth: true);
    return ApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLaporanLogAktivitas({
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    String endpoint = ApiConfig.laporanLogAktivitas;
    List<String> params = [];
    
    if (tanggalMulai != null) params.add('tanggal_mulai=$tanggalMulai');
    if (tanggalAkhir != null) params.add('tanggal_akhir=$tanggalAkhir');
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await ApiService.get(endpoint, auth: true);
    return ApiService.handleResponse(response);
  }
}
