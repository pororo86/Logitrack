import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../validation/validation_screen.dart';

class ProcessScreen extends StatelessWidget {
  final String title;
  final int step;
  final Destination? destination;
  final IconData icon;
  final String heading;
  final String subtitle;
  final String buttonLabel;
  final bool showProgress;
  final VoidCallback onDone;

  const ProcessScreen({
    super.key,
    required this.title,
    required this.step,
    required this.icon,
    required this.heading,
    required this.subtitle,
    required this.buttonLabel,
    required this.onDone,
    this.destination,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StepIndicator(active: step),
                  const SizedBox(height: 16),
                  if (destination != null) ...[
                    DestinationHeader(destination: destination!),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8F0FE), Color(0xFFCFE0FB)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 84, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.inventory_2,
                          size: 70,
                          color: Color(0xFFC98A4B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 22),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 0.75),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, v, _) => Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              backgroundColor: AppColors.border,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(v * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(label: buttonLabel, onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar 5: Proses Muat Barang
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessScreen(
      title: 'Proses Muat Barang',
      step: 2,
      icon: Icons.local_shipping,
      heading: 'Proses memuat barang\nke kendaraan',
      subtitle: 'Pastikan seluruh barang sudah dimuat\ndengan aman.',
      buttonLabel: 'Selesai Muat',
      showProgress: true,
      onDone: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ValidationScreen(kind: ValidationKind.loaded),
        ),
      ),
    );
  }
}

/// Layar 9: Proses Bongkar Barang
class UnloadingScreen extends StatelessWidget {
  const UnloadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i = FlowState.destIndex;
    final dest = i < MockData.destinations.length
        ? MockData.destinations[i]
        : null;

    return ProcessScreen(
      title: 'Proses Bongkar Barang',
      step: 4,
      destination: dest,
      icon: Icons.local_shipping,
      heading: 'Proses bongkar barang',
      subtitle: 'Pastikan seluruh barang dibongkar\ndengan aman.',
      buttonLabel: 'Selesai Bongkar',
      onDone: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ValidationScreen(kind: ValidationKind.unloaded),
        ),
      ),
    );
  }
}
