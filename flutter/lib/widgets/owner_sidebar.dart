import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Widget Sidebar (Drawer) untuk navigasi menu Owner
// Menampilkan informasi pengguna yang sedang login dan menu laporan serta riwayat parkir
// [currentRoute] digunakan untuk menyorot menu yang sedang aktif
class OwnerSidebar extends StatelessWidget {
  final String currentRoute; // Nama route halaman yang sedang ditampilkan

  const OwnerSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // === Bagian Header Sidebar ===
          // Menampilkan avatar, nama, dan role owner yang sedang login
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), // Padding atas lebih besar untuk status bar
            decoration: BoxDecoration(
              // Gradient ungu untuk membedakan sidebar owner dari sidebar admin (indigo)
              gradient: LinearGradient(
                colors: [Colors.purple.shade800, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FutureBuilder<User?>(
              future: AuthService.getUserInfo(), // Ambil data user dari SharedPreferences
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar ikon pengguna dengan latar semi-transparan
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 35, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    // Nama lengkap owner - fallback 'Owner' jika data belum loaded
                    Text(
                      user?.namaLengkap ?? 'Owner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Role dalam huruf kapital
                    Text(
                      user?.role.toUpperCase() ?? 'OWNER',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),

          // === Bagian Daftar Menu ===
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildMenuItem(context, icon: Icons.dashboard, title: 'Dashboard', route: '/owner/dashboard'),
                _buildMenuItem(context, icon: Icons.receipt_long, title: 'Rekap Transaksi', route: '/owner/laporan'),
                _buildMenuItem(context, icon: Icons.local_parking, title: 'Riwayat Parkir', route: '/owner/riwayat'),
                const Divider(height: 1),
                // Tombol logout dengan warna merah sebagai penanda aksi berbahaya
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  route: '/logout',
                  isLogout: true,
                  color: Colors.red.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Membangun satu item menu di dalam sidebar
  // [icon] ikon Material, [title] label menu, [route] tujuan navigasi
  // [isLogout] jika true menjalankan logout bukan navigasi biasa
  // [color] warna ikon dan teks opsional (override warna default)
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
    Color? color,
  }) {
    // Tentukan apakah item ini adalah halaman yang sedang aktif
    final isActive = currentRoute == route;
    // Gunakan warna kustom jika ada, jika tidak gunakan ungu/abu berdasarkan status aktif
    final itemColor = color ?? (isActive ? Colors.purple.shade700 : Colors.grey.shade700);

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          // Merah untuk logout, ungu untuk menu aktif, abu-abu untuk menu biasa
          color: isLogout ? Colors.red.shade600 : (isActive ? Colors.purple.shade700 : Colors.grey.shade800),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      // Latar ungu muda untuk item yang aktif
      tileColor: isActive ? Colors.purple.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () async {
        Navigator.pop(context); // Tutup drawer sebelum navigasi
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
      },
    );
  }
}
