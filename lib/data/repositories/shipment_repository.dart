import '../../core/network/api_client.dart';
import '../models/shipment_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

import 'package:dio/dio.dart';

class AvailableShipments {
  const AvailableShipments({required this.items, required this.hasActive});

  final List<ShipmentModel> items;

  /// Driver ini masih punya pengiriman aktif (tidak boleh mengambil/membuat lagi).
  final bool hasActive;
}

class ShipmentPage {
  const ShipmentPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ShipmentModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
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

  /// Pengiriman aktif milik driver, atau null.
  Future<ShipmentModel?> active() async {
    final data = await _api.get('/shipments/active');
    final raw = data['shipment'];
    return raw is Map
        ? ShipmentModel.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }

  /// Riwayat. displayStatus: Selesai / Berjalan / Terlambat / Gagal (null atau "Semua" = semua).
  Future<ShipmentPage> list({
    String? displayStatus,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    final data = await _api.get(
      '/shipments',
      query: {
        'page': page,
        'per_page': perPage,
        if (displayStatus != null && displayStatus != 'Semua')
          'display_status': displayStatus,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final meta = data['meta'] is Map ? data['meta'] as Map : const {};
    return ShipmentPage(
      items: _list(data['items'], ShipmentModel.fromJson),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ReportSummary> summary({int days = 30}) async {
    final data = await _api.get('/reports/summary', query: {'days': days});
    return ReportSummary.fromJson(data);
  }

  Future<ShipmentModel> show(int id) async =>
      ShipmentModel.fromJson(await _api.get('/shipments/$id'));

  /// loaded -> in_transit. Aman dipanggil ulang saat sudah berjalan.
  Future<ShipmentModel> start(int id) async =>
      ShipmentModel.fromJson(await _api.post('/shipments/$id/start'));

  /// unloaded -> completed (selesai tanpa kembali ke warehouse).
  Future<ShipmentModel> complete(int id) async =>
      ShipmentModel.fromJson(await _api.post('/shipments/$id/complete'));

  /// Satu bukti = foto + GPS dalam satu permintaan. Server yang memutuskan
  /// valid atau tidaknya dan mengubah status.
  Future<ValidationResult> submitValidation({
    required int shipmentId,
    required String type,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime capturedAt,
    required String photoPath,
    String? nextStep,
  }) async {
    final form = FormData.fromMap({
      'validation_type': type,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy': accuracy.toString(),
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'next_step': ?nextStep,
      'photo': await MultipartFile.fromFile(photoPath, filename: 'photo.jpg'),
    });

    final data = await _api.post(
      '/shipments/$shipmentId/validations',
      data: form,
      timeout: const Duration(seconds: 90),
    );
    return ValidationResult.fromJson(data);
  }

  /// Mengambil pengiriman buatan admin lewat nomornya.
  Future<ShipmentModel> claim({required String number, int? vehicleId}) async {
    final data = await _api.post(
      '/shipments/claim',
      data: {'shipment_number': number, 'vehicle_id': ?vehicleId},
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
        'vehicle_id': ?vehicleId,
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
