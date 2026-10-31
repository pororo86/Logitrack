class Destination {
  final String name;
  final String city;
  final String address;
  final double lat;
  final double lng;
  final int radius;

  const Destination({
    required this.name,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    this.radius = 150,
  });
}

class RecentShipment {
  final String number;
  final int points;
  final String date;
  final String status;

  const RecentShipment(this.number, this.points, this.date, this.status);
}

/// Satu bukti validasi (foto + GPS). Nanti dikirim ke Laravel.
class ValidationRecord {
  final String type;
  final String photoPath;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? distance;
  final bool gpsValid;
  final DateTime capturedAt;

  const ValidationRecord({
    required this.type,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distance,
    required this.gpsValid,
    required this.capturedAt,
  });
}

class MockData {
  static const driverName = 'Budi';
  static const driverFullName = 'Budi Santoso';
  static const driverInitials = 'BS';
  static const driverId = 'DRV-0092';
  static const driverEmail = 'driver@perusahaan.com';
  static const driverPhone = '+62 812-3456-7890';
  static const driverCompany = 'PT Sumber Makmur';
  static const shipmentNumber = 'TRK-20261004-001';

  /// Koordinat dummy. Ganti dengan koordinat nyata saat pengujian di lapangan.
  static const warehouse = Destination(
    name: 'Warehouse Pusat',
    city: 'Cikarang',
    address: 'Kawasan Industri Jababeka, Cikarang',
    lat: -6.3070,
    lng: 107.1720,
    radius: 200,
  );

  static List<Destination> destinations = [
    const Destination(
      name: 'PT ABC Indonesia',
      city: 'Jakarta Selatan',
      address: 'Jl. TB Simatupang No. 12, Jakarta Selatan',
      lat: -6.2615,
      lng: 106.8106,
    ),
    const Destination(
      name: 'PT XYZ Logistic',
      city: 'Bekasi',
      address: 'Jl. Raya Narogong Km 8, Bekasi',
      lat: -6.2349,
      lng: 106.9896,
    ),
    const Destination(
      name: 'PT DEF Corp',
      city: 'Karawang',
      address: 'Kawasan KIIC Blok C-5, Karawang',
      lat: -6.3227,
      lng: 107.3376,
    ),
  ];

  /// Riwayat lengkap (layar Riwayat). Ganti dengan data Laravel nanti.
  static const history = [
    RecentShipment('TRK-20261031-001', 3, '31 Okt 2026', 'Selesai'),
    RecentShipment('TRK-20261029-003', 2, '29 Okt 2026', 'Selesai'),
    RecentShipment('TRK-20261028-008', 4, '28 Okt 2026', 'Berjalan'),
    RecentShipment('TRK-20261025-004', 1, '25 Okt 2026', 'Terlambat'),
    RecentShipment('TRK-20261022-006', 3, '22 Okt 2026', 'Selesai'),
  ];

  /// Statistik harian untuk grafik Laporan (dummy).
  static const dailyStats = <double>[3, 5, 2, 6, 4, 7, 5, 8, 6, 9, 7, 12];

  static const recent = [
    RecentShipment('TRK-20261029-003', 2, '29 Okt 2026', 'Selesai'),
    RecentShipment('TRK-20261028-008', 4, '28 Okt 2026', 'Berjalan'),
  ];
}

/// Status alur yang sedang berjalan (hanya untuk tahap UI).
/// Nanti digantikan data dari backend Laravel (sumber kebenaran).
class FlowState {
  static int destIndex = 0;
  static bool toWarehouse = false;
  static int skipped = 0;
  static DateTime startedAt = DateTime.now();
  static final List<ValidationRecord> records = [];

  static void reset() {
    destIndex = 0;
    toWarehouse = false;
    skipped = 0;
    startedAt = DateTime.now();
    records.clear();
  }
}
