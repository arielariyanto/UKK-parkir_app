import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/transaksi_service.dart';
import '../../models/transaksi_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/owner_sidebar.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Transaksi> _transaksiHariIni = [];
  bool _isLoading = true;

  // Summary stats
  int _totalMasuk = 0;
  int _totalKeluar = 0;
  int _sedangParkir = 0;
  int _totalPendapatan = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await TransaksiService.getAllTransaksi();
      final now = DateTime.now();
      final today = data.where((t) {
        if (t.waktuMasuk == null) return false;
        final d = t.waktuMasuk!.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      setState(() {
        _transaksiHariIni = today;
        _totalMasuk = today.length;
        _totalKeluar = today.where((t) => t.status == 'keluar').length;
        _sedangParkir = today.where((t) => t.status == 'masuk').length;
        _totalPendapatan = today
            .where((t) => t.biayaTotal != null)
            .fold(0, (sum, t) => sum + t.biayaTotal!);
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
        title: const Text('Dashboard Owner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const OwnerSidebar(currentRoute: '/owner/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade700, Colors.purple.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.bar_chart, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang, Owner!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pantau performa parkir hari ini',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section title
                    const Text(
                      'Statistik Hari Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: constraints.maxWidth > 600 ? 2.0 : 1.4,
                          children: [
                            _buildStatCard('Kendaraan Masuk', '$_totalMasuk', Icons.login, Colors.blue.shade600),
                            _buildStatCard('Kendaraan Keluar', '$_totalKeluar', Icons.logout, Colors.green.shade600),
                            _buildStatCard('Sedang Parkir', '$_sedangParkir', Icons.local_parking, Colors.orange.shade600),
                            _buildStatCard('Pendapatan', Helpers.formatRupiah(_totalPendapatan), Icons.attach_money, Colors.purple.shade600, smallText: true),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick action cards
                    

                    // Recent transactions
                    Row(
                      children: [
                        const Text(
                          'Transaksi Terbaru Hari Ini',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_transaksiHariIni.length} data',
                            style: TextStyle(color: Colors.purple.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _transaksiHariIni.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('Belum ada transaksi hari ini', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transaksiHariIni.take(10).length,
                              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
                              itemBuilder: (context, index) {
                                final t = _transaksiHariIni[index];
                                final isKeluar = t.status == 'keluar';
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isKeluar ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isKeluar ? Icons.check_circle : Icons.access_time,
                                      color: isKeluar ? Colors.green.shade600 : Colors.orange.shade600,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    t.platNomor ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${t.jenisKendaraan ?? '-'} • ${Helpers.formatDateTime(t.waktuMasuk)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  trailing: t.biayaTotal != null
                                      ? Text(
                                          Helpers.formatRupiah(t.biayaTotal!),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('Masuk', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                                        ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool smallText = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: smallText ? 13 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
