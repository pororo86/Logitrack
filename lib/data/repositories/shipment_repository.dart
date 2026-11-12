import '../../core/network/api_client.dart';
import '../models/shipment_model.dart';
import '../models/user_model.dart';

class AvailableShipments {
  const AvailableShipments({required this.items, required this.hasActive});

  final List<ShipmentModel> items;

  /// Driver ini masih punya pengiriman aktif (tidak boleh mengambil/membuat lagi).
  final bool hasActive;
}

class ShipmentRepository {
  ShipmentRepository(this._api);

  final ApiClient _api;

  Future<AvailableShipments> available({String? search}) async {
    final data = await _api.get(
      '/shipments/available',
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return AvailableShipments(
      items: _list(data['items'], ShipmentModel.fromJson),
      hasActive: data['has_active'] == true,
    );
  }

  Future<List<CompanyModel>> companies({String? search}) async {
    final data = await _api.get(
      '/companies',
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _list(data['items'], CompanyModel.fromJson);
  }

  Future<List<VehicleInfo>> vehicles() async {
    final data = await _api.get('/vehicles');
    return _list(data['items'], VehicleInfo.fromJson);
  }

  /// Mengambil pengiriman buatan admin lewat nomornya.
  Future<ShipmentModel> claim({required String number, int? vehicleId}) async {
    final data = await _api.post(
      '/shipments/claim',
      data: {
        'shipment_number': number,
        if (vehicleId != null) 'vehicle_id': vehicleId,
      },
    );
    return ShipmentModel.fromJson(data);
  }

  /// Membuat pengiriman baru (di luar daftar admin).
  Future<ShipmentModel> create({
    int? vehicleId,
    String? companyName,
    required List<Map<String, dynamic>> destinations,
  }) async {
    final data = await _api.post(
      '/shipments',
      data: {
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (companyName != null && companyName.isNotEmpty)
          'company_name': companyName,
        'destinations': destinations,
      },
    );
    return ShipmentModel.fromJson(data);
  }

  /// Tujuan dari daftar perusahaan Laravel: koordinat dan radius diambil server.
  static Map<String, dynamic> companyDestination(int companyId) => {
    'company_id': companyId,
  };

  /// Tujuan di luar daftar: titik yang dipilih di peta.
  static Map<String, dynamic> manualDestination({
    required String name,
    String? address,
    String? city,
    required double lat,
    required double lng,
    required int radius,
  }) => {
    'company_name': name,
    if (address != null && address.isNotEmpty && address != '-')
      'address': address,
    if (city != null && city.isNotEmpty && city != '-') 'city': city,
    'latitude': lat,
    'longitude': lng,
    'validation_radius': radius,
  };

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
  }
}
