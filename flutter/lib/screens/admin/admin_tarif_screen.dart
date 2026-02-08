import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../models/tarif_model.dart';
import '../../models/jenis_kendaraan_model.dart';
import '../../services/tarif_service.dart';
import '../../services/jenis_kendaraan_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminTarifScreen extends StatefulWidget {
  const AdminTarifScreen({super.key});

  @override
  State<AdminTarifScreen> createState() => _AdminTarifScreenState();
}

class _AdminTarifScreenState extends State<AdminTarifScreen> {
  List<Tarif> tarifList = [];
  List<JenisKendaraan> jenisKendaraanList = [];
  bool isLoading = true;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTarif(),
      _loadJenisKendaraan(),
    ]);
  }

  Future<void> _loadJenisKendaraan() async {
    try {
      final data = await JenisKendaraanService.getAllJenisKendaraan();
      setState(() {
        jenisKendaraanList = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat jenis kendaraan: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadTarif() async {
    setState(() => isLoading = true);
    try {
      final data = await TarifService.getAllTarif();
      setState(() {
        tarifList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data tarif: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showTarifDialog({Tarif? tarif}) {
    int? selectedIdKendaraan = tarif?.idKendaraan;
    final tarifController = TextEditingController(
      text: tarif != null ? tarif.tarifPerJam.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tarif == null ? 'Tambah Tarif' : 'Edit Tarif'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedIdKendaraan,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kendaraan',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: jenisKendaraanList.map((jenis) {
                    return DropdownMenuItem<int>(
                      value: jenis.idKendaraan,
                      child: Text(jenis.jenisKendaraan),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedIdKendaraan = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tarifController,
                  decoration: const InputDecoration(
                    labelText: 'Tarif per Jam (Rp)',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                if (selectedIdKendaraan == null || tarifController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                final tarifValue = double.tryParse(tarifController.text);
                if (tarifValue == null || tarifValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarif harus lebih dari 0')),
                  );
                  return;
                }

                try {
                  if (tarif == null) {
                    await TarifService.createTarif(
                      idKendaraan: selectedIdKendaraan!,
                      tarifPerJam: tarifValue,
                    );
                  } else {
                    await TarifService.updateTarif(
                      idTarif: tarif.idTarif!,
                      idKendaraan: selectedIdKendaraan,
                      tarifPerJam: tarifValue,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadTarif();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tarif == null ? 'Tarif berhasil ditambahkan' : 'Tarif berhasil diupdate'),
                        backgroundColor: AppTheme.accentColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTarif(Tarif tarif) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus tarif ${tarif.jenisKendaraan}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TarifService.deleteTarif(tarif.idTarif!);
        _loadTarif();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarif berhasil dihapus'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tarif Parkir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTarifDialog(),
            tooltip: 'Tambah Tarif',
          ),
        ],
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/tarif') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/tarif'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTarif,
                    child: tarifList.isEmpty
                        ? const Center(child: Text('Belum ada data tarif'))
                        : ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            itemCount: tarifList.length,
                            itemBuilder: (context, index) {
                              final tarif = tarifList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_parking,
                                      color: AppTheme.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                  title: Text(
                                    tarif.jenisKendaraan ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${currencyFormatter.format(tarif.tarifPerJam)} / jam',
                                      style: TextStyle(
                                        color: AppTheme.accentColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                        onPressed: () => _showTarifDialog(tarif: tarif),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                        onPressed: () => _deleteTarif(tarif),
                                        tooltip: 'Hapus',
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
}
