import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/helpers.dart';

/// Enum untuk jenis periode pendapatan yang ditampilkan
enum PeriodePendapatan { harian, bulanan, tahunan }

/// Bottom sheet yang menampilkan detail pendapatan beserta grafik batang.
/// Dipanggil dari OwnerDashboardScreen saat kartu pendapatan diklik.
class OwnerPendapatanDetailSheet extends StatefulWidget {
  /// Jenis periode (harian, bulanan, tahunan)
  final PeriodePendapatan periode;

  /// Total pendapatan periode yang dipilih
  final int totalPendapatan;

  /// Data grafik: list map dari backend berisi {tanggal/bulan, total}
  final List<Map<String, dynamic>> grafikData;

  const OwnerPendapatanDetailSheet({
    super.key,
    required this.periode,
    required this.totalPendapatan,
    required this.grafikData,
  });

  @override
  State<OwnerPendapatanDetailSheet> createState() =>
      _OwnerPendapatanDetailSheetState();
}

class _OwnerPendapatanDetailSheetState
    extends State<OwnerPendapatanDetailSheet> {
  int _touchedIndex = -1;

  /// Konfigurasi warna & label berdasarkan periode
  Color get _periodeColor {
    switch (widget.periode) {
      case PeriodePendapatan.harian:
        return Colors.teal.shade600;
      case PeriodePendapatan.bulanan:
        return Colors.indigo.shade600;
      case PeriodePendapatan.tahunan:
        return Colors.purple.shade600;
    }
  }

  String get _periodeLabel {
    switch (widget.periode) {
      case PeriodePendapatan.harian:
        return 'Pendapatan Harian (7 Hari Terakhir)';
      case PeriodePendapatan.bulanan:
        return 'Pendapatan Bulanan (12 Bulan Terakhir)';
      case PeriodePendapatan.tahunan:
        return 'Pendapatan Tahunan';
    }
  }

  IconData get _periodeIcon {
    switch (widget.periode) {
      case PeriodePendapatan.harian:
        return Icons.today;
      case PeriodePendapatan.bulanan:
        return Icons.calendar_month;
      case PeriodePendapatan.tahunan:
        return Icons.calendar_today;
    }
  }

  /// Ambil label sumbu X dari map data
  String _getLabelX(Map<String, dynamic> item) {
    if (widget.periode == PeriodePendapatan.harian) {
      // Format: "2025-03-01" → "01/03"
      final str = item['tanggal']?.toString() ?? '';
      if (str.length >= 10) {
        return '${str.substring(8, 10)}/${str.substring(5, 7)}';
      }
      return str;
    } else {
      // Format: "Mar 2025" → "Mar"
      final label = item['label']?.toString() ?? '';
      return label.length >= 3 ? label.substring(0, 3) : label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.grafikData.isNotEmpty;

    // Nilai max untuk skala grafik
    final double maxY = hasData
        ? widget.grafikData
                .map((e) =>
                    (double.tryParse(e['total']?.toString() ?? '0') ?? 0))
                .reduce((a, b) => a > b ? a : b) *
            1.2
        : 10000;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _periodeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_periodeIcon, color: _periodeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _periodeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${Helpers.formatRupiah(widget.totalPendapatan)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _periodeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grafik Batang
          if (widget.periode != PeriodePendapatan.tahunan) ...[
            Text(
              'Grafik Pendapatan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada data grafik',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxY == 0 ? 10000 : maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: _periodeColor.withOpacity(0.9),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = widget.grafikData[groupIndex];
                          return BarTooltipItem(
                            '${_getLabelX(item)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: Helpers.formatRupiah(
                                    rod.toY.toInt()),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          if (response?.spot != null &&
                              event is FlTapUpEvent) {
                            _touchedIndex =
                                response!.spot!.touchedBarGroupIndex;
                          } else {
                            _touchedIndex = -1;
                          }
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= widget.grafikData.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _getLabelX(widget.grafikData[idx]),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return Text('0',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade500));
                            }
                            // Format ribuan singkat
                            String label;
                            if (value >= 1000000) {
                              label =
                                  '${(value / 1000000).toStringAsFixed(1)}jt';
                            } else if (value >= 1000) {
                              label = '${(value / 1000).toStringAsFixed(0)}rb';
                            } else {
                              label = value.toStringAsFixed(0);
                            }
                            return Text(
                              label,
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade500),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade100,
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: List.generate(widget.grafikData.length, (i) {
                      final item = widget.grafikData[i];
                      final nilai =
                          double.tryParse(item['total']?.toString() ?? '0') ??
                              0;
                      final isTouched = i == _touchedIndex;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: nilai,
                            color: isTouched
                                ? _periodeColor
                                : _periodeColor.withOpacity(0.7),
                            width: isTouched ? 18 : 14,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Tabel Ringkasan Data
          if (hasData && widget.periode != PeriodePendapatan.tahunan) ...[
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Text(
              'Rincian Data',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.grafikData.reversed.take(7).map((item) {
              final nilai =
                  double.tryParse(item['total']?.toString() ?? '0') ?? 0;
              final label = widget.periode == PeriodePendapatan.harian
                  ? (item['tanggal']?.toString() ?? '-')
                  : (item['label']?.toString() ?? '-');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _periodeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatRupiah(nilai.toInt()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _periodeColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Untuk tahunan: tampilkan hanya total besar
          if (widget.periode == PeriodePendapatan.tahunan) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.monetization_on,
                      size: 64, color: _periodeColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text(
                    'Total Pendapatan Tahun Ini',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatRupiah(widget.totalPendapatan),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _periodeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
