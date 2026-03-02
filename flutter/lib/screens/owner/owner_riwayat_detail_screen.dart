import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

class OwnerRiwayatDetailScreen extends StatefulWidget {
  final int idUser;
  final String namaPetugas;

  const OwnerRiwayatDetailScreen({
    super.key,
    required this.idUser,
    required this.namaPetugas,
  });

  @override
  State<OwnerRiwayatDetailScreen> createState() => _OwnerRiwayatDetailScreenState();
}

class _OwnerRiwayatDetailScreenState extends State<OwnerRiwayatDetailScreen> {
  List<dynamic> _transaksi = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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
        _filtered = list;
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

  void _applySearch(String q) {
    setState(() {
      _filtered = _transaksi.where((t) {
        return (t['plat_nomor'] ?? '').toString().toLowerCase().contains(q.toLowerCase());
      }).toList();
    });
  }

  int get _totalPendapatan => _filtered.fold(0, (sum, t) {
        final biaya = t['biaya_total'];
        if (biaya == null) return sum;
        final parsed = biaya is num ? biaya.toInt() : int.tryParse(biaya.toString()) ?? 0;
        return sum + parsed;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaPetugas, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          // Summary banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
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

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari plat nomor...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _applySearch,
            ),
          ),

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
                            Text('Belum ada riwayat parkir',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final t = _filtered[index];
                            final biaya = t['biaya_total'];
                            final biayaInt = biaya == null
                                ? null
                                : (biaya is num
                                    ? biaya.toInt()
                                    : int.tryParse(biaya.toString()));

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
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
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                        const Spacer(),
                                        Text(
                                          biayaInt != null
                                              ? Helpers.formatRupiah(biayaInt)
                                              : 'Gratis',
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
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        _infoItem(Icons.login, 'Masuk',
                                            Helpers.formatDateTime(t['waktu_masuk'] != null
                                                ? DateTime.tryParse(t['waktu_masuk'])
                                                : null)),
                                        _infoItem(Icons.logout, 'Keluar',
                                            Helpers.formatDateTime(t['waktu_keluar'] != null
                                                ? DateTime.tryParse(t['waktu_keluar'])
                                                : null)),
                                        if (t['durasi_jam'] != null)
                                          _infoItem(Icons.timer, 'Durasi', '${t['durasi_jam']} jam'),
                                        if (t['nama_area'] != null)
                                          _infoItem(Icons.location_on, 'Area', t['nama_area']),
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
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text('$label: $value', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
