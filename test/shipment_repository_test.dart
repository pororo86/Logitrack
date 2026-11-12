import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcmrlogistic/core/network/api_client.dart';
import 'package:gcmrlogistic/core/network/api_exception.dart';
import 'package:gcmrlogistic/core/storage/token_storage.dart';
import 'package:gcmrlogistic/data/repositories/shipment_repository.dart';

class _Reply {
  const _Reply(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Reply Function(RequestOptions options) handler;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final reply = handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _shipment({
  int id = 7,
  String number = 'INV-20261110-0001',
}) => {
  'id': id,
  'shipment_number': number,
  'status': {'value': 'draft', 'label': 'Menunggu Mobile'},
  'display_status': 'Menunggu',
  'company_name': null,
  'cargo_type': 'Elektronik',
  'package_count': 24,
  'total_weight_kg': 560.0,
  'eta_at': '2026-11-10T08:30:00+00:00',
  'destination_count': 2,
  'destinations': [
    {
      'id': 1,
      'sequence': 1,
      'company_id': 5,
      'company_name': 'PT Anggana Catur Prima',
      'address': 'Jl. Pluit Raya',
      'city': 'Jakarta Utara',
      'latitude': -6.126617,
      'longitude': 106.798412,
      'validation_radius': 200,
      'status': {'value': 'pending', 'label': 'Menunggu'},
    },
    {
      'id': 2,
      'sequence': 2,
      'company_id': null,
      'company_name': 'Titik Peta',
      'address': null,
      'city': null,
      'latitude': -6.13,
      'longitude': 106.78,
      'validation_radius': 100,
      'status': {'value': 'pending', 'label': 'Menunggu'},
    },
  ],
};

_Reply _ok(Map<String, dynamic> data) =>
    _Reply(200, {'success': true, 'message': 'ok', 'data': data});

ShipmentRepository _repo(_FakeAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://test/api',
      headers: {'Accept': 'application/json'},
    ),
  )..httpClientAdapter = adapter;

  return ShipmentRepository(ApiClient(storage: MemoryTokenStorage(), dio: dio));
}

void main() {
  test('available membaca daftar, tujuan, dan penanda has_active', () async {
    final adapter = _FakeAdapter(
      (_) => _ok({
        'items': [_shipment()],
        'has_active': true,
      }),
    );

    final result = await _repo(adapter).available();

    expect(adapter.calls.single.path, '/shipments/available');
    expect(result.hasActive, isTrue);
    expect(result.items, hasLength(1));

    final s = result.items.single;
    expect(s.number, 'INV-20261110-0001');
    expect(s.status, 'draft');
    expect(s.destinations, hasLength(2));
    expect(s.destinations.first.name, 'PT Anggana Catur Prima');
    expect(s.destinations.first.companyId, 5);
    expect(s.destinations.first.radius, 200);
    expect(s.destinations.last.companyId, isNull);
    // 08:30 UTC menjadi 15:30 WIB
    expect(s.etaWib?.hour, 15);
  });

  test('claim mengirim nomor dan kendaraan', () async {
    final adapter = _FakeAdapter((_) => _ok(_shipment()));

    await _repo(adapter).claim(number: 'INV-20261110-0001', vehicleId: 3);

    final call = adapter.calls.single;
    expect(call.method, 'POST');
    expect(call.path, '/shipments/claim');
    expect(call.data, {
      'shipment_number': 'INV-20261110-0001',
      'vehicle_id': 3,
    });
  });

  test('payload tujuan: dari daftar hanya company_id, titik peta lengkap', () {
    expect(ShipmentRepository.companyDestination(5), {'company_id': 5});

    final manual = ShipmentRepository.manualDestination(
      name: 'Titik Peta',
      address: '-',
      city: 'Bekasi',
      lat: -6.2,
      lng: 106.8,
      radius: 100,
    );
    expect(manual, {
      'company_name': 'Titik Peta',
      'city': 'Bekasi',
      'latitude': -6.2,
      'longitude': 106.8,
      'validation_radius': 100,
    });
  });

  test(
    'claim ke pengiriman yang sudah diambil (409) memberi pesan server',
    () async {
      final adapter = _FakeAdapter(
        (_) => const _Reply(409, {
          'success': false,
          'message': 'Pengiriman ini sudah ditugaskan ke driver lain.',
          'errors': {},
        }),
      );

      await expectLater(
        _repo(adapter).claim(number: 'INV-20261110-0001'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 409)
              .having(
                (e) => e.message,
                'message',
                'Pengiriman ini sudah ditugaskan ke driver lain.',
              ),
        ),
      );
    },
  );
}
