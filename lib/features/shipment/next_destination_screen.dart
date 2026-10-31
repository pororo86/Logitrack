import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../validation/validation_screen.dart';
import 'completed_screen.dart';

class NextDestinationScreen extends StatelessWidget {
  const NextDestinationScreen({super.key});

  int get _remaining => MockData.destinations.length - FlowState.destIndex;
  bool get _hasNext => _remaining > 0;

  void _goNext(BuildContext context) {
    FlowState.toWarehouse = false;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ValidationScreen(kind: ValidationKind.departure),
      ),
    );
  }

  Future<void> _goWarehouse(BuildContext context) async {
    if (_hasNext) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kembali ke warehouse?'),
          content: Text(
            'Masih ada $_remaining tujuan yang belum dikerjakan. '
            'Jika kembali ke warehouse, tujuan tersebut dilewati dan '
            'dilaporkan ke admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, ke warehouse'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    FlowState.skipped = _remaining;
    FlowState.toWarehouse = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ValidationScreen(kind: ValidationKind.departure),
      ),
    );
  }

  Future<void> _finishWithoutWarehouse(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan pengiriman?'),
        content: const Text(
          'Pengiriman akan ditutup tanpa kembali ke warehouse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CompletedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final current = FlowState.destIndex;
    final next = _hasNext ? MockData.destinations[current] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tujuan Berikutnya')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (int i = 0; i < MockData.destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _row(i, current),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pilih langkah selanjutnya',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasNext
                        ? 'Lanjut ke ${next!.name} atau kembali ke warehouse. '
                              'Kedua pilihan memerlukan validasi foto + GPS.'
                        : 'Semua tujuan selesai. Kembali ke warehouse atau '
                              'selesaikan pengiriman.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  if (_hasNext) ...[
                    PrimaryButton(
                      label: 'Lanjut ke ${next!.name}',
                      onPressed: () => _goNext(context),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Kembali ke Warehouse',
                      outlined: true,
                      onPressed: () => _goWarehouse(context),
                    ),
                  ] else ...[
                    PrimaryButton(
                      label: 'Kembali ke Warehouse',
                      onPressed: () => _goWarehouse(context),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _finishWithoutWarehouse(context),
                      child: const Text('Selesaikan tanpa ke warehouse'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(int i, int current) {
    final d = MockData.destinations[i];
    final done = i < current;
    final isNow = i == current;

    final Color circleColor = done
        ? AppColors.success
        : (isNow ? AppColors.primary : AppColors.bg);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
            ),
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isNow ? Colors.white : AppColors.muted,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  d.city,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (done)
                const StatusChip(
                  label: 'Selesai',
                  color: AppColors.success,
                  background: AppColors.softGreen,
                )
              else if (isNow)
                const StatusChip(
                  label: 'Berikutnya',
                  color: AppColors.primary,
                  background: AppColors.softBlue,
                )
              else
                const StatusChip(
                  label: 'Menunggu',
                  color: AppColors.muted,
                  background: AppColors.bg,
                ),
              if (done)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    formatTime(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
