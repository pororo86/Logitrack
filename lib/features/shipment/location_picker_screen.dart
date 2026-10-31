import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../services/location_service.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String? label;
  const PickedLocation(this.lat, this.lng, {this.label});
}

class _SearchResult {
  final String name;
  final LatLng point;
  const _SearchResult(this.name, this.point);
}

/// Layar pilih titik di peta. Mengembalikan PickedLocation lewat Navigator.pop.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final int radius; // meter, hanya untuk menggambar lingkaran geofence

  const LocationPickerScreen({super.key, this.initial, this.radius = 150});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallbackCenter = LatLng(-6.2088, 106.8456); // Jakarta

  final _map = MapController();
  final _locationService = LocationService();
  final _searchCtl = TextEditingController();

  LatLng? _picked;
  LatLng? _me;
  String? _label;
  bool _locating = false;
  bool _searching = false;
  String? _message;
  List<_SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _locateMe({bool move = true}) async {
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      final fix = await _locationService.getCurrent();
      final p = LatLng(fix.latitude, fix.longitude);
      if (!mounted) return;
      setState(() => _me = p);
      if (move) _map.move(p, 16);
    } on LocationException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (e) {
      if (mounted) setState(() => _message = 'Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _search() async {
    final q = _searchCtl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _message = null;
      _results = [];
    });
    try {
      // Nominatim (OpenStreetMap). Hanya untuk pencarian ringan saat development.
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'id',
      });
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'LogiTrack/1.0 (gcmrlogistic)',
              'Accept-Language': 'id',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final list = (jsonDecode(res.body) as List).map((e) {
        return _SearchResult(
          e['display_name'] as String,
          LatLng(double.parse(e['lat']), double.parse(e['lon'])),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = list;
        if (list.isEmpty)
          _message = 'Alamat tidak ditemukan. Coba kata kunci lain.';
      });
    } on TimeoutException {
      if (mounted) {
        setState(() => _message = 'Pencarian terlalu lama. Cek internet Anda.');
      }
    } catch (_) {
      if (mounted)
        setState(() => _message = 'Pencarian gagal. Cek internet Anda.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choose(_SearchResult r) {
    setState(() {
      _picked = r.point;
      _label = r.name;
      _results = [];
    });
    _map.move(r.point, 17);
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.initial ?? _fallbackCenter;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: start,
              initialZoom: widget.initial == null ? 12 : 16,
              onMapReady: () {
                if (widget.initial == null) _locateMe();
              },
              onTap: (_, point) => setState(() {
                _picked = point;
                _label = null;
                _results = [];
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gcmrlogistic',
              ),
              if (_picked != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _picked!,
                      radius: widget.radius.toDouble(),
                      useRadiusInMeter: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  if (_picked != null)
                    Marker(
                      point: _picked!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.danger,
                        size: 44,
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Bar atas: kembali + pencarian
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.text,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'Cari alamat / nama tempat',
                            suffixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _search,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (final r in _results)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(
                                r.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _choose(r),
                            ),
                        ],
                      ),
                    ),
                  if (_message != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Tombol lokasi saya
          Positioned(
            right: 16,
            bottom: 170,
            child: FloatingActionButton.small(
              heroTag: 'me',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : _locateMe,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Kartu bawah: koordinat + konfirmasi
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _picked == null
                          ? 'Ketuk peta untuk menaruh pin tujuan'
                          : '${_picked!.latitude.toStringAsFixed(6)}, '
                                '${_picked!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    if (_label != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _label!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 10),
                      child: Text(
                        'Lingkaran biru = radius validasi ${widget.radius} m',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: 'Gunakan Titik Ini',
                      onPressed: _picked == null
                          ? null
                          : () => Navigator.of(context).pop(
                              PickedLocation(
                                _picked!.latitude,
                                _picked!.longitude,
                                label: _label,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
