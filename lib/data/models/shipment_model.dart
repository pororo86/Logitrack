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
    this.displayStatus = '',
    this.companyName,
    this.cargoType,
    this.packageCount,
    this.totalWeightKg,
    this.etaAt,
    this.destinations = const [],
  });

  final int id;
  final String number;
  final String status;
  final String displayStatus;
  final String? companyName;
  final String? cargoType;
  final int? packageCount;
  final double? totalWeightKg;
  final DateTime? etaAt;
  final List<DestinationModel> destinations;

  /// Estimasi tiba dalam WIB (UTC+7), siap ditampilkan.
  DateTime? get etaWib => etaAt?.toUtc().add(const Duration(hours: 7));

  factory ShipmentModel.fromJson(Map<String, dynamic> j) {
    final st = j['status'];
    return ShipmentModel(
      id: (j['id'] as num).toInt(),
      number: (j['shipment_number'] ?? '') as String,
      status: st is Map ? (st['value'] ?? '') as String : (st ?? '') as String,
      displayStatus: (j['display_status'] ?? '') as String,
      companyName: j['company_name'] as String?,
      cargoType: j['cargo_type'] as String?,
      packageCount: (j['package_count'] as num?)?.toInt(),
      totalWeightKg: (j['total_weight_kg'] as num?)?.toDouble(),
      etaAt: j['eta_at'] is String
          ? DateTime.tryParse(j['eta_at'] as String)
          : null,
      destinations: (j['destinations'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DestinationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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
