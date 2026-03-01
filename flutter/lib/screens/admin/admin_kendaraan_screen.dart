import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/jenis_kendaraan_model.dart';
import '../../services/jenis_kendaraan_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminKendaraanScreen extends StatefulWidget {
  const AdminKendaraanScreen({super.key});

  @override
  State<AdminKendaraanScreen> createState() => _AdminKendaraanScreenState();
}

class _AdminKendaraanScreenState extends State<AdminKendaraanScreen> {
  List<JenisKendaraan> jenisKendaraanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJenisKendaraan();
  }

  Future<void> _loadJenisKendaraan() async {
    setState(() => isLoading = true);
    try {
      final data = await JenisKendaraanService.getAllJenisKendaraan();
      setState(() {
        jenisKendaraanList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showJenisDialog({JenisKendaraan? jenis}) {
    final controller = TextEditingController(text: jenis?.jenisKendaraan);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jenis == null ? 'Tambah Jenis Kendaraan' : 'Edit Jenis Kendaraan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Jenis Kendaraan',
            hintText: 'Contoh: Motor, Mobil, Truk',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jenis kendaraan harus diisi')),
                );
                return;
              }

              try {
                if (jenis == null) {
                  await JenisKendaraanService.createJenisKendaraan(
                    jenisKendaraan: controller.text,
                  );
                } else {
                  await JenisKendaraanService.updateJenisKendaraan(
                    idKendaraan: jenis.idKendaraan,
                    jenisKendaraan: controller.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadJenisKendaraan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(jenis == null 
                          ? 'Jenis kendaraan berhasil ditambahkan' 
                          : 'Jenis kendaraan berhasil diupdate'),
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
    );
  }

  Future<void> _deleteJenis(JenisKendaraan jenis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus jenis kendaraan "${jenis.jenisKendaraan}"?'),
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
        await JenisKendaraanService.deleteJenisKendaraan(jenis.idKendaraan);
        _loadJenisKendaraan();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jenis kendaraan berhasil dihapus'),
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
        title: const Text('Kelola Jenis Kendaraan'),
        automaticallyImplyLeading: !isMobile,
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/kendaraan') : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJenisDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jenis'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/kendaraan'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadJenisKendaraan,
                    child: jenisKendaraanList.isEmpty
                        ? const Center(child: Text('Belum ada data jenis kendaraan'))
                        : ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            itemCount: jenisKendaraanList.length,
                            itemBuilder: (context, index) {
                              final jenis = jenisKendaraanList[index];
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
                                      Icons.category,
                                      color: AppTheme.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                  title: Text(
                                    jenis.jenisKendaraan,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'ID: ${jenis.idKendaraan}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                        onPressed: () => _showJenisDialog(jenis: jenis),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                        onPressed: () => _deleteJenis(jenis),
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
