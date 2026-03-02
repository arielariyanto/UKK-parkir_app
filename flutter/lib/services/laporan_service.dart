import '../config/api_config.dart';
import 'api_service.dart';

// Service untuk mengambil data laporan dan statistik dari server
// Digunakan oleh halaman Dashboard dan Laporan milik owner
class LaporanService {
  // Mengambil data ringkasan untuk halaman dashboard
  // Biasanya berisi total pendapatan hari ini, jumlah kendaraan, dll.
  // Memerlukan autentikasi
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiService.get(ApiConfig.dashboard, auth: true);
    return ApiService.handleResponse(response);
  }

  // Mengambil laporan transaksi secara detail dengan opsi filter
  // Digunakan untuk halaman rekap transaksi owner
  // Parameter opsional: [tanggalMulai], [tanggalAkhir] untuk filter rentang waktu
  // Parameter opsional: [status] untuk filter berdasarkan status ('aktif' atau 'selesai')
  static Future<Map<String, dynamic>> getLaporanTransaksiDetail({
    String? tanggalMulai,
    String? tanggalAkhir,
    String? status,
  }) async {
    String endpoint = ApiConfig.laporanTransaksiDetail;
    List<String> params = []; // Kumpulkan query parameter yang akan ditambahkan ke URL
    
    // Tambahkan query parameter hanya jika nilainya tidak null
    if (tanggalMulai != null) params.add('tanggal_mulai=$tanggalMulai');
    if (tanggalAkhir != null) params.add('tanggal_akhir=$tanggalAkhir');
    if (status != null) params.add('status=$status');
    
    // Gabungkan semua parameter dengan '&' dan tambahkan ke URL setelah '?'
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await ApiService.get(endpoint, auth: true);
    return ApiService.handleResponse(response);
  }

  // Mengambil laporan log aktivitas pengguna dengan filter tanggal opsional
  // Menampilkan semua aksi yang dilakukan admin/petugas di sistem
  // Parameter opsional: [tanggalMulai] dan [tanggalAkhir] untuk filter rentang waktu
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

  // Mengambil semua data pengguna untuk keperluan laporan
  // Memerlukan autentikasi level owner/admin
  static Future<Map<String, dynamic>> getAllUsers() async {
    final response = await ApiService.get(ApiConfig.users, auth: true);
    return ApiService.handleResponse(response);
  }
}
