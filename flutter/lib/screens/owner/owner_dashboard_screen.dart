import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../models/transaksi_model.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Transaksi> _allTransaksi = [];
  List<Transaksi> _filteredTransaksi = [];
  bool _isLoading = false;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Default: today
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    setState(() => _isLoading = true);
    try {
      final data = await TransaksiService.getAllTransaksi();
      setState(() {
        _allTransaksi = data;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredTransaksi = _allTransaksi.where((t) {
      // Filter by date
      if (_startDate != null && t.waktuMasuk != null) {
        final masukDate = DateTime(
          t.waktuMasuk!.year,
          t.waktuMasuk!.month,
          t.waktuMasuk!.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = _endDate != null
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 23, 59, 59);
        
        if (masukDate.isBefore(start) || masukDate.isAfter(end)) {
          return false;
        }
      }

      // Filter by status
      if (_filterStatus != null && _filterStatus != 'Semua') {
        if (t.status?.toLowerCase() != _filterStatus!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get _totalKendaraan => _filteredTransaksi.length;
  int get _kendaraanMasuk => _filteredTransaksi.where((t) => t.status == 'masuk').length;
  int get _kendaraanKeluar => _filteredTransaksi.where((t) => t.status == 'keluar').length;
  int get _totalPendapatan => _filteredTransaksi
      .where((t) => t.biayaTotal != null)
      .fold(0, (sum, t) => sum + t.biayaTotal!);

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Rekap Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransaksi,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
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
                          child: const Icon(Icons.assessment, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan Transaksi Parkir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rekap dan analisis data parkir',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_list, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter Data',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Range
                        InkWell(
                          onTap: _selectDateRange,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.purple.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _startDate != null && _endDate != null
                                        ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                        : 'Pilih Rentang Tanggal',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status Filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterStatus ?? 'Semua',
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.purple.shade700),
                              items: ['Semua', 'Masuk', 'Keluar'].map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Icon(
                                        status == 'Masuk' ? Icons.login :
                                        status == 'Keluar' ? Icons.logout :
                                        Icons.all_inclusive,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Status: $status'),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filterStatus = value;
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        'Total Kendaraan',
                        '$_totalKendaraan',
                        Icons.directions_car,
                        Colors.blue.shade700,
                      ),
                      _buildStatCard(
                        'Kendaraan Masuk',
                        '$_kendaraanMasuk',
                        Icons.login,
                        Colors.green.shade700,
                      ),
                      _buildStatCard(
                        'Kendaraan Keluar',
                        '$_kendaraanKeluar',
                        Icons.logout,
                        Colors.orange.shade700,
                      ),
                      _buildStatCard(
                        'Total Pendapatan',
                        Helpers.formatRupiah(_totalPendapatan),
                        Icons.attach_money,
                        Colors.purple.shade700,
                        isRevenue: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Transactions List
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Detail Transaksi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_filteredTransaksi.length} data',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _filteredTransaksi.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tidak ada transaksi',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTransaksi.length,
                                separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final t = _filteredTransaksi[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: t.status == 'keluar'
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            t.status == 'keluar' ? Icons.check_circle : Icons.access_time,
                                            color: t.status == 'keluar'
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.platNomor ?? '-',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${t.jenisKendaraan ?? '-'} • ${Helpers.formatDateTime(t.waktuMasuk)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (t.waktuKeluar != null)
                                                Text(
                                                  'Keluar: ${Helpers.formatDateTime(t.waktuKeluar)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (t.biayaTotal != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                Helpers.formatRupiah(t.biayaTotal!),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                              if (t.durasiJam != null)
                                                Text(
                                                  '${t.durasiJam} jam',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isRevenue = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isRevenue ? 14 : 20,
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
