import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import 'set_shipment_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  Vehicle? _selected;

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan terlebih dahulu')),
      );
      return;
    }

    MockData.selectedVehicle = _selected;

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SetShipmentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Kendaraan')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Kendaraan Pengiriman',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih kendaraan yang akan digunakan '
                    'untuk proses pengiriman.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  for (final vehicle in MockData.vehicles)
                    _vehicleCard(vehicle),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Lanjut ke Set Pengiriman',
                onPressed: _selected == null ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard(Vehicle vehicle) {
    final selected = _selected?.id == vehicle.id;

    return Opacity(
      opacity: vehicle.available ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: vehicle.available
              ? () => setState(() => _selected = vehicle)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.plate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.type} • ${vehicle.capacity}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.available ? 'Tersedia' : 'Sedang digunakan',
                        style: TextStyle(
                          color: vehicle.available
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
