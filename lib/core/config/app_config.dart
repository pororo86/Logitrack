class AppConfig {
  /// Akurasi GPS terburuk yang diterima (meter). Backend akan menghitung ulang.
  static const double gpsMaxAccuracy = 100;

  /// Radius default bila tujuan tidak punya radius sendiri (meter).
  static const int defaultRadius = 150;

  /// MODE DEVELOPMENT: true = tombol Kirim tetap aktif walau GPS di luar
  /// radius / akurasi buruk (berguna di emulator). Ubah ke false untuk
  /// menguji aturan sebenarnya. Wajib false saat rilis.
  static const bool devBypassGeofence = true;

  /// Kompresi foto.
  static const int photoMaxSide = 1280;
  static const int photoQuality = 75;
}
