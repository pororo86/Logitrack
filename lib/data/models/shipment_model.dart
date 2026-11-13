class DestinationModel {
  const DestinationModel({
    required this.id,
    required this.sequence,
    this.companyId,
    required this.name,
    this.city,
    this.address,
    required this.lat,
    required this.lng,
    this.radius = 150,
    this.status = 'pending',
  });

  final int id;
  final int sequence;
  final int? companyId;
  final String name;
  final String? city;
  final String? address;
  final double lat;
  final double lng;
  final int radius;
  final String status;

  factory DestinationModel.fromJson(Map<String, dynamic> j) {
    final st = j['status'];
    return DestinationModel(
      id: (j['id'] as num).toInt(),
      sequence: (j['sequence'] as num?)?.toInt() ?? 0,
      companyId: (j['company_id'] as num?)?.toInt(),
      name: (j['company_name'] ?? '') as String,
      city: j['city'] as String?,
      address: j['address'] as String?,
      lat: (j['latitude'] as num).toDouble(),
      lng: (j['longitude'] as num).toDouble(),
      radius: (j['validation_radius'] as num?)?.toInt() ?? 150,
      status: st is Map
          ? (st['value'] ?? 'pending') as String
          : (st ?? 'pending') as String,
    );
  }
}

class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.number,
    required this.status,
    this.statusLabel = '',
    this.displayStatus = '',
    this.uiStep = 1,
    this.nextAction,
    this.isLate = false,
    this.companyName,
    this.cargoType,
    this.packageCount,
    this.totalWeightKg,
    this.etaAt,
    this.createdAt,
    this.startTime,
    this.completedAt,
    this.destinationCount = 0,
    this.progressPercent = 0,
    this.warehouse,
    this.destinations = const [],
  });

  final int id;
  final String number;
  final String status;
  final String statusLabel;

  /// Selesai / Berjalan / Terlambat / Gagal / Menunggu
  final String displayStatus;

  /// Langkah 1..4 untuk StepIndicator.
  final int uiStep;

  /// Tahap berikutnya menurut server: ready_to_ship, loaded, start, arrived,
  /// unloaded, choose_next, warehouse.
  final String? nextAction;
  final bool isLate;
  final String? companyName;
  final String? cargoType;
  final int? packageCount;
  final double? totalWeightKg;
  final DateTime? etaAt;
  final DateTime? createdAt;
  final DateTime? startTime;
  final DateTime? completedAt;
  final int destinationCount;
  final int progressPercent;
  final CompanyModel? warehouse;
  final List<DestinationModel> destinations;

  /// Waktu dalam WIB (UTC+7), siap ditampilkan.
  DateTime? get etaWib => _toWib(etaAt);
  DateTime? get createdWib => _toWib(createdAt);
  DateTime? get startWib => _toWib(startTime);
  DateTime? get completedWib => _toWib(completedAt);

  static DateTime? _toWib(DateTime? t) =>
      t?.toUtc().add(const Duration(hours: 7));

  static DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;

  /// Warehouse tanpa koordinat dianggap tidak ada (tidak bisa dipakai untuk geofence).
  static CompanyModel? _company(Object? raw) {
    if (raw is! Map) return null;
    if (raw['latitude'] is! num || raw['longitude'] is! num) return null;
    return CompanyModel.fromJson(Map<String, dynamic>.from(raw));
  }

  factory ShipmentModel.fromJson(Map<String, dynamic> j) {
    final st = j['status'];
    final progress = j['progress'];
    final dests = (j['destinations'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => DestinationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ShipmentModel(
      id: (j['id'] as num).toInt(),
      number: (j['shipment_number'] ?? '') as String,
      status: st is Map ? (st['value'] ?? '') as String : (st ?? '') as String,
      statusLabel: st is Map ? (st['label'] ?? '') as String : '',
      displayStatus: (j['display_status'] ?? '') as String,
      uiStep: (j['ui_step'] as num?)?.toInt() ?? 1,
      nextAction: j['next_action'] as String?,
      isLate: j['is_late'] == true,
      companyName: j['company_name'] as String?,
      cargoType: j['cargo_type'] as String?,
      packageCount: (j['package_count'] as num?)?.toInt(),
      totalWeightKg: (j['total_weight_kg'] as num?)?.toDouble(),
      etaAt: _dt(j['eta_at']),
      createdAt: _dt(j['created_at']),
      startTime: _dt(j['start_time']),
      completedAt: _dt(j['completed_at']),
      destinationCount:
          (j['destination_count'] as num?)?.toInt() ?? dests.length,
      progressPercent: progress is Map
          ? (progress['percent'] as num?)?.toInt() ?? 0
          : 0,
      warehouse: _company(j['warehouse']),
      destinations: dests,
    );
  }
}

/// Hasil satu validasi: keputusan server dan pengiriman terbaru.
class ValidationResult {
  const ValidationResult({
    required this.shipment,
    required this.gpsValid,
    this.distance,
    this.radius,
    this.statusAfter,
  });

  final ShipmentModel shipment;
  final bool gpsValid;
  final double? distance;
  final int? radius;
  final String? statusAfter;

  factory ValidationResult.fromJson(Map<String, dynamic> data) {
    final v = data['validation'] is Map
        ? Map<String, dynamic>.from(data['validation'] as Map)
        : <String, dynamic>{};
    final s = data['shipment'];

    return ValidationResult(
      shipment: ShipmentModel.fromJson(Map<String, dynamic>.from(s as Map)),
      gpsValid: v['gps_valid'] == true,
      distance: (v['distance_from_destination'] as num?)?.toDouble(),
      radius: (v['validation_radius'] as num?)?.toInt(),
      statusAfter: v['status_after'] as String?,
    );
  }
}

class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    this.city,
    this.address,
    required this.lat,
    required this.lng,
    this.radius = 150,
  });

  final int id;
  final String name;
  final String? city;
  final String? address;
  final double lat;
  final double lng;
  final int radius;

  factory CompanyModel.fromJson(Map<String, dynamic> j) => CompanyModel(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '') as String,
    city: j['city'] as String?,
    address: j['address'] as String?,
    lat: (j['latitude'] as num).toDouble(),
    lng: (j['longitude'] as num).toDouble(),
    radius: (j['validation_radius'] as num?)?.toInt() ?? 150,
  );
}
