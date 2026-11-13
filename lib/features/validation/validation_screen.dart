import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../../services/location_service.dart';
import '../../services/photo_service.dart';
import '../shipment/completed_screen.dart';
import '../shipment/in_transit_screen.dart';
import '../shipment/next_destination_screen.dart';
import '../shipment/process_screen.dart';
import 'camera_screen.dart';

enum ValidationKind {
  ready, // siap kirim
  loaded, // selesai muat
  arrived, // tiba di tujuan
  unloaded, // selesai bongkar
  departure, // berangkat setelah bongkar (lanjut tujuan / ke warehouse)
  warehouse, // tiba di warehouse
}

class ValidationScreen extends StatefulWidget {
  final ValidationKind kind;
  const ValidationScreen({super.key, required this.kind});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  /// Penolakan server yang berarti foto dan GPS harus diambil ulang.
  static const _retakeReasons = {
    'gps_out_of_radius',
    'gps_accuracy_poor',
    'timestamp_too_old',
    'timestamp_future',
    'photo_invalid',
    'photo_required',
    'photo_too_large',
  };

  final _photoService = PhotoService();
  final _locationService = LocationService();

  PhotoResult? _photo;
  GpsFix? _fix;
  DateTime _capturedAt = DateTime.now().toUtc();
  bool _busy = false;
  bool _sending = false;
  String? _error;
  LocationException? _locError;

  // Tujuan yang sedang dikerjakan saat layar ini dibuka.
  late final int _destIdx = FlowState.destIndex;

  // ---------- Target & aturan (hanya informasi; server menghitung ulang) ----------

  Destination? get _target {
    switch (widget.kind) {
      case ValidationKind.arrived:
      case ValidationKind.unloaded:
        return _destIdx < MockData.destinations.length
            ? MockData.destinations[_destIdx]
            : null;
      case ValidationKind.warehouse:
        return FlowState.warehouse ?? MockData.warehouse;
      default:
        return null;
    }
  }

  bool get _needsGeofence => _target != null;
  int get _radius => _target?.radius ?? AppConfig.defaultRadius;

  double? get _distance => (_fix == null || _target == null)
      ? null
      : haversineMeters(
          _fix!.latitude,
          _fix!.longitude,
          _target!.lat,
          _target!.lng,
        );

  bool get _accuracyOk =>
      _fix != null && _fix!.accuracy <= AppConfig.gpsMaxAccuracy;

  bool get _inRadius =>
      !_needsGeofence || (_distance != null && _distance! <= _radius);

  bool get _gpsValid => _fix != null && _accuracyOk && _inRadius;

  bool get _canSubmit =>
      _photo != null &&
      _fix != null &&
      !_sending &&
      (_gpsValid || AppConfig.devBypassGeofence);

  String? get _invalidReason {
    if (_fix == null) return null;
    if (!_accuracyOk) {
      return 'Akurasi GPS buruk (±${_fix!.accuracy.round()} m, maksimal '
          '${AppConfig.gpsMaxAccuracy.round()} m). Pindah ke area terbuka lalu ambil ulang.';
    }
    if (!_inRadius) {
      return 'Anda berjarak ${_distance!.round()} m dari ${_target!.name} '
          '(radius $_radius m). Dekati lokasi lalu ambil ulang.';
    }
    return null;
  }

  // ---------- Teks per jenis ----------

  /// Nilai validation_type yang dikenal server.
  String get _typeName => switch (widget.kind) {
    ValidationKind.ready => 'ready_to_ship',
    ValidationKind.loaded => 'loaded',
    ValidationKind.arrived => 'arrived',
    ValidationKind.unloaded => 'unloaded',
    ValidationKind.departure => 'departure',
    ValidationKind.warehouse => 'warehouse',
  };

  String get _title => switch (widget.kind) {
    ValidationKind.ready => 'Validasi Siap Kirim',
    ValidationKind.loaded => 'Validasi Selesai Muat',
    ValidationKind.arrived => 'Validasi Tiba di Lokasi',
    ValidationKind.unloaded => 'Validasi Selesai Bongkar',
    ValidationKind.departure =>
      FlowState.toWarehouse
          ? 'Validasi Kembali ke Warehouse'
          : 'Validasi Lanjut Tujuan',
    ValidationKind.warehouse => 'Validasi Tiba di Warehouse',
  };

  int get _step => switch (widget.kind) {
    ValidationKind.ready => 1,
    ValidationKind.loaded => 2,
    ValidationKind.arrived => 3,
    ValidationKind.unloaded => 4,
    ValidationKind.departure => 4,
    ValidationKind.warehouse => 4,
  };

  String get _instruction => switch (widget.kind) {
    ValidationKind.ready => 'Ambil foto kondisi box/mobil\nsebelum berangkat',
    ValidationKind.loaded =>
      'Ambil foto kondisi barang\nsetelah selesai dimuat',
    ValidationKind.arrived => 'Ambil foto lokasi tujuan',
    ValidationKind.unloaded => 'Ambil foto setelah selesai bongkar',
    ValidationKind.departure =>
      FlowState.toWarehouse
          ? 'Ambil foto kondisi kendaraan\nsebelum kembali ke warehouse'
          : 'Ambil foto kondisi kendaraan\nsebelum ke tujuan berikutnya',
    ValidationKind.warehouse => 'Ambil foto kedatangan di warehouse',
  };

  bool get _showMap =>
      widget.kind == ValidationKind.arrived ||
      widget.kind == ValidationKind.warehouse;

  // ---------- Aksi ----------

