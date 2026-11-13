import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models/shipment_model.dart';
import '../validation/validation_screen.dart';
import 'in_transit_screen.dart';
import 'next_destination_screen.dart';
import 'process_screen.dart';

/// Membuka layar yang sesuai dengan tahap berikutnya menurut server (next_action).
Future<void> resumeShipment(BuildContext context, ShipmentModel s) async {
  FlowState.reset();
  FlowState.sync(s);

  final Widget screen = switch (s.nextAction) {
    'loaded' => const LoadingScreen(),
    'start' || 'arrived' || 'warehouse' => const InTransitScreen(),
    'unloaded' => const UnloadingScreen(),
    'choose_next' => const NextDestinationScreen(),
    _ => const ValidationScreen(kind: ValidationKind.ready),
  };

  await Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => screen));
}
