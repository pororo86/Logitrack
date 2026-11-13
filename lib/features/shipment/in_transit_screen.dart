import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../validation/validation_screen.dart';

class InTransitScreen extends StatefulWidget {
  const InTransitScreen({super.key});

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen> {
  bool _starting = false;
  String? _error;

  /// Dari status "loaded", perjalanan harus dimulai dulu di server.
  bool get _needsStart => FlowState.shipment?.status == 'loaded';

  @override
  void initState() {
    super.initState();
    if (_needsStart) _start();
  }

  Future<void> _start() async {
    final id = FlowState.shipmentId;
    if (id == null) return;

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final shipment = await AppServices.I.shipments.start(id);
      FlowState.sync(shipment);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _arrive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ValidationScreen(
          kind: FlowState.toWarehouse
              ? ValidationKind.warehouse
              : ValidationKind.arrived,
        ),
      ),
    );
  }

  void _showDetail(Destination d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(d.address, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            Text(
              'Koordinat: ${d.lat.toStringAsFixed(6)}, ${d.lng.toStringAsFixed(6)}',
            ),
            Text('Radius validasi: ${d.radius} m'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String get _etaText {
    final eta = FlowState.shipment?.etaWib;
    return eta == null ? 'Belum diatur' : formatTime(eta);
  }

  @override
  Widget build(BuildContext context) {
    final dest = FlowState.toWarehouse
        ? (FlowState.warehouse ?? MockData.warehouse)
        : MockData.destinations[FlowState.destIndex.clamp(
            0,
            MockData.destinations.length - 1,
          )];
    final canArrive = !_starting && !_needsStart;

    return Scaffold(
      appBar: AppBar(title: const Text('Dalam Perjalanan')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const StepIndicator(active: 3),
                  const SizedBox(height: 16),
                  if (_starting) ...[
                    _banner(
                      'Memulai perjalanan...',
                      const Color(0xFFE8F0FE),
                      AppColors.primary,
                      spinner: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_error != null) ...[
                    _banner(_error!, const Color(0xFFFDECEC), AppColors.danger),
                    TextButton(
                      onPressed: _start,
                      child: const Text('Coba lagi'),
                    ),
                    const SizedBox(height: 4),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tujuan Berikutnya',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dest.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    dest.city,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _showDetail(dest),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.softBlue,
                                foregroundColor: AppColors.primary,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Lihat Detail'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      const MapPlaceholder(height: 290, showRoute: true),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimasi tiba',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                _etaText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 13,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Tracking GPS aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: FlowState.toWarehouse
                    ? 'Tiba di Warehouse'
                    : 'Tiba di Lokasi',
                onPressed: canArrive ? _arrive : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(
    String text,
    Color background,
    Color foreground, {
    bool spinner = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (spinner)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.error_outline, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
