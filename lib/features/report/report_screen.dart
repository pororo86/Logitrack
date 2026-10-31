import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';

/// Laporan Pengiriman (statistik 1 bulan). Grafik digambar manual,
/// tanpa package tambahan. Angka masih dummy -> ganti dari Laravel.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const _success = 128;
  static const _failed = 6;
  static const _total = _success + _failed;

  @override
  Widget build(BuildContext context) {
    final pct = (_success / _total * 100).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        children: [
          const Text(
            'Laporan Pengiriman',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Statistik pengiriman dalam periode satu bulan',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                      Text(
                        '1 Bulan Terakhir',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MiniStat(
                  Icons.inventory_2_outlined,
                  AppColors.primary,
                  AppColors.softBlue,
                  '$_total',
                  'Total',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  Icons.check,
                  AppColors.success,
                  AppColors.softGreen,
                  '$_success',
                  'Berhasil',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  Icons.close,
                  AppColors.danger,
                  AppColors.softRed,
                  '$_failed',
                  'Gagal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Pengiriman (Per Hari)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const Text(
                  'Jumlah pengiriman selama 1 bulan',
                  style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _LineChartPainter(MockData.dailyStats),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Axis('1'),
                    _Axis('8'),
                    _Axis('15'),
                    _Axis('22'),
                    _Axis('30 Sep'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Status (1 Bulan)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CustomPaint(
                        painter: _DonutPainter(_success / _total),
                        child: Center(
                          child: Text(
                            '$pct%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    const Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Legend(
                              'Berhasil',
                              '$_success pengiriman',
                              'Berhasil',
                            ),
                          ),
                          Expanded(
                            child: _Legend(
                              'Gagal',
                              '$_failed pengiriman',
                              'Gagal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Kendaraan Dipakai',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 8),
                _VehicleRow('B 9123 UXR', 12),
                Divider(height: 14),
                _VehicleRow('B 8765 KLP', 8),
                Divider(height: 14),
                _VehicleRow('B 1234 QWE', 6),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gagal Pengiriman',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$_failed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Alamat tidak valid 3  •  Penerima tidak ada 2\n'
                        'Kendala operasional 1',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String value;
  final String label;

  const _MiniStat(this.icon, this.color, this.bg, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Axis extends StatelessWidget {
  final String text;
  const _Axis(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
  );
}

class _Legend extends StatelessWidget {
  final String title;
  final String sub;
  final String chip;
  const _Legend(this.title, this.sub, this.chip);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        StatusChip.of(chip),
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final String plate;
  final int count;
  const _VehicleRow(this.plate, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          plate,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        Text(
          '$count pengiriman',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxV = data.reduce(math.max) * 1.1;
    final dx = size.width / (data.length - 1);
    final pts = [
      for (int i = 0; i < data.length; i++)
        Offset(i * dx, size.height - (data[i] / maxV) * size.height),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3.2,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.data != data;
}

class _DonutPainter extends CustomPainter {
  final double ratio;
  _DonutPainter(this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final sweep = 2 * math.pi * ratio;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, p(AppColors.success));
    canvas.drawArc(
      rect,
      -math.pi / 2 + sweep,
      2 * math.pi - sweep,
      false,
      p(AppColors.danger),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.ratio != ratio;
}
