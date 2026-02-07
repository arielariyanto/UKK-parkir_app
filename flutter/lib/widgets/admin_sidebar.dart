import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: FutureBuilder<User?>(
              future: AuthService.getUserInfo(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.namaLengkap ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/admin/dashboard',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: 'Kelola User',
                  route: '/admin/users',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.attach_money,
                  title: 'Kelola Tarif',
                  route: '/admin/tarif',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.location_on,
                  title: 'Kelola Area',
                  route: '/admin/area',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.directions_car,
                  title: 'Kelola Kendaraan',
                  route: '/admin/kendaraan',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Data Transaksi',
                  route: '/admin/transaksi',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: 'Log Aktivitas',
                  route: '/admin/log',
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  route: '/logout',
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    final isActive = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
      onTap: () async {
        if (isLogout) {
          await AuthService.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
