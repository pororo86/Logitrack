import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcmrlogistic/core/network/api_exception.dart';
import 'package:gcmrlogistic/data/mock_data.dart';
import 'package:gcmrlogistic/data/models/shipment_model.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _shipmentJson({
  String status = 'arrived',
  String next = 'unloaded',
  List<String> destStatus = const ['pending', 'pending'],
  Map<String, dynamic>? warehouse,
}) => {
  'id': 7,
  'shipment_number': 'INV-20261110-0001',
  'status': {'value': status, 'label': 'Label'},
  'ui_step': 3,
  'next_action': next,
  'display_status': 'Berjalan',
  'is_late': false,
  'created_at': '2026-11-10T01:00:00+00:00',
  'start_time': '2026-11-10T02:00:00+00:00',
  'completed_at': null,
  'eta_at': null,
  'destination_count': destStatus.length,
  'progress': {'done': 0, 'total': destStatus.length, 'percent': 0},
  'warehouse': warehouse,
  'destinations': [
    for (var i = 0; i < destStatus.length; i++)
      {
        'id': i + 1,
        'sequence': i + 1,
        'company_id': null,
        'company_name': 'PT ${i + 1}',
        'address': 'Jl. ${i + 1}',
        'city': 'Jakarta Utara',
        'latitude': -6.12 - i * 0.01,
        'longitude': 106.79,
        'validation_radius': 200,
        'status': {'value': destStatus[i], 'label': 'Label'},
      },
  ],
};

Map<String, dynamic> _validationResponse() => {
  'validation': {
    'id': 5,
    'validation_type': 'arrived',
    'gps_valid': true,
    'distance_from_destination': 12.3,
    'validation_radius': 200,
    'status_after': 'arrived',
  },
  'shipment': _shipmentJson(),
};

void main() {
  test(
    'submitValidation mengirim multipart foto + GPS dan membaca hasilnya',
    () async {
      final adapter = FakeAdapter((_) => ok(_validationResponse()));
      final s = buildServices(adapter);

      final photo = File('${Directory.systemTemp.path}/f3_photo_test.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final result = await s.shipments.submitValidation(
        shipmentId: 7,
        type: 'arrived',
        latitude: -6.126617,
        longitude: 106.798412,
        accuracy: 8.5,
        capturedAt: DateTime.utc(2026, 11, 10, 3, 15, 30),
        photoPath: photo.path,
      );

      final call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/shipments/7/validations');
      expect(call.data, isA<FormData>());

      final form = call.data as FormData;
      final fields = Map.fromEntries(form.fields);
      expect(fields['validation_type'], 'arrived');
      expect(fields['latitude'], '-6.126617');
      expect(fields['accuracy'], '8.5');
      expect(fields['captured_at'], '2026-11-10T03:15:30.000Z');
      expect(fields.containsKey('next_step'), isFalse);
      expect(
        fields.containsKey('gps_valid'),
        isFalse,
      ); // keputusan GPS tidak pernah dikirim dari aplikasi
      expect(form.files.single.key, 'photo');
      expect(form.files.single.value.filename, 'photo.jpg');
      expect(call.sendTimeout, const Duration(seconds: 90));

      expect(result.gpsValid, isTrue);
      expect(result.distance, 12.3);
      expect(result.radius, 200);
      expect(result.statusAfter, 'arrived');
      expect(result.shipment.number, 'INV-20261110-0001');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (await photo.exists()) {
        await photo.delete();
      }
    },
  );

  test('departure mengirim next_step', () async {
    final adapter = FakeAdapter((_) => ok(_validationResponse()));
    final s = buildServices(adapter);
    final photo = File('${Directory.systemTemp.path}/f3_photo_test2.jpg')
      ..writeAsBytesSync([1, 2, 3]);

    await s.shipments.submitValidation(
      shipmentId: 7,
      type: 'departure',
      latitude: -6.1,
      longitude: 106.8,
      accuracy: 5,
      capturedAt: DateTime.utc(2026, 11, 10),
      photoPath: photo.path,
      nextStep: 'warehouse',
    );

    final fields = Map.fromEntries(
      (adapter.calls.single.data as FormData).fields,
    );
    expect(fields['validation_type'], 'departure');
    expect(fields['next_step'], 'warehouse');

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (await photo.exists()) {
      await photo.delete();
    }
  });

  test('start dan complete memanggil endpoint yang benar', () async {
    final adapter = FakeAdapter(
      (_) => ok(_shipmentJson(status: 'in_transit', next: 'arrived')),
    );
    final s = buildServices(adapter);

    final started = await s.shipments.start(7);
    final done = await s.shipments.complete(7);

    expect(adapter.calls[0].method, 'POST');
    expect(adapter.calls[0].path, '/shipments/7/start');
    expect(adapter.calls[1].path, '/shipments/7/complete');
    expect(started.status, 'in_transit');
    expect(done.number, 'INV-20261110-0001');
  });

  test('penolakan GPS (422) membawa kode alasan dan angka jarak', () async {
    final adapter = FakeAdapter(
      (_) => const Reply(422, {
        'success': false,
        'message': 'Anda berjarak 380 m dari PT 1 (radius 200 m). Dekati lokasi lalu ambil ulang.',
        'errors': {
          'reason': 'gps_out_of_radius',
          'distance': 380.5,
          'radius': 200,
          'target': 'PT 1',
        },
      }),
    );
    final s = buildServices(adapter);
    final photo = File('${Directory.systemTemp.path}/f3_photo_test3.jpg')
      ..writeAsBytesSync([1, 2, 3]);

    await expectLater(
      s.shipments.submitValidation(
        shipmentId: 7,
        type: 'arrived',
        latitude: -6.2,
        longitude: 106.8,
        accuracy: 8,
        capturedAt: DateTime.utc(2026, 11, 10),
        photoPath: photo.path,
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 422)
            .having((e) => e.reason, 'reason', 'gps_out_of_radius')
            .having((e) => e.details['distance'], 'distance', 380.5)
            .having((e) => e.message, 'message', contains('380 m')),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (await photo.exists()) {
      await photo.delete();
    }
  });

  test(
    'FlowState.sync menyelaraskan tujuan, warehouse, dan status dari server',
    () {
      final shipment = ShipmentModel.fromJson(
        _shipmentJson(
          status: 'warehouse',
          next: 'warehouse',
          destStatus: const ['completed', 'skipped', 'skipped'],
          warehouse: {
            'id': 9,
            'name': 'Warehouse Pusat',
            'type': 'warehouse',
            'address': 'Jababeka',
            'city': 'Cikarang',
            'latitude': -6.307,
            'longitude': 107.172,
            'validation_radius': 200,
          },
        ),
      );

      FlowState.reset();
      FlowState.sync(shipment);

      expect(FlowState.shipmentId, 7);
      expect(FlowState.shipmentNumber, 'INV-20261110-0001');
      expect(MockData.destinations, hasLength(3));
      expect(MockData.destinations.first.name, 'PT 1');
      expect(FlowState.toWarehouse, isTrue);
      expect(FlowState.destIndex, 3); // selesai + dilewati
      expect(FlowState.skipped, 2);
      expect(FlowState.warehouse?.name, 'Warehouse Pusat');
      expect(FlowState.warehouse?.radius, 200);

      FlowState.reset();
    },
  );
}
