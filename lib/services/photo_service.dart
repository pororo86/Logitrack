import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../core/config/app_config.dart';

class PhotoException implements Exception {
  final String message;
  const PhotoException(this.message);

  @override
  String toString() => message;
}

class PhotoResult {
  final File file;
  final int originalBytes;
  final int compressedBytes;

  const PhotoResult({
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });
}

/// Kompres foto hasil kamera. Widget tidak mengurus kompresi.
class PhotoService {
  Future<PhotoResult> processFile(String sourcePath) async {
    final originalBytes = await File(sourcePath).length();
    final target =
        '${Directory.systemTemp.path}/lt_${DateTime.now().microsecondsSinceEpoch}.jpg';

    try {
      final out = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        target,
        minWidth: AppConfig.photoMaxSide,
        minHeight: AppConfig.photoMaxSide,
        quality: AppConfig.photoQuality,
        format: CompressFormat.jpeg,
      );
      if (out == null) {
        throw const PhotoException('Gagal mengompres foto. Coba ambil ulang.');
      }
      return PhotoResult(
        file: File(out.path),
        originalBytes: originalBytes,
        compressedBytes: await out.length(),
      );
    } on PhotoException {
      rethrow;
    } catch (_) {
      throw const PhotoException('Gagal mengompres foto. Coba ambil ulang.');
    }
  }
}
