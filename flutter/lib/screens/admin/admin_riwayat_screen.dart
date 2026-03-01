import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_sidebar.dart';
import 'admin_riwayat_detail_screen.dart';

class AdminRiwayatScreen extends StatefulWidget {
  const AdminRiwayatScreen({super.key});

  @override
  State<AdminRiwayatScreen> createState() => _AdminRiwayatScreenState();
}

class _AdminRiwayatScreenState extends State<AdminRiwayatScreen> {
  List<User> _petugasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPetugas();
  }

  Future<void> _loadPetugas() async {
    setState(() => _isLoading = true);
    try {
      final all = await UserService.getAllUsers();
      setState(() {
        _petugasList = all.where((u) => u.role == 'petugas').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Parkir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPetugas,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AdminSidebar(currentRoute: '/admin/riwayat'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.manage_accounts, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Petugas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_petugasList.length} petugas terdaftar',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _petugasList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Tidak ada data petugas',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPetugas,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _petugasList.length,
                            itemBuilder: (context, index) {
                              final petugas = _petugasList[index];
                              return _buildPetugasCard(petugas);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPetugasCard(User petugas) {
    final initials = (petugas.namaLengkap.isNotEmpty)
        ? petugas.namaLengkap.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'P';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminRiwayatDetailScreen(
                idUser: petugas.idUser!,
                namaPetugas: petugas.namaLengkap,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petugas.namaLengkap,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${petugas.username}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Status badge + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: petugas.isAktif ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: petugas.isAktif ? Colors.green.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      petugas.isAktif ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: petugas.isAktif ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
