// Konfigurasi URL dan endpoint API backend
// File ini menyimpan semua konstanta alamat server yang digunakan oleh aplikasi
class ApiConfig {
  // URL dasar server backend - sesuaikan dengan alamat server Anda
  static const String baseUrl = 'http://localhost:3000/api';
  
  // === Endpoint Autentikasi Pengguna ===
  static const String login = '/user/login';       // Login dan dapatkan token JWT
  static const String logout = '/user/logout';     // Logout dan nonaktifkan sesi
  static const String register = '/user/register'; // Daftarkan pengguna baru
  static const String profile = '/user/profile';   // Ambil profil pengguna yang sedang login
  static const String users = '/user';             // CRUD data pengguna (admin)
  
  // === Endpoint Master Data ===
  static const String kendaraan = '/kendaraan'; // Data jenis kendaraan (motor, mobil, dll)
  static const String tarif = '/tarif';         // Tarif parkir per jam per jenis kendaraan
  static const String area = '/area';           // Data area/lokasi parkir beserta kapasitasnya
  
  // === Endpoint Transaksi Parkir ===
  static const String transaksi = '/transaksi';           // Daftar semua transaksi & tambah transaksi masuk
  static const String transaksiAktif = '/transaksi/aktif'; // Cek kendaraan yang masih parkir berdasarkan plat nomor
  static const String transaksiKeluar = '/transaksi';     // Proses kendaraan keluar (PUT /{id}/keluar)
  
  // === Endpoint Laporan & Dashboard ===
  static const String dashboard = '/laporan/dashboard';                     // Ringkasan statistik dashboard
  static const String laporanPendapatan = '/laporan/pendapatan';            // Laporan pendapatan parkir
  static const String laporanKendaraan = '/laporan/kendaraan';              // Laporan statistik kendaraan
  static const String laporanArea = '/laporan/area';                        // Laporan okupansi per area
  static const String laporanTransaksiDetail = '/laporan/transaksi-detail'; // Laporan transaksi lengkap dengan filter
  static const String laporanLogAktivitas = '/laporan/log-aktivitas';       // Log aktivitas pengguna di sistem
}
