import 'package:flutter/material.dart';
import 'config/theme_config.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_tarif_screen.dart';
import 'screens/admin/admin_area_screen.dart';
import 'screens/admin/admin_kendaraan_screen.dart';
import 'screens/admin/admin_transaksi_screen.dart';
import 'screens/admin/admin_log_screen.dart';
import 'screens/admin/admin_riwayat_screen.dart';
import 'screens/petugas/petugas_dashboard_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/owner/owner_laporan_screen.dart';
import 'screens/owner/owner_riwayat_screen.dart';
import 'services/auth_service.dart';

// Titik masuk utama aplikasi Flutter
// Memanggil MyApp dan menjalankan seluruh aplikasi
void main() {
  runApp(const MyApp());
}

// Widget root aplikasi - mengonfigurasi MaterialApp dengan tema dan routing
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Parkir',
      theme: AppTheme.lightTheme,          // Tema visual global dari theme_config.dart
      debugShowCheckedModeBanner: false,    // Sembunyikan banner 'DEBUG' di pojok kanan atas
      home: const SplashScreen(),          // Halaman pertama yang ditampilkan saat aplikasi dibuka

      // Daftar semua named routes yang tersedia di aplikasi
      // Digunakan dengan Navigator.pushReplacementNamed(context, '/route')
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Route admin - hanya bisa diakses oleh pengguna dengan role 'admin'
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/tarif': (context) => const AdminTarifScreen(),
        '/admin/area': (context) => const AdminAreaScreen(),
        '/admin/kendaraan': (context) => const AdminKendaraanScreen(),
        '/admin/transaksi': (context) => const AdminTransaksiScreen(),
        '/admin/log': (context) => const AdminLogScreen(),
        '/admin/riwayat': (context) => const AdminRiwayatScreen(),

        // Route petugas - hanya bisa diakses oleh pengguna dengan role 'petugas'
        '/petugas/dashboard': (context) => const PetugasDashboardScreen(),

        // Route owner - hanya bisa diakses oleh pengguna dengan role 'owner'
        '/owner/dashboard': (context) => const OwnerDashboardScreen(),
        '/owner/laporan': (context) => const OwnerLaporanScreen(),
        '/owner/riwayat': (context) => const OwnerRiwayatScreen(),
      },
    );
  }
}

// Halaman Splash Screen - ditampilkan pertama kali saat aplikasi dibuka
// Memeriksa apakah pengguna sudah login dan mengarahkan ke halaman yang sesuai
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth(); // Segera cek status autentikasi saat widget pertama kali dibuat
  }

  // Memeriksa status login pengguna dan mengarahkan ke halaman yang tepat
  // Logika: jika sudah login -> dashboard sesuai role | jika belum -> halaman login
  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Tampilkan splash selama 1 detik
      
      final isLoggedIn = await AuthService.isLoggedIn(); // Cek apakah ada token tersimpan
      
      if (!mounted) return; // Pastikan widget masih ada sebelum navigasi

      if (isLoggedIn) {
        final user = await AuthService.getUserInfo(); // Ambil data user untuk mengetahui role
        if (user != null) {
          String route;
          // Tentukan halaman dashboard berdasarkan role pengguna
          switch (user.role) {
            case 'admin':
              route = '/admin/dashboard';
              break;
            case 'petugas':
              route = '/petugas/dashboard';
              break;
            case 'owner':
              route = '/owner/dashboard';
              break;
            default:
              route = '/login'; // Role tidak dikenal, arahkan ke login
          }
          Navigator.pushReplacementNamed(context, route);
          return;
        }
      }

      // Tidak ada sesi login - arahkan ke halaman login
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Fallback ke login jika ada error (terutama di web saat SharedPreferences bermasalah)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan splash screen: gradient latar, ikon parkir, nama aplikasi, dan loading spinner
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient, // Latar gradient indigo ke ungu
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon parkir besar berwarna putih
              Icon(
                Icons.local_parking_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              // Nama aplikasi
              const Text(
                'Aplikasi Parkir',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Loading indicator selama proses cek autentikasi
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
