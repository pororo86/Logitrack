import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  final bool canOpenLocationSettings;
  final bool canOpenAppSettings;

  const LocationException(
    this.message, {
    this.canOpenLocationSettings = false,
    this.canOpenAppSettings = false,
  });

  @override
  String toString() => message;
}

/// Satu titik GPS lengkap.
class GpsFix {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}

/// Semua urusan GPS ada di sini, bukan di widget.
class LocationService {
  /// Cek GPS menyala dan izin diberikan. Melempar LocationException jika tidak.
  Future<void> ensureReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'GPS di perangkat mati. Aktifkan lokasi lalu coba lagi.',
        canOpenLocationSettings: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Izin lokasi ditolak. Izinkan lokasi agar validasi bisa dilakukan.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.',
        canOpenAppSettings: true,
      );
    }
  }

  /// Ambil posisi saat ini (akurasi tinggi, batas waktu 15 detik).
  Future<GpsFix> getCurrent() async {
    await ensureReady();
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GpsFix(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        speed: p.speed,
        heading: p.heading,
        timestamp: p.timestamp,
      );
    } on TimeoutException {
      throw const LocationException(
        'Sinyal GPS belum didapat. Pindah ke area terbuka lalu coba lagi.',
      );
    }
  }

  /// Dipakai nanti untuk live tracking (Phase 17).
  Stream<GpsFix> stream({int distanceFilterMeters = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map(
      (p) => GpsFix(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        speed: p.speed,
        heading: p.heading,
        timestamp: p.timestamp,
      ),
    );
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
