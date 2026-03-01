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
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Parkir',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Admin routes
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/tarif': (context) => const AdminTarifScreen(),
        '/admin/area': (context) => const AdminAreaScreen(),
        '/admin/kendaraan': (context) => const AdminKendaraanScreen(),
        '/admin/transaksi': (context) => const AdminTransaksiScreen(),
        '/admin/log': (context) => const AdminLogScreen(),
        '/admin/riwayat': (context) => const AdminRiwayatScreen(),
        // Petugas routes
        '/petugas/dashboard': (context) => const PetugasDashboardScreen(),
        // Owner routes
        '/owner/dashboard': (context) => const OwnerDashboardScreen(),
        '/owner/laporan': (context) => const OwnerLaporanScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (!mounted) return;

      if (isLoggedIn) {
        final user = await AuthService.getUserInfo();
        if (user != null) {
          String route;
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
              route = '/login';
          }
          Navigator.pushReplacementNamed(context, route);
          return;
        }
      }

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Fallback ke login jika ada error (terutama di web)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_parking_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Aplikasi Parkir',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
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
