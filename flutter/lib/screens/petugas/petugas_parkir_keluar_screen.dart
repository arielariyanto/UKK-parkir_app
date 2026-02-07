import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/theme_config.dart';
import '../../services/transaksi_service.dart';
import '../../utils/helpers.dart';

class PetugasParkirKeluarScreen extends StatefulWidget {
  const PetugasParkirKeluarScreen({super.key});

  @override
  State<PetugasParkirKeluarScreen> createState() => _PetugasParkirKeluarScreenState();
}

class _PetugasParkirKeluarScreenState extends State<PetugasParkirKeluarScreen> {
  final _platController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  Map<String, dynamic>? _transaksiData;

  Future<void> _searchTransaksi() async {
    if (_platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan plat nomor')),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final transaksi = await TransaksiService.getActiveByPlat(_platController.text.toUpperCase());
      
      if (transaksi == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada transaksi aktif untuk plat nomor ini')),
          );
        }
        setState(() => _transaksiData = null);
      } else {
        setState(() {
          _transaksiData = {
            'id_parkir': transaksi.idParkir,
            'plat_nomor': transaksi.platNomor,
            'jenis_kendaraan': transaksi.jenisKendaraan,
            'waktu_masuk': transaksi.waktuMasuk,
            'nama_area': transaksi.namaArea,
            'tarif_per_jam': transaksi.tarifPerJam,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _processParkirKeluar() async {
    if (_transaksiData == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await TransaksiService.parkirKeluar(_transaksiData!['id_parkir']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Parkir keluar berhasil'),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        // Show receipt dialog
        _showReceiptDialog(result['data']);

        // Reset
        _platController.clear();
        setState(() => _transaksiData = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReceiptDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Struk Parkir'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptRow('Plat Nomor', data['plat_nomor']),
              _buildReceiptRow('Jenis', data['jenis_kendaraan']),
              _buildReceiptRow('Waktu Masuk', Helpers.formatDateTime(
                data['waktu_masuk'] != null ? DateTime.parse(data['waktu_masuk']) : null,
              )),
              _buildReceiptRow('Waktu Keluar', Helpers.formatDateTime(
                data['waktu_keluar'] != null ? DateTime.parse(data['waktu_keluar']) : null,
              )),
              _buildReceiptRow('Durasi', '${data['durasi_jam']} jam'),
              _buildReceiptRow('Tarif/Jam', Helpers.formatRupiah(data['tarif_per_jam'])),
              const Divider(),
              _buildReceiptRow('TOTAL', Helpers.formatRupiah(data['biaya_total']), bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () => _printReceipt(data),
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _printReceipt(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'STRUK PARKIR',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text('Plat Nomor: ${data['plat_nomor']}'),
              pw.Text('Jenis: ${data['jenis_kendaraan']}'),
              pw.Text('Waktu Masuk: ${Helpers.formatDateTime(
                data['waktu_masuk'] != null ? DateTime.parse(data['waktu_masuk']) : null,
              )}'),
              pw.Text('Waktu Keluar: ${Helpers.formatDateTime(
                data['waktu_keluar'] != null ? DateTime.parse(data['waktu_keluar']) : null,
              )}'),
              pw.Text('Durasi: ${data['durasi_jam']} jam'),
              pw.Text('Tarif/Jam: ${Helpers.formatRupiah(data['tarif_per_jam'])}'),
              pw.Divider(),
              pw.Text(
                'TOTAL: ${Helpers.formatRupiah(data['biaya_total'])}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Terima Kasih')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkir Keluar'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _platController,
                      decoration: const InputDecoration(
                        labelText: 'Plat Nomor',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchTransaksi,
                      icon: const Icon(Icons.search),
                      label: const Text('CARI'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_transaksiData != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Plat Nomor', _transaksiData!['plat_nomor']),
                      _buildInfoRow('Jenis', _transaksiData!['jenis_kendaraan']),
                      _buildInfoRow('Waktu Masuk', Helpers.formatDateTime(_transaksiData!['waktu_masuk'])),
                      _buildInfoRow('Area', _transaksiData!['nama_area'] ?? '-'),
                      _buildInfoRow('Tarif/Jam', Helpers.formatRupiah(_transaksiData!['tarif_per_jam'])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _processParkirKeluar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('PROSES PARKIR KELUAR', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
