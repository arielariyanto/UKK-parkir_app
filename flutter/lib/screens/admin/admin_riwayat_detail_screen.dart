import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/theme_config.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

class AdminRiwayatDetailScreen extends StatefulWidget {
  final int idUser;
  final String namaPetugas;

  const AdminRiwayatDetailScreen({
    super.key,
    required this.idUser,
    required this.namaPetugas,
  });

  @override
  State<AdminRiwayatDetailScreen> createState() => _AdminRiwayatDetailScreenState();
}

class _AdminRiwayatDetailScreenState extends State<AdminRiwayatDetailScreen> {
  List<Map<String, dynamic>> _riwayat = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/transaksi/petugas/${widget.idUser}',
        auth: true,
      );
      final data = ApiService.handleResponse(response);
      setState(() {
        _riwayat = List<Map<String, dynamic>>.from(data['data'] ?? []);
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_riwayat);
    } else {
      _filtered = _riwayat.where((t) {
        final plat = (t['plat_nomor'] ?? '').toString().toLowerCase();
        return plat.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  String _formatDt(dynamic val) {
    if (val == null) return '-';
    try {
      return _dateFormat.format(DateTime.parse(val.toString()).toLocal());
    } catch (_) {
      return val.toString();
    }
  }

  Future<void> _cetakStruk(Map<String, dynamic> t) async {
    final pdf = pw.Document();

    final platNomor = t['plat_nomor']?.toString() ?? '-';
    final jenisKendaraan = t['jenis_kendaraan']?.toString() ?? '-';
    final namaArea = t['nama_area']?.toString() ?? '-';
    final waktuMasuk = _formatDt(t['waktu_masuk']);
    final waktuKeluar = _formatDt(t['waktu_keluar']);
    final durasiJam = t['durasi_jam']?.toString() ?? '0';
    final biayaTotal = int.tryParse(t['biaya_total']?.toString() ?? '0') ?? 0;
    final namaPetugas = t['nama_petugas']?.toString() ?? widget.namaPetugas;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'STRUK PARKIR',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('(Cetak Ulang)', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  pw.Divider(thickness: 1.5),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Info rows
            _pdfRow('Plat Nomor', platNomor),
            _pdfRow('Jenis Kendaraan', jenisKendaraan),
            _pdfRow('Area Parkir', namaArea),
            pw.Divider(),
            _pdfRow('Waktu Masuk', waktuMasuk),
            _pdfRow('Waktu Keluar', waktuKeluar),
            _pdfRow('Durasi', '$durasiJam jam'),
            pw.Divider(thickness: 1.5),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL BIAYA',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  Helpers.formatRupiah(biayaTotal),
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),

            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Petugas: $namaPetugas', style: pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text('Terima kasih!', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Riwayat — ${widget.namaPetugas}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiwayat,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStat('Total Transaksi', '${_riwayat.length}', Icons.receipt_long, Colors.blue.shade700),
                      const SizedBox(width: 16),
                      _buildStat(
                        'Total Pendapatan',
                        Helpers.formatRupiah(
                          _riwayat.fold<int>(0, (sum, t) => sum + (int.tryParse(t['biaya_total']?.toString() ?? '0') ?? 0)),
                        ),
                        Icons.attach_money,
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari plat nomor...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _applyFilter();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                        _applyFilter();
                      });
                    },
                  ),
                ),

                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} transaksi ditemukan',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Tidak ada riwayat parkir',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRiwayat,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              return _buildTransaksiCard(_filtered[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(Map<String, dynamic> t) {
    final platNomor = t['plat_nomor']?.toString() ?? '-';
    final jenisKendaraan = t['jenis_kendaraan']?.toString() ?? '-';
    final namaArea = t['nama_area']?.toString() ?? '-';
    final waktuMasuk = _formatDt(t['waktu_masuk']);
    final waktuKeluar = _formatDt(t['waktu_keluar']);
    final durasiJam = t['durasi_jam']?.toString() ?? '0';
    final biayaTotal = int.tryParse(t['biaya_total']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: plat + biaya
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    platNomor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jenisKendaraan,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        namaArea,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  Helpers.formatRupiah(biayaTotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),

            // Bottom row: waktu + durasi + cetak
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.login_rounded, 'Masuk', waktuMasuk, Colors.blue),
                      const SizedBox(height: 4),
                      _infoRow(Icons.logout_rounded, 'Keluar', waktuKeluar, Colors.orange),
                      const SizedBox(height: 4),
                      _infoRow(Icons.timer_outlined, 'Durasi', '$durasiJam jam', Colors.purple),
                    ],
                  ),
                ),
                // Cetak ulang button
                ElevatedButton.icon(
                  onPressed: () => _cetakStruk(t),
                  icon: const Icon(Icons.print, size: 18, color: Colors.white),
                  label: const Text('Cetak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
