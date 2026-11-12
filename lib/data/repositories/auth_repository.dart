import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  static String get _device =>
      'flutter-${kIsWeb ? 'web' : defaultTargetPlatform.name}';

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/login',
      auth: false,
      data: {
        'email': email.trim(),
        'password': password,
        'device_name': _device,
      },
    );

    final token = data['token'];
    final user = data['user'];
    if (token is! String || token.isEmpty || user is! Map) {
      throw const ApiException('Respons login tidak lengkap.');
    }

    final model = UserModel.fromJson(Map<String, dynamic>.from(user));
    await _storage.write(token); // disimpan setelah respons terbukti utuh
    return model;
  }

  Future<UserModel> me() async => UserModel.fromJson(await _api.get('/me'));

  /// Token lokal selalu dihapus, walau server tidak terjangkau.
  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } on ApiException {
      // diabaikan: yang penting sesi lokal berakhir
    } finally {
      await _storage.clear();
    }
  }
}
