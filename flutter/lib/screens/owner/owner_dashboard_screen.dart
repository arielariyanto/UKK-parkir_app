import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../services/transaksi_service.dart';
import '../../services/laporan_service.dart';
import '../../models/transaksi_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/owner_sidebar.dart';
import 'owner_pendapatan_detail_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Transaksi> _transaksiHariIni = [];
  bool _isLoading = true;

  // Summary stats hari ini
  int _totalMasuk = 0;
  int _totalKeluar = 0;
  int _sedangParkir = 0;
  int _totalPendapatan = 0;

  // Data pendapatan dari API dashboard
  int _pendapatanHarian = 0;
  int _pendapatanBulanan = 0;
  int _pendapatanTahunan = 0;

  // Data grafik
  List<Map<String, dynamic>> _grafik7Hari = [];
  List<Map<String, dynamic>> _grafik12Bulan = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      // Load data secara paralel untuk performa lebih cepat
      final transaksiResult = TransaksiService.getAllTransaksi();
      final dashboardResult = LaporanService.getDashboard();

      final data = await transaksiResult;
      final dashboardData = await dashboardResult;

      final now = DateTime.now();
      final today = data.where((t) {
        if (t.waktuMasuk == null) return false;
        final d = t.waktuMasuk!.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      // Parse data dashboard dari API
      final apiData = dashboardData['data'] as Map<String, dynamic>? ?? {};
      final hariIni = apiData['hari_ini'] as Map<String, dynamic>? ?? {};
      final bulanIni = apiData['bulan_ini'] as Map<String, dynamic>? ?? {};
      final tahunIni = apiData['tahun_ini'] as Map<String, dynamic>? ?? {};
      final grafik = apiData['grafik'] as Map<String, dynamic>? ?? {};

      // Debug: lihat nilai mentah dari API
      debugPrint('=== DASHBOARD API DATA ===');
      debugPrint('hariIni: $hariIni');
      debugPrint('bulanIni: $bulanIni');
      debugPrint('tahunIni: $tahunIni');

      setState(() {
        _transaksiHariIni = today;
        _totalMasuk = today.length;
        _totalKeluar = today.where((t) => t.status == 'keluar').length;
        _sedangParkir = today.where((t) => t.status == 'masuk').length;
        _totalPendapatan = today
            .where((t) => t.biayaTotal != null)
            .fold(0, (sum, t) => sum + t.biayaTotal!);

        // Gunakan _toInt() agar bisa handle int, double, maupun String dari MySQL
        _pendapatanHarian = _toInt(hariIni['pendapatan']);
        _pendapatanBulanan = _toInt(bulanIni['pendapatan']);
        _pendapatanTahunan = _toInt(tahunIni['pendapatan']);

        // Data grafik
        _grafik7Hari = List<Map<String, dynamic>>.from(
            grafik['tujuh_hari'] as List? ?? []);
        _grafik12Bulan = List<Map<String, dynamic>>.from(
            grafik['dua_belas_bulan'] as List? ?? []);

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  /// Membuka bottom sheet detail pendapatan + grafik
  void _showPendapatanDetail(PeriodePendapatan periode) {
    int total;
    List<Map<String, dynamic>> grafikData;

    switch (periode) {
      case PeriodePendapatan.harian:
        total = _pendapatanHarian;
        grafikData = _grafik7Hari;
        break;
      case PeriodePendapatan.bulanan:
        total = _pendapatanBulanan;
        grafikData = _grafik12Bulan;
        break;
      case PeriodePendapatan.tahunan:
        total = _pendapatanTahunan;
        grafikData = [];
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: OwnerPendapatanDetailSheet(
            periode: periode,
            totalPendapatan: total,
            grafikData: grafikData,
          ),
        ),
      ),
    );
  }

  /// Konversi nilai dari JSON/MySQL ke int secara aman.
  /// MySQL SUM() bisa mengembalikan double (misal 15000.0) atau String.
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Owner',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const OwnerSidebar(currentRoute: '/owner/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade700,
                            Colors.purple.shade500
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade200,
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
                            child: const Icon(Icons.bar_chart,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang, Owner!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pantau performa parkir hari ini',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Statistik Hari Ini ──────────────────────────
                    const Text(
                      'Statistik Hari Ini',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio:
                              constraints.maxWidth > 600 ? 2.0 : 1.4,
                          children: [
                            _buildStatCard('Kendaraan Masuk', '$_totalMasuk',
                                Icons.login, Colors.blue.shade600),
                            _buildStatCard('Kendaraan Keluar', '$_totalKeluar',
                                Icons.logout, Colors.green.shade600),
                            _buildStatCard('Sedang Parkir', '$_sedangParkir',
                                Icons.local_parking, Colors.orange.shade600),
                            // _buildStatCard(
                            //     'Pendapatan',
                            //     Helpers.formatRupiah(_totalPendapatan),
                            //     Icons.attach_money,
                            //     Colors.purple.shade600,
                            //     smallText: true),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Ringkasan Pendapatan ────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Ringkasan Pendapatan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.purple.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app,
                                  size: 12, color: Colors.purple.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Klik untuk detail',
                                style: TextStyle(
                                    color: Colors.purple.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3 kartu pendapatan yang bisa diklik
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                  child: _buildPendapatanCard(
                                      'Hari Ini',
                                      _pendapatanHarian,
                                      Icons.today,
                                      Colors.teal.shade600,
                                      PeriodePendapatan.harian)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildPendapatanCard(
                                      'Bulan Ini',
                                      _pendapatanBulanan,
                                      Icons.calendar_month,
                                      Colors.indigo.shade600,
                                      PeriodePendapatan.bulanan)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildPendapatanCard(
                                      'Tahun Ini',
                                      _pendapatanTahunan,
                                      Icons.calendar_today,
                                      Colors.purple.shade700,
                                      PeriodePendapatan.tahunan)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildPendapatanCard(
                                  'Hari Ini',
                                  _pendapatanHarian,
                                  Icons.today,
                                  Colors.teal.shade600,
                                  PeriodePendapatan.harian),
                              const SizedBox(height: 12),
                              _buildPendapatanCard(
                                  'Bulan Ini',
                                  _pendapatanBulanan,
                                  Icons.calendar_month,
                                  Colors.indigo.shade600,
                                  PeriodePendapatan.bulanan),
                              const SizedBox(height: 12),
                              _buildPendapatanCard(
                                  'Tahun Ini',
                                  _pendapatanTahunan,
                                  Icons.calendar_today,
                                  Colors.purple.shade700,
                                  PeriodePendapatan.tahunan),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Transaksi Terbaru ───────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Transaksi Terbaru Hari Ini',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_transaksiHariIni.length} data',
                            style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _transaksiHariIni.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inbox,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('Belum ada transaksi hari ini',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transaksiHariIni.take(10).length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: Colors.grey.shade100, height: 1),
                              itemBuilder: (context, index) {
                                final t = _transaksiHariIni[index];
                                final isKeluar = t.status == 'keluar';
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isKeluar
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isKeluar
                                          ? Icons.check_circle
                                          : Icons.access_time,
                                      color: isKeluar
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    t.platNomor ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${t.jenisKendaraan ?? '-'} • ${Helpers.formatDateTime(t.waktuMasuk)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                  trailing: t.biayaTotal != null
                                      ? Text(
                                          Helpers.formatRupiah(t.biayaTotal!),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text('Masuk',
                                              style: TextStyle(
                                                  color:
                                                      Colors.orange.shade700,
                                                  fontSize: 12)),
                                        ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Kartu statistik hari ini (tidak bisa diklik)
  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool smallText = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: smallText ? 13 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu ringkasan pendapatan (bisa diklik → buka grafik)
  Widget _buildPendapatanCard(String label, int nilai, IconData icon,
      Color color, PeriodePendapatan periode) {
    return GestureDetector(
      onTap: () => _showPendapatanDetail(periode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatRupiah(nilai),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
