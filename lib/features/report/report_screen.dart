import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';

/// Laporan Pengiriman (statistik bulanan). Grafik digambar manual
/// (tanpa package tambahan). Angka masih dummy -> ganti dari Laravel.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const _done = 128;
  static const _failed = 6;

  @override
  Widget build(BuildContext context) {
    const total = _done + _failed;
    final donePct = (_done / total * 100).toStringAsFixed(1).replaceAll('.', ',');
    final failPct = (_failed / total * 100).toStringAsFixed(1).replaceAll('.', ',');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: Text(
              'Laporan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      Text(
                        '1 Bulan Terakhir',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MiniStat(
                  Icons.check_circle,
                  AppColors.success,
                  '$_done',
                  'Selesai',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  Icons.cancel,
                  AppColors.danger,
                  '$_failed',
                  'Gagal',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  Icons.local_shipping,
                  AppColors.primary,
                  '$total',
                  'Total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Pengiriman (Per Hari)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _LineChartPainter(MockData.dailyStats),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AxisLabel('1 Sep'),
                    _AxisLabel('8 Sep'),
                    _AxisLabel('15 Sep'),
                    _AxisLabel('22 Sep'),
                    _AxisLabel('30 Sep'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Status (1 Bulan)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: _DonutPainter(_done / total),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _Legend(AppColors.success, 'Selesai', '$donePct%'),
                          const SizedBox(height: 10),
                          _Legend(AppColors.danger, 'Gagal', '$failPct%'),
                        ],
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
  final String value;
  final String label;

  const _MiniStat(this.icon, this.color, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 10, color: AppColors.muted),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;

  const _Legend(this.color, this.label, this.pct);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          pct,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
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
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x553478F6), Color(0x003478F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.data != data;
}

class _DonutPainter extends CustomPainter {
  final double doneRatio;
  _DonutPainter(this.doneRatio);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
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
    final sweep = 2 * math.pi * doneRatio;
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
  bool shouldRepaint(covariant _DonutPainter old) => old.doneRatio != doneRatio;
}