  /// Foto + GPS diambil dalam SATU aksi, supaya jadi satu bukti.
  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
      _locError = null;
    });

    try {
      await _locationService.ensureReady();
      if (!mounted) return;

      final path = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CameraScreen(title: _title)),
      );
      if (path == null || !mounted) return;

      final photo = await _photoService.processFile(path);
      final fix = await _locationService.getCurrent();
      if (!mounted) return;

      setState(() {
        _photo = photo;
        _fix = fix;
        _capturedAt = DateTime.now()
            .toUtc(); // jam perangkat saat bukti diambil
      });
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _locError = e;
        });
      }
    } on PhotoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() => setState(() {
    _photo = null;
    _fix = null;
    _error = null;
    _locError = null;
  });

  Future<void> _submit() async {
    final fix = _fix;
    final photo = _photo;
    if (fix == null || photo == null) return;

    final shipmentId = FlowState.shipmentId;
    if (shipmentId == null) {
      setState(() {
        _error = 'Pengiriman tidak ditemukan. Kembali ke Beranda lalu pilih pengiriman.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final result = await AppServices.I.shipments.submitValidation(
        shipmentId: shipmentId,
        type: _typeName,
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracy: fix.accuracy,
        capturedAt: _capturedAt,
        photoPath: photo.file.path,
        nextStep: widget.kind == ValidationKind.departure
            ? (FlowState.toWarehouse ? 'warehouse' : 'next_destination')
            : null,
      );

      // Server adalah sumber kebenaran: tujuan, warehouse, dan status diselaraskan.
      FlowState.sync(result.shipment);
      FlowState.records.add(
        ValidationRecord(
          type: _typeName,
          photoPath: photo.file.path,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          distance: result.distance ?? _distance,
          gpsValid: result.gpsValid,
          capturedAt: _capturedAt,
        ),
      );

      if (!mounted) return;
      _goNext();
    } on ApiException catch (e) {
      await _handleRejection(e);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Terjadi kesalahan saat mengirim. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleRejection(ApiException e) async {
    if (!mounted) return;

    // Sesi habis ditangani global (kembali ke login).
    if (e.isUnauthorized) return;

    // Status berubah (dibatalkan admin, kirim ganda, dsb.): muat ulang dari Beranda.
    if (e.statusCode == 409) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Status pengiriman berubah'),
          content: Text('${e.message}\n\nBeranda akan memuat status terbaru.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final firstField = e.fieldErrors.values.expand((v) => v).firstOrNull;
    final message = firstField ?? e.message;

    // Ditolak karena isi buktinya: foto dan GPS harus diambil ulang.
    final mustRetake =
        _retakeReasons.contains(e.reason) || e.fieldErrors.containsKey('photo');

    setState(() {
      _error = message;
      if (mustRetake) {
        _photo = null;
        _fix = null;
      }
    });
    // Galat jaringan dan server (tanpa alasan di atas): foto dan GPS dipertahankan untuk dicoba lagi.
  }

  void _goNext() {
    final Widget next = switch (widget.kind) {
      ValidationKind.ready => const LoadingScreen(),
      ValidationKind.loaded => const InTransitScreen(),
      ValidationKind.arrived => const UnloadingScreen(),
      ValidationKind.unloaded => const NextDestinationScreen(),
      ValidationKind.departure => const InTransitScreen(),
      ValidationKind.warehouse => const CompletedScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final target = _target;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StepIndicator(active: _step),
                  const SizedBox(height: 16),
                  if (target != null) ...[
                    DestinationHeader(destination: target),
                    const SizedBox(height: 12),
                  ],
                  if (_showMap) ...[
                    _mapWithBanner(),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _instruction,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PhotoBox(
                    file: _photo?.file,
                    beforeBytes: _photo?.originalBytes,
                    afterBytes: _photo?.compressedBytes,
                    busy: _busy,
                    onCapture: _capture,
                    onRemove: _clear,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _errorBox(),
                  ],
                  if (_fix != null) ...[
                    const SizedBox(height: 12),
                    LocationInfoCard(
                      lat: _fix!.latitude,
                      lng: _fix!.longitude,
                      accuracy: _fix!.accuracy,
                      time: _fix!.timestamp.toLocal(),
                      valid: _gpsValid,
                    ),
                    const SizedBox(height: 8),
                    if (_distance != null)
                      Text(
                        'Jarak ke tujuan: ${_distance!.round()} m (radius $_radius m). '
                        'Keputusan akhir dihitung ulang oleh server.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    if (_invalidReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _invalidReason!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    if (!_gpsValid && AppConfig.devBypassGeofence) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'MODE DEV: tombol tetap aktif. Server tetap menolak bila di luar radius.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: 'Kirim Validasi',
                loading: _sending,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapWithBanner() {
    return Stack(
      children: [
        const MapPlaceholder(height: 130),
        if (_fix != null)
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _gpsValid
                    ? AppColors.softGreen
                    : const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _gpsValid ? Icons.check_circle : Icons.error_outline,
                    size: 16,
                    color: _gpsValid ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _gpsValid
                        ? 'Anda berada di lokasi tujuan'
                        : 'Anda belum berada di lokasi tujuan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _gpsValid ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_locError?.canOpenLocationSettings == true)
            TextButton(
              onPressed: _locationService.openLocationSettings,
              child: const Text('Buka pengaturan lokasi'),
            ),
          if (_locError?.canOpenAppSettings == true)
            TextButton(
              onPressed: _locationService.openAppSettings,
              child: const Text('Buka pengaturan aplikasi'),
            ),
        ],
      ),
    );
  }
}
