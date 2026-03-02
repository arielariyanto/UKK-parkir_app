import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

// Widget Sidebar (Drawer) untuk navigasi menu Admin
// Menampilkan informasi pengguna yang sedang login dan daftar menu navigasi
// [currentRoute] digunakan untuk menyorot menu yang sedang aktif
class AdminSidebar extends StatelessWidget {
  final String currentRoute; // Nama route halaman yang sedang ditampilkan

  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // === Bagian Header Sidebar ===
          // Menampilkan avatar, nama, dan role pengguna yang sedang login
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient, // Latar gradient indigo-ungu
            ),
            child: FutureBuilder<User?>(
              future: AuthService.getUserInfo(), // Ambil data user dari SharedPreferences
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar ikon pengguna
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    // Nama lengkap pengguna - fallback 'Admin' jika data belum loaded
                    Text(
                      user?.namaLengkap ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Role pengguna dalam huruf kapital
                    Text(
                      user?.role.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // === Bagian Daftar Menu ===
          // Menggunakan ListView agar bisa di-scroll jika item terlalu banyak
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, icon: Icons.dashboard, title: 'Dashboard', route: '/admin/dashboard'),
                _buildMenuItem(context, icon: Icons.people, title: 'Kelola User', route: '/admin/users'),
                _buildMenuItem(context, icon: Icons.attach_money, title: 'Kelola Tarif', route: '/admin/tarif'),
                _buildMenuItem(context, icon: Icons.location_on, title: 'Kelola Area', route: '/admin/area'),
                _buildMenuItem(context, icon: Icons.directions_car, title: 'Kelola Kendaraan', route: '/admin/kendaraan'),
                _buildMenuItem(context, icon: Icons.receipt_long, title: 'Data Transaksi', route: '/admin/transaksi'),
                _buildMenuItem(context, icon: Icons.local_parking, title: 'Riwayat Parkir', route: '/admin/riwayat'),
                _buildMenuItem(context, icon: Icons.history, title: 'Log Aktivitas', route: '/admin/log'),
                const Divider(),
                // Tombol logout dengan flag khusus untuk memicu proses logout
                _buildMenuItem(context, icon: Icons.logout, title: 'Logout', route: '/logout', isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Membangun satu item menu di dalam sidebar
  // [icon] ikon Material, [title] teks label, [route] nama route tujuan
  // [isLogout] jika true, menjalankan proses logout bukan navigasi biasa
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    // Tentukan apakah item ini adalah halaman yang sedang aktif
    final isActive = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        // Warna indigo untuk menu aktif, abu-abu untuk menu lainnya
        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      // Latar belakang transparan indigo untuk item yang aktif
      tileColor: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
      onTap: () async {
        if (isLogout) {
          // Proses logout: hapus sesi lalu navigasi ke halaman login
          await AuthService.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else if (!isActive) {
          // Navigasi ke halaman lain (hanya jika berbeda dari halaman saat ini)
          Navigator.pushReplacementNamed(context, route);
        }
        // Jika item aktif diklik, tidak melakukan apa-apa
      },
    );
  }
}
