import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

// Halaman detail riwayat transaksi parkir per petugas
// Menampilkan semua transaksi yang ditangani petugas yang dipilih
// dilengkapi filter range tanggal dan pencarian plat nomor
class OwnerRiwayatDetailScreen extends StatefulWidget {
  final int idUser;
  final String namaPetugas;

  const OwnerRiwayatDetailScreen({
    super.key,
    required this.idUser,
    required this.namaPetugas,
  });

  @override
  State<OwnerRiwayatDetailScreen> createState() =>
      _OwnerRiwayatDetailScreenState();
}

class _OwnerRiwayatDetailScreenState
    extends State<OwnerRiwayatDetailScreen> {
  List<dynamic> _transaksi = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _searchQ = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default: bulan ini
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
      final response = await ApiService.get(
        '/transaksi/petugas/${widget.idUser}',
        auth: true,
      );
      final data = ApiService.handleResponse(response);
      final list = (data['data'] as List?) ?? [];
      setState(() {
        _transaksi = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  // Terapkan filter tanggal dan pencarian plat nomor
  void _applyFilters() {
    _filtered = _transaksi.where((t) {
      // Filter berdasarkan tanggal waktu masuk
      if (_startDate != null && t['waktu_masuk'] != null) {
        final wm = DateTime.tryParse(t['waktu_masuk'].toString());
        if (wm != null) {
          final d = DateTime(wm.year, wm.month, wm.day);
          final s = DateTime(
              _startDate!.year, _startDate!.month, _startDate!.day);
          final e = _endDate != null
              ? DateTime(
                  _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
              : DateTime(_startDate!.year, _startDate!.month,
                  _startDate!.day, 23, 59, 59);
          if (d.isBefore(s) || d.isAfter(e)) return false;
        }
      }
      // Filter pencarian plat nomor
      if (_searchQ.isNotEmpty) {
        return (t['plat_nomor'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQ.toLowerCase());
      }
      return true;
    }).toList();
  }

  int get _totalPendapatan => _filtered.fold(0, (sum, t) {
        final biaya = t['biaya_total'];
        if (biaya == null) return sum;
        final parsed =
            biaya is num ? biaya.toInt() : int.tryParse(biaya.toString()) ?? 0;
        return sum + parsed;
      });

  // Tampilkan date range picker
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
        title: Text(widget.namaPetugas,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          // ── Panel filter ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Colors.purple.shade50,
            child: Column(
              children: [
                // Pencarian plat nomor
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari plat nomor...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQ.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQ = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() {
                    _searchQ = val;
                    _applyFilters();
                  }),
                ),
                const SizedBox(height: 8),
                // Pemilih rentang tanggal
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range,
                            color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd MMM yyyy').format(_startDate!)} – ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                : 'Pilih rentang tanggal',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Ringkasan total ─────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    icon: Icons.receipt_long,
                    label: 'Total Transaksi',
                    value: '${_filtered.length}',
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryTile(
                    icon: Icons.attach_money,
                    label: 'Total Pendapatan',
                    value: Helpers.formatRupiah(_totalPendapatan),
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Daftar transaksi ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Belum ada riwayat parkir',
                                style:
                                    TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _pickDateRange,
                              icon: const Icon(Icons.date_range),
                              label: const Text('Ubah rentang tanggal'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final t = _filtered[index];
                            final biaya = t['biaya_total'];
                            final biayaInt = biaya == null
                                ? null
                                : (biaya is num
                                    ? biaya.toInt()
                                    : int.tryParse(biaya.toString()));
                            final isKeluar =
                                t['status']?.toString() == 'keluar';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Badge plat nomor
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            t['plat_nomor'] ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.purple.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          t['jenis_kendaraan'] ?? '-',
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                        const Spacer(),
                                        // Badge status
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isKeluar
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isKeluar
                                                  ? Colors.green.shade200
                                                  : Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            isKeluar ? 'Selesai' : 'Parkir',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isKeluar
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        _infoItem(
                                            Icons.login,
                                            'Masuk',
                                            Helpers.formatDateTime(
                                                t['waktu_masuk'] != null
                                                    ? DateTime.tryParse(
                                                        t['waktu_masuk'])
                                                    : null)),
                                        if (isKeluar)
                                          _infoItem(
                                              Icons.logout,
                                              'Keluar',
                                              Helpers.formatDateTime(
                                                  t['waktu_keluar'] != null
                                                      ? DateTime.tryParse(
                                                          t['waktu_keluar'])
                                                      : null)),
                                        if (t['durasi_jam'] != null)
                                          _infoItem(Icons.timer, 'Durasi',
                                              '${t['durasi_jam']} jam'),
                                        if (biayaInt != null)
                                          _infoItem(
                                              Icons.attach_money,
                                              'Biaya',
                                              Helpers.formatRupiah(biayaInt),
                                              highlight: true),
                                        if (t['nama_area'] != null)
                                          _infoItem(Icons.location_on,
                                              'Area', t['nama_area']),
                                      ],
                                    ),
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

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color:
                highlight ? Colors.green.shade600 : Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color:
                highlight ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight:
                highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
