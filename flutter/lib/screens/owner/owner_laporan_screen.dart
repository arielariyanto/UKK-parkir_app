import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../services/transaksi_service.dart';
import '../../models/transaksi_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/owner_sidebar.dart';

class OwnerLaporanScreen extends StatefulWidget {
  const OwnerLaporanScreen({super.key});

  @override
  State<OwnerLaporanScreen> createState() => _OwnerLaporanScreenState();
}

class _OwnerLaporanScreenState extends State<OwnerLaporanScreen> {
  List<Transaksi> _allTransaksi = [];
  List<Transaksi> _filtered = [];
  bool _isLoading = true;
  String _searchPlat = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default: this month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await TransaksiService.getAllTransaksi();
      setState(() {
        _allTransaksi = data.where((t) => t.status == 'keluar').toList();
        _applyFilters();
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

  void _applyFilters() {
    _filtered = _allTransaksi.where((t) {
      // Date filter
      if (_startDate != null && t.waktuMasuk != null) {
        final d = DateTime(t.waktuMasuk!.year, t.waktuMasuk!.month, t.waktuMasuk!.day);
        final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final e = _endDate != null
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 23, 59, 59);
        if (d.isBefore(s) || d.isAfter(e)) return false;
      }
      // Search
      if (_searchPlat.isNotEmpty) {
        return (t.platNomor ?? '').toLowerCase().contains(_searchPlat.toLowerCase());
      }
      return true;
    }).toList();
  }

  int get _totalPendapatan => _filtered
      .where((t) => t.biayaTotal != null)
      .fold(0, (sum, t) => sum + t.biayaTotal!);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.purple.shade700),
        ),
        child: child!,
      ),
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
      appBar: AppBar(
        title: const Text('Rekap Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const OwnerSidebar(currentRoute: '/owner/laporan'),
      body: Column(
        children: [
          // Filter panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari plat nomor...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchPlat.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchPlat = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() {
                    _searchPlat = val;
                    _applyFilters();
                  }),
                ),
                const SizedBox(height: 8),
                // Date range
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd MMM yyyy').format(_startDate!)} – ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                : 'Pilih rentang tanggal',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.receipt, size: 18, color: Colors.purple.shade700),
                const SizedBox(width: 6),
                Text('${_filtered.length} transaksi',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.attach_money, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  Helpers.formatRupiah(_totalPendapatan),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Tidak ada data', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final t = _filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            t.platNomor ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.jenisKendaraan ?? '-',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        const Spacer(),
                                        if (t.biayaTotal != null)
                                          Text(
                                            Helpers.formatRupiah(t.biayaTotal!),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                              fontSize: 15,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _infoChip(Icons.login, 'Masuk', Helpers.formatDateTime(t.waktuMasuk)),
                                        const SizedBox(width: 12),
                                        _infoChip(Icons.logout, 'Keluar', Helpers.formatDateTime(t.waktuKeluar)),
                                      ],
                                    ),
                                    if (t.durasiJam != null) ...[
                                      const SizedBox(height: 4),
                                      _infoChip(Icons.timer, 'Durasi', '${t.durasiJam} jam'),
                                    ],
                                  ],
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

  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
