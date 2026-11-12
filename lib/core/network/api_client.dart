import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

// ignore_for_file: prefer_initializing_formals
/// Pembungkus Dio. Menambahkan token Bearer, dan menangani 401 (sesi habis).
class ApiClient {
  ApiClient({required TokenStorage storage, Dio? dio, this.onUnauthorized})
    : _storage = storage,
      dio = dio ?? _buildDio() {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['auth'] != false) {
            final token = await _storage.read();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final unauthorized =
              error.response?.statusCode == 401 &&
              error.requestOptions.extra['auth'] != false;
          if (unauthorized) {
            await _storage.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    // Log hanya saat development, tanpa header dan isi (tidak membocorkan token/password).
    if (kDebugMode && dio == null) {
      this.dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          requestBody: false,
          responseBody: false,
          error: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }
  }

  final Dio dio;
  final TokenStorage _storage;
  final VoidCallback? onUnauthorized;

  static Dio _buildDio() => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    bool auth = true,
  }) => _send('POST', path, data: data, auth: auth);

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    bool auth = true,
  }) => _send('PUT', path, data: data, auth: auth);

  /// Mengembalikan isi "data" dari format {success, message, data}.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required bool auth,
  }) async {
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method, extra: {'auth': auth}),
      );

      final body = response.data;
      if (body is Map && body['success'] == true) {
        final payload = body['data'];
        return payload is Map
            ? Map<String, dynamic>.from(payload)
            : <String, dynamic>{};
      }
      throw const ApiException('Respons server tidak dikenali.');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
