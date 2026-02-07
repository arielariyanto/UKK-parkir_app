import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/laporan_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => isLoading = true);
    try {
      final data = await LaporanService.getDashboard();
      setState(() {
        dashboardData = data['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/dashboard') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/dashboard'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats cards
                          _buildStatsSection(isMobile),
                          const SizedBox(height: 24),
                          
                          // Area capacity
                          _buildAreaSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final hariIni = dashboardData?['hari_ini'] ?? {};
    final bulanIni = dashboardData?['bulan_ini'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Hari Ini',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Kendaraan Masuk',
              '${hariIni['kendaraan_masuk'] ?? 0}',
              Icons.login,
              AppTheme.accentColor,
              isMobile,
            ),
            _buildStatCard(
              'Kendaraan Keluar',
              '${hariIni['kendaraan_keluar'] ?? 0}',
              Icons.logout,
              AppTheme.primaryColor,
              isMobile,
            ),
            _buildStatCard(
              'Sedang Parkir',
              '${hariIni['sedang_parkir'] ?? 0}',
              Icons.local_parking,
              AppTheme.warningColor,
              isMobile,
            ),
            _buildStatCard(
              'Pendapatan Hari Ini',
              Helpers.formatRupiah(hariIni['pendapatan'] ?? 0),
              Icons.attach_money,
              AppTheme.accentColor,
              isMobile,
            ),
            _buildStatCard(
              'Pendapatan Bulan Ini',
              Helpers.formatRupiah(bulanIni['pendapatan'] ?? 0),
              Icons.trending_up,
              AppTheme.secondaryColor,
              isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSection() {
    final kapasitas = dashboardData?['kapasitas'] ?? {};
    final areas = dashboardData?['area'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapasitas Area Parkir',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Total capacity card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildCapacityInfo(
                    'Total Kapasitas',
                    '${kapasitas['total'] ?? 0}',
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildCapacityInfo(
                    'Terisi',
                    '${kapasitas['terisi'] ?? 0}',
                    AppTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: _buildCapacityInfo(
                    'Tersedia',
                    '${kapasitas['tersedia'] ?? 0}',
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Area details
        ...areas.map((area) {
          final terisi = area['terisi'] is int ? area['terisi'] : (int.tryParse(area['terisi']?.toString() ?? '0') ?? 0);
          final kapasitas = area['kapasitas'] is int ? area['kapasitas'] : (int.tryParse(area['kapasitas']?.toString() ?? '1') ?? 1);
          final persentase = double.tryParse(area['persentase_terisi']?.toString() ?? '0') ?? 0.0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
              title: Text(area['nama_area'] ?? ''),
              subtitle: LinearProgressIndicator(
                value: terisi / kapasitas,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  persentase > 80 ? AppTheme.errorColor : AppTheme.accentColor,
                ),
              ),
              trailing: Text(
                '$terisi/$kapasitas',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCapacityInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
