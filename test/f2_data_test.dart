import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _shipmentJson({
  int id = 1,
  String number = 'INV-20261108-0001',
  String status = 'assigned',
  String next = 'ready_to_ship',
  int step = 1,
}) => {
  'id': id,
  'shipment_number': number,
  'status': {'value': status, 'label': 'Ditugaskan'},
  'ui_step': step,
  'next_action': next,
  'display_status': 'Berjalan',
  'is_late': false,
  'created_at': '2026-11-08T22:29:09+00:00',
  'eta_at': null,
  'destination_count': 2,
  'progress': {'done': 1, 'total': 2, 'percent': 50},
  'destinations': [
    {
      'id': 1,
      'sequence': 1,
      'company_name': 'PT Satu',
      'latitude': -6.12,
      'longitude': 106.79,
      'validation_radius': 150,
      'status': {'value': 'completed', 'label': 'Selesai'},
    },
    {
      'id': 2,
      'sequence': 2,
      'company_name': 'PT Dua',
      'latitude': -6.13,
      'longitude': 106.78,
      'validation_radius': 150,
      'status': {'value': 'pending', 'label': 'Menunggu'},
    },
  ],
};

Map<String, dynamic> _userJson(String name) => {
  'id': 3,
  'name': name,
  'email': 'budi@logitrack.test',
  'phone': '0812-3456-7890',
  'roles': ['driver'],
  'driver': {
    'id': 1,
    'driver_code': 'DRV-001',
    'company_name': 'PT Sumber Makmur',
    'status': 'available',
    'vehicle': null,
  },
};

void main() {
  test('active: tanpa pengiriman aktif mengembalikan null', () async {
    final s = buildServices(FakeAdapter((_) => ok({'shipment': null})));

    expect(await s.shipments.active(), isNull);
  });

  test('active: membaca tahap, langkah, dan tujuan', () async {
    final s = buildServices(
      FakeAdapter(
        (_) => ok({
          'shipment': _shipmentJson(
            next: 'arrived',
            step: 3,
            status: 'in_transit',
          ),
        }),
      ),
    );

    final shipment = await s.shipments.active();

    expect(shipment, isNotNull);
    expect(shipment!.number, 'INV-20261108-0001');
    expect(shipment.status, 'in_transit');
    expect(shipment.statusLabel, 'Ditugaskan');
    expect(shipment.uiStep, 3);
    expect(shipment.nextAction, 'arrived');
    expect(shipment.destinationCount, 2);
    expect(shipment.progressPercent, 50);
    expect(shipment.destinations.first.status, 'completed');
    // 22:29 UTC = 05:29 WIB keesokan harinya
    expect(shipment.createdWib?.day, 9);
    expect(shipment.createdWib?.hour, 5);
  });

  test('list: parameter query dan penomoran halaman', () async {
    final adapter = FakeAdapter(
      (_) => ok({
        'items': [
          _shipmentJson(id: 1),
          _shipmentJson(id: 2, number: 'INV-20261108-0002'),
        ],
        'meta': {
          'current_page': 2,
          'last_page': 3,
          'per_page': 15,
          'total': 40,
        },
      }),
    );
    final s = buildServices(adapter);

    final page = await s.shipments.list(
      displayStatus: 'Selesai',
      search: 'inv',
      page: 2,
    );

    final q = adapter.calls.single.queryParameters;
    expect(q['display_status'], 'Selesai');
    expect(q['search'], 'inv');
    expect(q['page'], 2);
    expect(page.items, hasLength(2));
    expect(page.total, 40);
    expect(page.hasMore, isTrue);

    await s.shipments.list(displayStatus: 'Semua');
    expect(
      adapter.calls.last.queryParameters.containsKey('display_status'),
      isFalse,
    );
  });

  test('summary: membaca ringkasan laporan', () async {
    final s = buildServices(
      FakeAdapter(
        (_) => ok({
          'period': {'from': '2026-10-11', 'to': '2026-11-09', 'days': 30},
          'total': 6,
          'success': 5,
          'failed': 1,
          'in_progress': 1,
          'success_rate': 83,
          'daily': [
            {'date': '2026-11-08', 'count': 2},
            {'date': '2026-11-09', 'count': 1},
          ],
          'vehicles': [
            {'plate_number': 'B 9213 UCJ', 'count': 7},
          ],
          'failures': {
            'total': 1,
            'reasons': [
              {
                'code': 'receiver_absent',
                'label': 'Penerima tidak ada',
                'count': 1,
              },
            ],
          },
        }),
      ),
    );

    final r = await s.shipments.summary();

    expect(r.total, 6);
    expect(r.successRate, 83);
    expect(r.inProgress, 1);
    expect(r.daily.last.count, 1);
    expect(r.vehicles.single.plateNumber, 'B 9213 UCJ');
    expect(r.failureReasons.single.label, 'Penerima tidak ada');
  });

  test('updateProfile: mengirim PUT dan memperbarui sesi', () async {
    final adapter = FakeAdapter((_) => ok(_userJson('Budi Santoso')));
    final s = buildServices(adapter);

    await s.session.updateProfile(
      name: 'Budi Santoso',
      phone: '0812-3456-7890',
      companyName: 'PT Sumber Makmur',
    );

    final call = adapter.calls.single;
    expect(call.method, 'PUT');
    expect(call.path, '/me');
    expect(call.data, {
      'name': 'Budi Santoso',
      'phone': '0812-3456-7890',
      'company_name': 'PT Sumber Makmur',
    });
    expect(s.session.user?.name, 'Budi Santoso');
    expect(s.session.user?.firstName, 'Budi');
    expect(s.session.user?.driver?.companyName, 'PT Sumber Makmur');
  });
}
