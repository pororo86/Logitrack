import 'dart:math';

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)} WIB';

String formatDateTime(DateTime d) => '${formatDate(d)} • ${formatTime(d)}';

/// Jarak dua titik GPS dalam meter (rumus Haversine).
/// Di aplikasi final, keputusan valid/tidak tetap dihitung ulang oleh Laravel.
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(a));
}

/// 3984000 -> "3.8 MB", 430000 -> "420 KB"
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).round()} KB';
}
