import 'package:dio/dio.dart';

/// Semua galat jaringan dan server diubah menjadi ini, dengan pesan yang
/// bisa langsung ditampilkan ke driver.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
    this.reason,
    this.details = const {},
  });

  final String message;
  final int? statusCode;

  /// Galat per kolom (422), mis. {'email': ['Email atau password salah.']}.
  final Map<String, List<String>> fieldErrors;

  /// Kode alasan dari aturan bisnis server, mis. gps_out_of_radius.
  final String? reason;
  final Map<String, dynamic> details;

  bool get isUnauthorized => statusCode == 401;

  String? fieldError(String field) {
    final list = fieldErrors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  factory ApiException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        'Koneksi terlalu lama. Periksa internet Anda lalu coba lagi.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Tidak dapat terhubung ke server. Periksa internet dan alamat server.',
      );
    }
    if (e.type == DioExceptionType.cancel) {
      return const ApiException('Permintaan dibatalkan.');
    }
    if (e.type == DioExceptionType.badCertificate) {
      return const ApiException('Sertifikat keamanan server tidak valid.');
    }

    final response = e.response;
    if (response == null) {
      return const ApiException('Terjadi kesalahan jaringan. Coba lagi.');
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    String? message;
    final fields = <String, List<String>>{};
    String? reason;
    var details = <String, dynamic>{};

    if (data is Map) {
      message = data['message']?.toString();
      final errors = data['errors'];
      if (errors is Map) {
        if (errors['reason'] is String) {
          reason = errors['reason'] as String;
          details = Map<String, dynamic>.from(errors);
        } else {
          errors.forEach((key, value) {
            if (value is List) {
              fields[key.toString()] = value.map((x) => x.toString()).toList();
            }
          });
        }
      }
    }

    return ApiException(
      _messageFor(status, message),
      statusCode: status,
      fieldErrors: fields,
      reason: reason,
      details: details,
    );
  }

  static String _messageFor(int status, String? serverMessage) {
    if (status >= 500) {
      return 'Terjadi gangguan pada server. Coba lagi beberapa saat lagi.';
    }
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage;
    }
    switch (status) {
      case 401:
        return 'Sesi Anda berakhir. Silakan masuk kembali.';
      case 403:
        return 'Anda tidak memiliki akses untuk tindakan ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 422:
        return 'Data yang dikirim tidak valid.';
      case 429:
        return 'Terlalu banyak permintaan. Coba lagi sebentar lagi.';
      default:
        return 'Permintaan gagal (kode $status).';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
