import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  static String _duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return hours > 0 ? '$hours jam $minutes menit' : '${d.inMinutes} menit';
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowState.shipment;
    final start = s?.startTime;
    final end = s?.completedAt;

    final number =
        s?.number ?? FlowState.shipmentNumber ?? MockData.shipmentNumber;
    final points = s?.destinationCount ?? MockData.destinations.length;
    final startText = s?.startWib == null ? '-' : formatDateTime(s!.startWib!);
    final endText = s?.completedWib == null
        ? '-'
        : formatDateTime(s!.completedWib!);
    final totalText = (start != null && end != null)
        ? _duration(end.difference(start))
        : '-';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 66),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pengiriman Selesai',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Semua titik pengiriman telah selesai\ndilakukan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 22),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$points Titik Pengiriman',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _line(Icons.schedule, 'Berangkat', startText),
                    const SizedBox(height: 10),
                    _line(Icons.check_circle_outline, 'Selesai', endText),
                    const SizedBox(height: 10),
                    _line(Icons.timer_outlined, 'Total Waktu', totalText),
                    if (FlowState.skipped > 0) ...[
                      const SizedBox(height: 10),
                      _line(
                        Icons.alt_route,
                        'Tujuan dilewati',
                        '${FlowState.skipped}',
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Kembali ke Beranda',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Lihat Detail',
                outlined: true,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Halaman detail menyusul')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ],
    );
  }
}
