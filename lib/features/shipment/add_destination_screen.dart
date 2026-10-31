import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import 'location_picker_screen.dart';

/// Form tambah tujuan. Mengembalikan Destination lewat Navigator.pop.
class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();

  PickedLocation? _location;
  double _radius = 150;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _location == null
              ? null
              : LatLng(_location!.lat, _location!.lng),
          radius: _radius.round(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _location = result;
      _error = null;
      if (_address.text.trim().isEmpty && result.label != null) {
        _address.text = result.label!;
      }
    });
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Nama perusahaan wajib diisi.');
      return;
    }
    if (_location == null) {
      setState(() => _error = 'Pilih titik lokasi tujuan di peta.');
      return;
    }
    final city = _city.text.trim().isEmpty ? '-' : _city.text.trim();
    final addr = _address.text.trim().isEmpty ? city : _address.text.trim();

    Navigator.of(context).pop(
      Destination(
        name: _name.text.trim(),
        city: city,
        address: addr,
        lat: _location!.lat,
        lng: _location!.lng,
        radius: _radius.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Tujuan')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Nama Perusahaan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'PT ABC Indonesia',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kota',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Jakarta Selatan',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _address,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Jl. TB Simatupang No. 12',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Titik Lokasi Tujuan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickOnMap,
                    borderRadius: BorderRadius.circular(16),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _location == null
                                  ? AppColors.softBlue
                                  : AppColors.softGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _location == null
                                  ? Icons.map_outlined
                                  : Icons.check_circle,
                              color: _location == null
                                  ? AppColors.primary
                                  : AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _location == null
                                      ? 'Pilih di peta'
                                      : 'Titik sudah dipilih',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _location == null
                                      ? 'Ketuk untuk membuka peta'
                                      : '${_location!.lat.toStringAsFixed(6)}, '
                                            '${_location!.lng.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Radius Validasi GPS',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_radius.round()} m',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: '${_radius.round()} m',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  const Text(
                    'Driver harus berada dalam radius ini saat validasi tiba. '
                    'Server menghitung ulang jaraknya.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(label: 'Simpan Tujuan', onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}
