import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/laporan_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';

class AdminLogScreen extends StatefulWidget {
  const AdminLogScreen({super.key});

  @override
  State<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends State<AdminLogScreen> {
  List<dynamic> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => isLoading = true);
    try {
      final data = await LaporanService.getLaporanLogAktivitas();
      setState(() {
        logs = data['data'] as List;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat log aktivitas: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/log') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/log'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: [
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Waktu')),
                                DataColumn(label: Text('User')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Aktivitas')),
                              ],
                              rows: logs.map((log) => DataRow(cells: [
                                DataCell(Text(Helpers.formatDateTime(
                                  log['waktu_aktivitas'] != null 
                                      ? DateTime.parse(log['waktu_aktivitas']) 
                                      : null,
                                ))),
                                DataCell(Text(log['nama_lengkap'] ?? '-')),
                                DataCell(Chip(label: Text((log['role'] ?? '').toUpperCase()))),
                                DataCell(Text(log['aktivitas'] ?? '')),
                              ])).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
