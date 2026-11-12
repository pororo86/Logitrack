class VehicleInfo {
  const VehicleInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.plateNumber,
    required this.type,
    this.capacityLabel,
    this.available = true,
  });

  final int id;
  final String code;
  final String name;
  final String plateNumber;
  final String type;
  final String? capacityLabel;
  final bool available;

  factory VehicleInfo.fromJson(Map<String, dynamic> j) => VehicleInfo(
    id: (j['id'] as num).toInt(),
    code: (j['vehicle_code'] ?? '') as String,
    name: (j['name'] ?? j['type'] ?? '') as String,
    plateNumber: (j['plate_number'] ?? '') as String,
    type: (j['type'] ?? '') as String,
    capacityLabel: j['capacity_label'] as String?,
    available: j['available'] as bool? ?? true,
  );
}

class DriverInfo {
  const DriverInfo({
    required this.id,
    required this.driverCode,
    this.companyName,
    this.status = 'offline',
    this.vehicle,
  });

  final int id;
  final String driverCode;
  final String? companyName;
  final String status;
  final VehicleInfo? vehicle;

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
    id: (j['id'] as num).toInt(),
    driverCode: (j['driver_code'] ?? '') as String,
    companyName: j['company_name'] as String?,
    status: (j['status'] ?? 'offline') as String,
    vehicle: j['vehicle'] is Map
        ? VehicleInfo.fromJson(Map<String, dynamic>.from(j['vehicle'] as Map))
        : null,
  );
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.roles = const [],
    this.driver,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  final DriverInfo? driver;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '') as String,
    email: (j['email'] ?? '') as String,
    phone: j['phone'] as String?,
    roles: (j['roles'] as List? ?? const []).map((e) => e.toString()).toList(),
    driver: j['driver'] is Map
        ? DriverInfo.fromJson(Map<String, dynamic>.from(j['driver'] as Map))
        : null,
  );

  /// "Budi Santoso" menjadi "Budi".
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
  }

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}
