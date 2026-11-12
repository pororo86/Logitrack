import 'package:flutter/foundation.dart';

/// Alamat backend.
/// HP fisik:  flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api'; // alamat laptop dari emulator Android
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);
}
