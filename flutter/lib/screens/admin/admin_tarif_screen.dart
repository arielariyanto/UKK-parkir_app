import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/tarif_model.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';

class AdminTarifScreen extends StatefulWidget {
  const AdminTarifScreen({super.key});

  @override
  State<AdminTarifScreen> createState() => _AdminTarifScreenState();
}

class _AdminTarifScreenState extends State<AdminTarifScreen> {
  List<Tarif> tarifs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTarifs();
  }

  Future<void> _loadTarifs() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.tarif, auth: false);
      final data = ApiService.handleResponse(response);
      setState(() {
        tarifs = (data['data'] as List).map((json) => Tarif.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data tarif: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showEditDialog(Tarif tarif) {
    final controller = TextEditingController(text: tarif.tarifPerJam.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tarif ${tarif.jenisKendaraan}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tarif per Jam (Rp)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.put(
                  '${ApiConfig.tarif}/${tarif.idTarif}',
                  {'tarif_per_jam': int.parse(controller.text)},
                  auth: true,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadTarifs();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarif berhasil diupdate')),
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
      appBar: AppBar(title: const Text('Kelola Tarif Parkir')),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/tarif') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/tarif'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTarifs,
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: tarifs.map((tarif) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Icon(
                            tarif.jenisKendaraan.toLowerCase() == 'motor'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                          title: Text(
                            tarif.jenisKendaraan.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            Helpers.formatRupiah(tarif.tarifPerJam) + ' / jam',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                            onPressed: () => _showEditDialog(tarif),
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

