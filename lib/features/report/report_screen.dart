import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/report_model.dart';

const _bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Laporan Pengiriman (30 hari terakhir) dari server.
/// Grafik digambar manual, tanpa package tambahan.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportSummary? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AppServices.I.shipments.summary(days: 30);
      if (!mounted) return;
      setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            if (_data == null && _loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_data == null)
              _errorBlock()
            else
              ..._content(_data!),
          ],
        ),
      ),
    );
  }

  Widget _errorBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _error ?? 'Data laporan tidak tersedia.',
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(onPressed: _load, child: const Text('Coba lagi')),
      ],
    );
  }

  String _dayLabel(String iso, {required bool withMonth}) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return withMonth ? '${d.day} ${_bulanPendek[d.month - 1]}' : '${d.day}';
  }

  List<Widget> _axis(List<DailyCount> daily) {
    if (daily.length < 2) return const [];
    final last = daily.length - 1;
    final idx = <int>[0, last ~/ 4, last ~/ 2, (last * 3) ~/ 4, last];

    return [
      for (var i = 0; i < idx.length; i++)
        _Axis(_dayLabel(daily[idx[i]].date, withMonth: i == idx.length - 1)),
    ];
  }

  List<Widget> _content(ReportSummary r) {
    final ratio = r.total > 0 ? r.success / r.total : 0.0;
    final stats = r.daily.length >= 2
        ? r.daily.map((d) => d.count.toDouble()).toList()
        : <double>[0, 0];

    return [
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_month_outlined, color: AppColors.primary),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _MiniStat(
              Icons.inventory_2_outlined,
              AppColors.primary,
              AppColors.softBlue,
              '${r.total}',
              'Total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              Icons.check,
              AppColors.success,
              AppColors.softGreen,
              '${r.success}',
              'Berhasil',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              Icons.close,
              AppColors.danger,
              AppColors.softRed,
              '${r.failed}',
              'Gagal',
            ),
          ),
        ],
      ),
      if (r.inProgress > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${r.inProgress} pengiriman masih berjalan (belum dihitung)',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
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
              child: CustomPaint(painter: _LineChartPainter(stats)),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _axis(r.daily),
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
                    painter: _DonutPainter(ratio),
                    child: Center(
                      child: Text(
                        '${r.successRate}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Legend(
                          'Berhasil',
                          '${r.success} pengiriman',
                          'Berhasil',
                        ),
                      ),
                      Expanded(
                        child: _Legend(
                          'Gagal',
                          '${r.failed} pengiriman',
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
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Kendaraan Dipakai',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (r.vehicles.isEmpty)
              const Text(
                'Belum ada data.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              )
            else
              for (var i = 0; i < r.vehicles.length; i++) ...[
                if (i > 0) const Divider(height: 14),
                _VehicleRow(r.vehicles[i].plateNumber, r.vehicles[i].count),
              ],
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
              'Gagal Pengiriman',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${r.failed}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    r.failureReasons.isEmpty
                        ? 'Tidak ada pengiriman gagal'
                        : r.failureReasons
                              .map((f) => '${f.label} ${f.count}')
                              .join('  •  '),
                    style: const TextStyle(
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
    ];
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
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 9.5, color: AppColors.muted));
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

    final maxV = math.max(1.0, data.reduce(math.max)) * 1.1;
    // final maxV = data.reduce(math.max) * 1.1;
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
