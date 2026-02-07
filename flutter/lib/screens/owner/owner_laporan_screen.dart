import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../services/laporan_service.dart';
import '../../utils/helpers.dart';

class OwnerLaporanScreen extends StatefulWidget {
  const OwnerLaporanScreen({super.key});

  @override
  State<OwnerLaporanScreen> createState() => _OwnerLaporanScreenState();
}

class _OwnerLaporanScreenState extends State<OwnerLaporanScreen> {
  List<dynamic> transaksis = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    setState(() => isLoading = true);
    try {
      final data = await LaporanService.getLaporanTransaksiDetail(
        tanggalMulai: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
        tanggalAkhir: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
      );
      setState(() {
        transaksis = data['data'] as List;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadLaporan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          if (startDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                });
                _loadLaporan();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (startDate != null && endDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadLaporan,
                    child: transaksis.isEmpty
                        ? const Center(child: Text('Tidak ada data'))
                        : isMobile
                            ? _buildMobileList()
                            : _buildDesktopTable(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transaksis.length,
      itemBuilder: (context, index) {
        final t = transaksis[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: t['status'] == 'keluar' ? AppTheme.accentColor : AppTheme.warningColor,
              child: Icon(
                t['status'] == 'keluar' ? Icons.check : Icons.local_parking,
                color: Colors.white,
              ),
            ),
            title: Text(
              t['plat_nomor'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t['jenis_kendaraan']} - ${t['nama_area'] ?? '-'}'),
                Text('Masuk: ${Helpers.formatDateTime(
                  t['waktu_masuk'] != null ? DateTime.parse(t['waktu_masuk']) : null,
                )}'),
                if (t['waktu_keluar'] != null)
                  Text('Keluar: ${Helpers.formatDateTime(DateTime.parse(t['waktu_keluar']))}'),
              ],
            ),
            trailing: t['biaya_total'] != null
                ? Text(
                    Helpers.formatRupiah(t['biaya_total']),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Plat Nomor')),
              DataColumn(label: Text('Jenis')),
              DataColumn(label: Text('Area')),
              DataColumn(label: Text('Waktu Masuk')),
              DataColumn(label: Text('Waktu Keluar')),
              DataColumn(label: Text('Durasi')),
              DataColumn(label: Text('Biaya')),
              DataColumn(label: Text('Status')),
            ],
            rows: transaksis.map((t) => DataRow(cells: [
              DataCell(Text(t['plat_nomor'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(t['jenis_kendaraan'] ?? '')),
              DataCell(Text(t['nama_area'] ?? '-')),
              DataCell(Text(Helpers.formatDateTime(
                t['waktu_masuk'] != null ? DateTime.parse(t['waktu_masuk']) : null,
              ))),
              DataCell(Text(t['waktu_keluar'] != null 
                  ? Helpers.formatDateTime(DateTime.parse(t['waktu_keluar'])) 
                  : '-')),
              DataCell(Text(t['durasi_jam'] != null ? '${t['durasi_jam']} jam' : '-')),
              DataCell(Text(t['biaya_total'] != null ? Helpers.formatRupiah(t['biaya_total']) : '-')),
              DataCell(Chip(
                label: Text(t['status']?.toUpperCase() ?? ''),
                backgroundColor: t['status'] == 'keluar' ? AppTheme.accentColor : AppTheme.warningColor,
              )),
            ])).toList(),
          ),
        ),
      ),
    );
  }
}
