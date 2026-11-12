import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcmrlogistic/core/auth/app_services.dart';
import 'package:gcmrlogistic/core/auth/session.dart';
import 'package:gcmrlogistic/core/network/api_exception.dart';
import 'package:gcmrlogistic/core/storage/token_storage.dart';

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

Map<String, dynamic> _userJson() => {
  'id': 3,
  'name': 'Budi Santoso',
  'email': 'budi@logitrack.test',
  'phone': '0812',
  'roles': ['driver'],
  'driver': {
    'id': 1,
    'driver_code': 'DRV-001',
    'company_name': 'PT Sumber Makmur',
    'status': 'available',
    'vehicle': {
      'id': 1,
      'vehicle_code': 'VH-001',
      'name': 'Mitsubishi Canter',
      'plate_number': 'B 9213 UCJ',
      'type': 'Truk Engkel',
      'capacity_label': '5 Ton',
      'available': true,
    },
  },
};

_Reply _ok(Map<String, dynamic> data) =>
    _Reply(200, {'success': true, 'message': 'ok', 'data': data});

_Reply _fail(int status, String message, [Map<String, dynamic>? errors]) =>
    _Reply(status, {
      'success': false,
      'message': message,
      'errors': errors ?? {},
    });

AppServices _build(_FakeAdapter adapter, {TokenStorage? storage}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://test/api',
      headers: {'Accept': 'application/json'},
    ),
  )..httpClientAdapter = adapter;

  return AppServices.create(storage: storage ?? MemoryTokenStorage(), dio: dio);
}

void main() {
  test('login menyimpan token dan mengembalikan data driver', () async {
    final adapter = _FakeAdapter(
      (_) =>
          _ok({'token': '1|abc', 'token_type': 'Bearer', 'user': _userJson()}),
    );
    final storage = MemoryTokenStorage();
    final s = _build(adapter, storage: storage);

    await s.session.login(email: 'budi@logitrack.test', password: 'password');

    expect(await storage.read(), '1|abc');
    expect(s.session.status, SessionStatus.signedIn);
    expect(s.session.user?.firstName, 'Budi');
    expect(s.session.user?.driver?.driverCode, 'DRV-001');
    expect(s.session.user?.driver?.vehicle?.plateNumber, 'B 9213 UCJ');
    expect(adapter.calls.single.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'password salah (422) memberi galat per kolom dan tidak menyimpan token',
    () async {
      final adapter = _FakeAdapter(
        (_) => _fail(422, 'Data yang dikirim tidak valid.', {
          'email': ['Email atau password salah.'],
        }),
      );
      final storage = MemoryTokenStorage();
      final s = _build(adapter, storage: storage);

      await expectLater(
        s.session.login(email: 'budi@logitrack.test', password: 'salah'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 422)
              .having(
                (e) => e.fieldError('email'),
                'email',
                'Email atau password salah.',
              ),
        ),
      );
      expect(await storage.read(), isNull);
      expect(s.session.user, isNull);
    },
  );

  test('pesan 403 dari server diteruskan apa adanya', () async {
    final adapter = _FakeAdapter(
      (_) => _fail(
        403,
        'Aplikasi ini khusus driver. Admin dan staff memakai panel web.',
      ),
    );
    final s = _build(adapter);

    await expectLater(
      s.session.login(email: 'admin@logitrack.test', password: 'password'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Aplikasi ini khusus driver. Admin dan staff memakai panel web.',
        ),
      ),
    );
  });

  test('kode alasan aturan bisnis (409) terbaca', () async {
    final adapter = _FakeAdapter(
      (_) => _fail(409, 'Tahap ini tidak dapat dilakukan.', {
        'reason': 'invalid_status',
        'current_status': 'assigned',
      }),
    );
    final s = _build(adapter);

    await expectLater(
      s.api.get('/shipments/1'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.reason, 'reason', 'invalid_status')
            .having((e) => e.details['current_status'], 'status', 'assigned'),
      ),
    );
  });

  test('restore tanpa token: keluar', () async {
    final s = _build(_FakeAdapter((_) => _ok(_userJson())));

    await s.session.restore();

    expect(s.session.status, SessionStatus.signedOut);
  });

  test('restore memakai token tersimpan', () async {
    final adapter = _FakeAdapter((_) => _ok(_userJson()));
    final storage = MemoryTokenStorage();
    await storage.write('tok');
    final s = _build(adapter, storage: storage);

    await s.session.restore();

    expect(s.session.status, SessionStatus.signedIn);
    expect(adapter.calls.single.headers['Authorization'], 'Bearer tok');
  });

  test(
    'restore dengan token ditolak (401): token dihapus dan ada pesan',
    () async {
      final adapter = _FakeAdapter((_) => _fail(401, 'Token tidak valid.'));
      final storage = MemoryTokenStorage();
      await storage.write('lama');
      final s = _build(adapter, storage: storage);

      await s.session.restore();

      expect(s.session.status, SessionStatus.signedOut);
      expect(await storage.read(), isNull);
      expect(s.session.notice, isNotNull);
    },
  );

  test('logout tetap menghapus token walau server gagal', () async {
    final adapter = _FakeAdapter(
      (o) =>
          o.path.endsWith('/logout') ? _fail(500, 'rusak') : _ok(_userJson()),
    );
    final storage = MemoryTokenStorage();
    await storage.write('tok');
    final s = _build(adapter, storage: storage);
    await s.session.restore();

    await s.session.logout();

    expect(await storage.read(), isNull);
    expect(s.session.status, SessionStatus.signedOut);
  });

  test('pesan ramah untuk timeout dan tanpa koneksi', () {
    final req = RequestOptions(path: '/x');

    final timeout = ApiException.fromDio(
      DioException(
        requestOptions: req,
        type: DioExceptionType.connectionTimeout,
      ),
    );
    final offline = ApiException.fromDio(
      DioException(requestOptions: req, type: DioExceptionType.connectionError),
    );

    expect(timeout.message, contains('terlalu lama'));
    expect(offline.message, contains('Tidak dapat terhubung'));
  });
}
