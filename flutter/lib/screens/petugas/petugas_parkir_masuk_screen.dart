import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/area_model.dart';
import '../../models/jenis_kendaraan_model.dart';
import '../../models/tarif_model.dart';
import '../../services/api_service.dart';
import '../../services/transaksi_service.dart';
import '../../services/jenis_kendaraan_service.dart';
import '../../services/tarif_service.dart';

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
  
  int? _selectedKendaraanId;
  int? _selectedAreaId;
  List<JenisKendaraan> _jenisKendaraanList = [];
  List<Area> _areas = [];
  Tarif? _selectedTarif;
  bool _isLoading = false;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAreas(),
      _loadJenisKendaraan(),
    ]);
  }

  Future<void> _loadJenisKendaraan() async {
    try {
      final data = await JenisKendaraanService.getAllJenisKendaraan();
      setState(() {
        _jenisKendaraanList = data;
      });
    } catch (e) {
      // Ignore error
    }
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

  Future<void> _loadTarif(int idKendaraan) async {
    try {
      final tarifList = await TarifService.getAllTarif();
      final tarif = tarifList.firstWhere(
        (t) => t.idKendaraan == idKendaraan,
        orElse: () => Tarif(tarifPerJam: 0),
      );
      setState(() {
        _selectedTarif = tarif;
      });
    } catch (e) {
      setState(() {
        _selectedTarif = null;
      });
    }
  }

  Future<void> _submitParkirMasuk() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKendaraanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis kendaraan terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'plat_nomor': _platController.text.toUpperCase(),
        'id_kendaraan': _selectedKendaraanId,
        if (_warnaController.text.isNotEmpty) 'warna': _warnaController.text,
        if (_pemilikController.text.isNotEmpty) 'pemilik': _pemilikController.text,
        if (_selectedAreaId != null) 'id_area': _selectedAreaId,
      };

      final result = await TransaksiService.parkirMasuk(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Parkir masuk berhasil')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        _platController.clear();
        _warnaController.clear();
        _pemilikController.clear();
        setState(() {
          _selectedKendaraanId = null;
          _selectedAreaId = null;
          _selectedTarif = null;
        });
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Parkir Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
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
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Input Kendaraan Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Isi data kendaraan yang masuk',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Card
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
                    // Plat Nomor
                    TextFormField(
                      controller: _platController,
                      decoration: InputDecoration(
                        labelText: 'Plat Nomor',
                        hintText: 'Contoh: B 1234 XYZ',
                        prefixIcon: Icon(Icons.credit_card, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                    
                    // Jenis Kendaraan
                    DropdownButtonFormField<int>(
                      value: _selectedKendaraanId,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kendaraan',
                        prefixIcon: Icon(Icons.two_wheeler, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _jenisKendaraanList.map((jenis) {
                        return DropdownMenuItem<int>(
                          value: jenis.idKendaraan,
                          child: Text(jenis.jenisKendaraan),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKendaraanId = value;
                        });
                        if (value != null) {
                          _loadTarif(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih jenis kendaraan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tarif Display
                    if (_selectedTarif != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade50, Colors.green.shade100],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.attach_money, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tarif Parkir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currencyFormatter.format(_selectedTarif!.tarifPerJam)} / jam',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_selectedTarif != null) const SizedBox(height: 16),
                    
                    // Warna
                    TextFormField(
                      controller: _warnaController,
                      decoration: InputDecoration(
                        labelText: 'Warna (opsional)',
                        hintText: 'Contoh: Hitam',
                        prefixIcon: Icon(Icons.palette, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pemilik
                    TextFormField(
                      controller: _pemilikController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pemilik (opsional)',
                        hintText: 'Contoh: Budi Santoso',
                        prefixIcon: Icon(Icons.person, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Area Parkir
                    DropdownButtonFormField<int>(
                      value: _selectedAreaId,
                      decoration: InputDecoration(
                        labelText: 'Area Parkir (opsional)',
                        prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _areas.map((area) {
                        final available = area.kapasitas - area.terisi;
                        return DropdownMenuItem<int>(
                          value: area.idArea,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(area.namaArea),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: available > 0 ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$available tersedia',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: available > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedAreaId = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitParkirMasuk,
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
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'SIMPAN PARKIR MASUK',
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _platController.dispose();
    _warnaController.dispose();
    _pemilikController.dispose();
    super.dispose();
  }
}
