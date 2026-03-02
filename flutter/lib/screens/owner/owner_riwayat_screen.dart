import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/owner_sidebar.dart';
import 'owner_riwayat_detail_screen.dart';

class OwnerRiwayatScreen extends StatefulWidget {
  const OwnerRiwayatScreen({super.key});

  @override
  State<OwnerRiwayatScreen> createState() => _OwnerRiwayatScreenState();
}

class _OwnerRiwayatScreenState extends State<OwnerRiwayatScreen> {
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
        title: const Text('Riwayat Parkir', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPetugas,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const OwnerSidebar(currentRoute: '/owner/riwayat'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.purple.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.manage_accounts, color: Colors.purple.shade700),
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

                // Petugas list
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
                              final initials = petugas.namaLengkap.isNotEmpty
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
                                        builder: (_) => OwnerRiwayatDetailScreen(
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
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.purple.shade600,
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
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
