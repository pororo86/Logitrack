import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';

enum SessionStatus { restoring, signedOut, signedIn }

// ignore_for_file: prefer_initializing_formals
/// Status login aplikasi. Layar cukup mendengarkan objek ini.
class Session extends ChangeNotifier {
  Session({required AuthRepository repository, required TokenStorage storage})
    : _repository = repository,
      _storage = storage;

  final AuthRepository _repository;
  final TokenStorage _storage;

  SessionStatus _status = SessionStatus.restoring;
  UserModel? _user;
  String? _notice;

  SessionStatus get status => _status;
  UserModel? get user => _user;
  String? get notice => _notice;

  /// Pesan untuk layar login (mis. "Sesi berakhir"), diambil sekali.
  String? takeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  /// Dipanggil saat aplikasi dibuka: pulihkan sesi dari token tersimpan.
  Future<void> restore() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      _set(SessionStatus.signedOut);
      return;
    }

    try {
      _user = await _repository.me();
      _set(SessionStatus.signedIn);
    } on ApiException catch (e) {
      _user = null;
      if (e.isUnauthorized) {
        await _storage.clear();
        _notice ??= 'Sesi Anda berakhir. Silakan masuk kembali.';
      } else {
        // Server tidak terjangkau: token dipertahankan, pengguna bisa mencoba lagi.
        _notice = e.message;
      }
      _set(SessionStatus.signedOut);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _user = await _repository.login(email: email, password: password);
    _notice = null;
    _set(SessionStatus.signedIn);
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _notice = null;
    _set(SessionStatus.signedOut);
  }

  /// Menyimpan profil ke server. Layar yang mendengarkan Session ikut diperbarui.
  Future<void> updateProfile({
    required String name,
    String? phone,
    String? companyName,
  }) async {
    _user = await _repository.updateProfile(
      name: name,
      phone: phone,
      companyName: companyName,
    );
    notifyListeners();
  }

  /// Dipanggil ApiClient saat server menjawab 401 di tengah pemakaian.
  void handleUnauthorized() {
    if (_status == SessionStatus.signedOut) return;
    _user = null;
    _notice = 'Sesi Anda berakhir. Silakan masuk kembali.';
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus status) {
    _status = status;
    notifyListeners();
  }
}
