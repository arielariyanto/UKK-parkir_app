import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/kendaraan_model.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminKendaraanScreen extends StatefulWidget {
  const AdminKendaraanScreen({super.key});

  @override
  State<AdminKendaraanScreen> createState() => _AdminKendaraanScreenState();
}

class _AdminKendaraanScreenState extends State<AdminKendaraanScreen> {
  List<Kendaraan> kendaraans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKendaraans();
  }

  Future<void> _loadKendaraans() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.kendaraan, auth: false);
      final data = ApiService.handleResponse(response);
      setState(() {
        kendaraans = (data['data'] as List).map((json) => Kendaraan.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data kendaraan: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteKendaraan(int id) async {
    try {
      await ApiService.delete('${ApiConfig.kendaraan}/$id', auth: true);
      _loadKendaraans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kendaraan berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showKendaraanDialog({Kendaraan? kendaraan}) {
    final platController = TextEditingController(text: kendaraan?.platNomor);
    final warnaController = TextEditingController(text: kendaraan?.warna);
    final pemilikController = TextEditingController(text: kendaraan?.pemilik);
    String selectedJenis = kendaraan?.jenisKendaraan ?? 'motor';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kendaraan == null ? 'Tambah Kendaraan' : 'Edit Kendaraan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: platController,
                decoration: const InputDecoration(labelText: 'Plat Nomor'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedJenis,
                  decoration: const InputDecoration(labelText: 'Jenis Kendaraan'),
                  items: ['motor', 'mobil']
                      .map((jenis) => DropdownMenuItem(value: jenis, child: Text(jenis.toUpperCase())))
                      .toList(),
                  onChanged: (value) => setState(() => selectedJenis = value!),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warnaController,
                decoration: const InputDecoration(labelText: 'Warna (opsional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pemilikController,
                decoration: const InputDecoration(labelText: 'Pemilik (opsional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'plat_nomor': platController.text.toUpperCase(),
                'jenis_kendaraan': selectedJenis,
                if (warnaController.text.isNotEmpty) 'warna': warnaController.text,
                if (pemilikController.text.isNotEmpty) 'pemilik': pemilikController.text,
              };

              try {
                if (kendaraan == null) {
                  await ApiService.post(ApiConfig.kendaraan, data, auth: true);
                } else {
                  await ApiService.put('${ApiConfig.kendaraan}/${kendaraan.idKendaraan}', data, auth: true);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadKendaraans();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(kendaraan == null ? 'Kendaraan berhasil ditambahkan' : 'Kendaraan berhasil diupdate')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kendaraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showKendaraanDialog(),
          ),
        ],
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/kendaraan') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/kendaraan'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadKendaraans,
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: [
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Plat Nomor')),
                                DataColumn(label: Text('Jenis')),
                                DataColumn(label: Text('Warna')),
                                DataColumn(label: Text('Pemilik')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: kendaraans.map((k) => DataRow(cells: [
                                DataCell(Text(k.platNomor, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Chip(
                                  label: Text(k.jenisKendaraan.toUpperCase()),
                                  backgroundColor: k.jenisKendaraan == 'motor' ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                )),
                                DataCell(Text(k.warna ?? '-')),
                                DataCell(Text(k.pemilik ?? '-')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                      onPressed: () => _showKendaraanDialog(kendaraan: k),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Konfirmasi'),
                                            content: Text('Hapus kendaraan ${k.platNomor}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteKendaraan(k.idKendaraan!);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )),
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
