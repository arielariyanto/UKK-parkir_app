import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/transaksi_service.dart';
import '../../models/transaksi_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';

class AdminTransaksiScreen extends StatefulWidget {
  const AdminTransaksiScreen({super.key});

  @override
  State<AdminTransaksiScreen> createState() => _AdminTransaksiScreenState();
}

class _AdminTransaksiScreenState extends State<AdminTransaksiScreen> {
  List<Transaksi> transaksis = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaksis();
  }

  Future<void> _loadTransaksis() async {
    setState(() => isLoading = true);
    try {
      transaksis = await TransaksiService.getAllTransaksi();
      setState(() => isLoading = false);
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Transaksi'),
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/transaksi') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/transaksi'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTransaksis,
                    child: transaksis.isEmpty
                        ? const Center(child: Text('Belum ada transaksi'))
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
              backgroundColor: t.status == 'keluar' ? AppTheme.accentColor : AppTheme.warningColor,
              child: Icon(
                t.status == 'keluar' ? Icons.check : Icons.local_parking,
                color: Colors.white,
              ),
            ),
            title: Text(
              t.platNomor ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.jenisKendaraan} - ${t.namaArea ?? '-'}'),
                Text('Masuk: ${Helpers.formatDateTime(t.waktuMasuk)}'),
                if (t.waktuKeluar != null)
                  Text('Keluar: ${Helpers.formatDateTime(t.waktuKeluar)}'),
              ],
            ),
            trailing: t.biayaTotal != null
                ? Text(
                    Helpers.formatRupiah(t.biayaTotal!),
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
              DataColumn(label: Text('Petugas')),
            ],
            rows: transaksis.map((t) => DataRow(cells: [
              DataCell(Text(t.platNomor ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(t.jenisKendaraan ?? '')),
              DataCell(Text(t.namaArea ?? '-')),
              DataCell(Text(Helpers.formatDateTime(t.waktuMasuk))),
              DataCell(Text(t.waktuKeluar != null 
                  ? Helpers.formatDateTime(t.waktuKeluar) 
                  : '-')),
              DataCell(Text(t.durasiJam != null ? '${t.durasiJam} jam' : '-')),
              DataCell(Text(t.biayaTotal != null ? Helpers.formatRupiah(t.biayaTotal!) : '-')),
              DataCell(Chip(
                label: Text(t.status?.toUpperCase() ?? ''),
                backgroundColor: t.status == 'keluar' ? AppTheme.accentColor : AppTheme.warningColor,
              )),
              DataCell(Text(t.petugas ?? '-')),
            ])).toList(),
          ),
        ),
      ),
    );
  }
}
