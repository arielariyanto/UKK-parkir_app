import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/area_model.dart';
import '../../services/api_service.dart';
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
      final response = await ApiService.get(ApiConfig.area, auth: false);
      final data = ApiService.handleResponse(response);
      setState(() {
        areas = (data['data'] as List).map((json) => Area.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data area: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteArea(int id) async {
    try {
      await ApiService.delete('${ApiConfig.area}/$id', auth: true);
      _loadAreas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAreaDialog({Area? area}) {
    final nameController = TextEditingController(text: area?.namaArea);
    final capacityController = TextEditingController(text: area?.kapasitas.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area == null ? 'Tambah Area' : 'Edit Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Area'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Kapasitas'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'nama_area': nameController.text,
                'kapasitas': int.parse(capacityController.text),
              };

              try {
                if (area == null) {
                  await ApiService.post(ApiConfig.area, data, auth: true);
                } else {
                  await ApiService.put('${ApiConfig.area}/${area.idArea}', data, auth: true);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAreas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(area == null ? 'Area berhasil ditambahkan' : 'Area berhasil diupdate')),
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
        title: const Text('Kelola Area Parkir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAreaDialog(),
          ),
        ],
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/area') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/area'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAreas,
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: areas.map((area) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 40),
                          title: Text(area.namaArea, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Kapasitas: ${area.kapasitas} | Terisi: ${area.terisi} | Tersedia: ${area.tersedia}'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: area.terisi / area.kapasitas,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(
                                  area.terisi / area.kapasitas > 0.8 ? AppTheme.errorColor : AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                onPressed: () => _showAreaDialog(area: area),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Konfirmasi'),
                                      content: Text('Hapus area ${area.namaArea}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteArea(area.idArea!);
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
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

