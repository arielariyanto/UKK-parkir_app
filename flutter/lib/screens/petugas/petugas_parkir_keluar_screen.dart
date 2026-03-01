import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/theme_config.dart';
import '../../models/transaksi_model.dart';
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
  
  List<Transaksi> _activeTransaksi = [];
  List<Transaksi> _filteredTransaksi = [];
  String? _filterJenis;
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    _loadActiveTransaksi();
  }

  Future<void> _loadActiveTransaksi() async {
    setState(() => _isLoadingList = true);
    try {
      final allTransaksi = await TransaksiService.getAllTransaksi();
      setState(() {
        _activeTransaksi = allTransaksi.where((t) => t.status == 'masuk').toList();
        _applyFilter();
      });
    } catch (e) {
      // Ignore error
    } finally {
      setState(() => _isLoadingList = false);
    }
  }

  void _applyFilter() {
    if (_filterJenis == null || _filterJenis == 'Semua') {
      _filteredTransaksi = _activeTransaksi;
    } else {
      _filteredTransaksi = _activeTransaksi
          .where((t) => t.jenisKendaraan?.toLowerCase() == _filterJenis!.toLowerCase())
          .toList();
    }
  }

  Future<void> _searchTransaksi() async {
    if (_platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text('Masukkan plat nomor'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final transaksi = await TransaksiService.getActiveByPlat(_platController.text.toUpperCase());
      
      if (transaksi == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Tidak ada transaksi aktif untuk plat nomor ini')),
                ],
              ),
              backgroundColor: Colors.blue.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Parkir keluar berhasil')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Show receipt dialog
        _showReceiptDialog(result['data']);

        // Reset and reload
        _platController.clear();
        setState(() => _transaksiData = null);
        _loadActiveTransaksi();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectFromTable(Transaksi transaksi) {
    _platController.text = transaksi.platNomor ?? '';
    _searchTransaksi();
  }

  void _showReceiptDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Struk Parkir'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptRow('Plat Nomor', data['plat_nomor']?.toString() ?? '-'),
              _buildReceiptRow('Waktu Masuk', Helpers.formatDateTime(
                data['waktu_masuk'] != null ? DateTime.parse(data['waktu_masuk'].toString()) : null,
              )),
              _buildReceiptRow('Waktu Keluar', Helpers.formatDateTime(
                data['waktu_keluar'] != null ? DateTime.parse(data['waktu_keluar'].toString()) : null,
              )),
              _buildReceiptRow('Durasi', '${data['durasi_jam'] ?? 0} jam'),
              const Divider(height: 24),
              _buildReceiptRow('TOTAL', Helpers.formatRupiah(data['biaya_total'] ?? 0), bold: true),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 14,
              color: bold ? Colors.green.shade700 : Colors.black87,
            ),
          ),
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
              pw.Text('Plat Nomor: ${data['plat_nomor']?.toString() ?? '-'}'),
              pw.Text('Waktu Masuk: ${Helpers.formatDateTime(
                data['waktu_masuk'] != null ? DateTime.parse(data['waktu_masuk'].toString()) : null,
              )}'),
              pw.Text('Waktu Keluar: ${Helpers.formatDateTime(
                data['waktu_keluar'] != null ? DateTime.parse(data['waktu_keluar'].toString()) : null,
              )}'),
              pw.Text('Durasi: ${data['durasi_jam'] ?? 0} jam'),
              pw.Divider(),
              pw.Text(
                'TOTAL: ${Helpers.formatRupiah(data['biaya_total'] ?? 0)}',
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
    // Get unique jenis kendaraan for filter
    final jenisKendaraanList = ['Semua', ..._activeTransaksi
        .map((t) => t.jenisKendaraan)
        .where((j) => j != null)
        .toSet()
        .cast<String>()
        .toList()];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Parkir Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTransaksi,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200,
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
                    child: const Icon(Icons.exit_to_app, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proses Kendaraan Keluar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cari dan proses pembayaran parkir',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Card
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
                children: [
                  TextField(
                    controller: _platController,
                    decoration: InputDecoration(
                      labelText: 'Plat Nomor',
                      hintText: 'Contoh: B 1234 XYZ',
                      prefixIcon: Icon(Icons.credit_card, color: Colors.red.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _searchTransaksi(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade600, Colors.orange.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchTransaksi,
                      icon: const Icon(Icons.search, size: 22),
                      label: const Text(
                        'CARI KENDARAAN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_transaksiData != null) ...[ 
              const SizedBox(height: 24),
              
              // Detail Card
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Detail Transaksi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.credit_card, 'Plat Nomor', _transaksiData!['plat_nomor']),
                    _buildInfoRow(Icons.two_wheeler, 'Jenis', _transaksiData!['jenis_kendaraan'] ?? '-'),
                    _buildInfoRow(Icons.access_time, 'Waktu Masuk', Helpers.formatDateTime(_transaksiData!['waktu_masuk'])),
                    _buildInfoRow(Icons.location_on, 'Area', _transaksiData!['nama_area'] ?? '-'),
                    _buildInfoRow(Icons.attach_money, 'Tarif/Jam', Helpers.formatRupiah(_transaksiData!['tarif_per_jam'] ?? 0)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Process Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processParkirKeluar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'PROSES PARKIR KELUAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Vehicles Table
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.list_alt, color: Colors.purple.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Kendaraan Masih Parkir',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filteredTransaksi.length} unit',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter
                  if (jenisKendaraanList.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterJenis ?? 'Semua',
                          isExpanded: true,
                          icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
                          items: jenisKendaraanList.map((jenis) {
                            return DropdownMenuItem(
                              value: jenis,
                              child: Text('Filter: $jenis'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterJenis = value;
                              _applyFilter();
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Table
                  _isLoadingList
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _filteredTransaksi.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tidak ada kendaraan',
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
                                final transaksi = _filteredTransaksi[index];
                                final duration = transaksi.waktuMasuk != null
                                    ? DateTime.now().difference(transaksi.waktuMasuk!)
                                    : null;
                                final hours = duration != null ? duration.inHours : 0;
                                final minutes = duration != null ? duration.inMinutes % 60 : 0;

                                return InkWell(
                                  onTap: () => _selectFromTable(transaksi),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.directions_car,
                                            color: Colors.blue.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                transaksi.platNomor ?? '-',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      transaksi.jenisKendaraan ?? '-',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.purple.shade700,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${hours}j ${minutes}m',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                      ],
                                    ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _platController.dispose();
    super.dispose();
  }
}
