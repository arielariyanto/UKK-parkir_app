class ApiConfig {
  // Base URL - Update this to match your backend server
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Endpoints
  static const String login = '/user/login';
  static const String logout = '/user/logout';
  static const String register = '/user/register';
  static const String profile = '/user/profile';
  static const String users = '/user';
  
  static const String kendaraan = '/kendaraan';
  static const String tarif = '/tarif';
  static const String area = '/area';
  
  static const String transaksi = '/transaksi';
  static const String transaksiAktif = '/transaksi/aktif';
  static const String transaksiKeluar = '/transaksi';
  
  static const String dashboard = '/laporan/dashboard';
  static const String laporanPendapatan = '/laporan/pendapatan';
  static const String laporanKendaraan = '/laporan/kendaraan';
  static const String laporanArea = '/laporan/area';
  static const String laporanTransaksiDetail = '/laporan/transaksi-detail';
  static const String laporanLogAktivitas = '/laporan/log-aktivitas';
}
