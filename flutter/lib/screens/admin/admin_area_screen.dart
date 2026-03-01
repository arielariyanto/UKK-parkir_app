import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme_config.dart';
import '../../models/area_model.dart';
import '../../services/area_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminAreaScreen extends StatefulWidget {
  const AdminAreaScreen({super.key});

  @override
  State<AdminAreaScreen> createState() => _AdminAreaScreenState();
}

class _AdminAreaScreenState extends State<AdminAreaScreen> {
  List<Area> areas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() => isLoading = true);
    try {
      final data = await AreaService.getAllAreas();
      setState(() {
        areas = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data area: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAreaDialog({Area? area}) {
    final nameController = TextEditingController(text: area?.namaArea);
    final capacityController = TextEditingController(
      text: area != null ? area.kapasitas.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area == null ? 'Tambah Area Parkir' : 'Edit Area Parkir'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Area',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Contoh: Area A, Lantai 1',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Kapasitas',
                  prefixIcon: Icon(Icons.local_parking),
                  hintText: 'Jumlah slot parkir',
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
              if (nameController.text.isEmpty || capacityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              final kapasitas = int.tryParse(capacityController.text);
              if (kapasitas == null || kapasitas <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kapasitas harus lebih dari 0')),
                );
                return;
              }

              try {
                if (area == null) {
                  await AreaService.createArea(
                    namaArea: nameController.text,
                    kapasitas: kapasitas,
                  );
                } else {
                  await AreaService.updateArea(
                    idArea: area.idArea!,
                    namaArea: nameController.text,
                    kapasitas: kapasitas,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAreas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(area == null
                          ? 'Area berhasil ditambahkan'
                          : 'Area berhasil diupdate'),
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

  Future<void> _deleteArea(Area area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus area "${area.namaArea}"?'),
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
        await AreaService.deleteArea(area.idArea!);
        _loadAreas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Area berhasil dihapus'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Area Parkir'),
      ),
      drawer: const AdminSidebar(currentRoute: '/admin/area'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAreaDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Area'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAreas,
              child: areas.isEmpty
                  ? const Center(child: Text('Belum ada data area parkir'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: areas.length,
                      itemBuilder: (context, index) {
                        final area = areas[index];
                        final occupancyRate = area.terisi / area.kapasitas;

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
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 32,
                              ),
                            ),
                            title: Text(
                              area.namaArea,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_parking, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Kapasitas: ${area.kapasitas} | Terisi: ${area.terisi} | Tersedia: ${area.tersedia}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: occupancyRate,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation(
                                        occupancyRate > 0.8
                                            ? AppTheme.errorColor
                                            : occupancyRate > 0.5
                                                ? Colors.orange
                                                : AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(occupancyRate * 100).toStringAsFixed(0)}% Terisi',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                  onPressed: () => _showAreaDialog(area: area),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                  onPressed: () => _deleteArea(area),
                                  tooltip: 'Hapus',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
