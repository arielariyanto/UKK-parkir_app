import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/area_model.dart';
import '../../services/api_service.dart';
import '../../services/transaksi_service.dart';

class PetugasParkirMasukScreen extends StatefulWidget {
  const PetugasParkirMasukScreen({super.key});

  @override
  State<PetugasParkirMasukScreen> createState() => _PetugasParkirMasukScreenState();
}

class _PetugasParkirMasukScreenState extends State<PetugasParkirMasukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _platController = TextEditingController();
  final _warnaController = TextEditingController();
  final _pemilikController = TextEditingController();
  
  String _jenisKendaraan = 'motor';
  int? _selectedAreaId;
  List<Area> _areas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final response = await ApiService.get(ApiConfig.area, auth: false);
      final data = ApiService.handleResponse(response);
      setState(() {
        _areas = (data['data'] as List).map((json) => Area.fromJson(json)).toList();
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _submitParkirMasuk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'plat_nomor': _platController.text.toUpperCase(),
        'jenis_kendaraan': _jenisKendaraan,
        if (_warnaController.text.isNotEmpty) 'warna': _warnaController.text,
        if (_pemilikController.text.isNotEmpty) 'pemilik': _pemilikController.text,
        if (_selectedAreaId != null) 'id_area': _selectedAreaId,
      };

      final result = await TransaksiService.parkirMasuk(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Parkir masuk berhasil'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        _platController.clear();
        _warnaController.clear();
        _pemilikController.clear();
        setState(() {
          _jenisKendaraan = 'motor';
          _selectedAreaId = null;
        });
        _loadAreas();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkir Masuk'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Kendaraan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _platController,
                        decoration: const InputDecoration(
                          labelText: 'Plat Nomor *',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Plat nomor harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _jenisKendaraan,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kendaraan *',
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'motor', child: Text('Motor')),
                          DropdownMenuItem(value: 'mobil', child: Text('Mobil')),
                        ],
                        onChanged: (value) => setState(() => _jenisKendaraan = value!),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _warnaController,
                        decoration: const InputDecoration(
                          labelText: 'Warna (opsional)',
                          prefixIcon: Icon(Icons.palette),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _pemilikController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Pemilik (opsional)',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        value: _selectedAreaId,
                        decoration: const InputDecoration(
                          labelText: 'Area Parkir (opsional)',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: _areas.map((area) => DropdownMenuItem(
                          value: area.idArea,
                          child: Text('${area.namaArea} (${area.tersedia} tersedia)'),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedAreaId = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitParkirMasuk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
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
                    : const Text('PARKIR MASUK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
