import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'petugas_parkir_masuk_screen.dart';
import 'petugas_parkir_keluar_screen.dart';

class PetugasDashboardScreen extends StatefulWidget {
  const PetugasDashboardScreen({super.key});

  @override
  State<PetugasDashboardScreen> createState() => _PetugasDashboardScreenState();
}

class _PetugasDashboardScreenState extends State<PetugasDashboardScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const PetugasParkirMasukScreen(),
    const PetugasParkirKeluarScreen(),
    const PetugasProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Parkir Masuk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Parkir Keluar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class PetugasProfileScreen extends StatelessWidget {
  const PetugasProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<User?>(
        future: AuthService.getUserInfo(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Nama'),
                  subtitle: Text(user?.namaLengkap ?? '-'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Username'),
                  subtitle: Text(user?.username ?? '-'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Role'),
                  subtitle: Text(user?.role.toUpperCase() ?? '-'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
