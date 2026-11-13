class DailyCount {
  const DailyCount(this.date, this.count);

  final String date; // yyyy-MM-dd (WIB)
  final int count;
}

class VehicleUsage {
  const VehicleUsage(this.plateNumber, this.count);

  final String plateNumber;
  final int count;
}

class FailureReason {
  const FailureReason(this.code, this.label, this.count);

  final String code;
  final String label;
  final int count;
}

class ReportSummary {
  const ReportSummary({
    required this.total,
    required this.success,
    required this.failed,
    required this.inProgress,
    required this.successRate,
    required this.from,
    required this.to,
    required this.daily,
    required this.vehicles,
    required this.failureReasons,
  });

  final int total; // berhasil + gagal
  final int success;
  final int failed;
  final int inProgress;
  final int successRate;
  final String from;
  final String to;
  final List<DailyCount> daily;
  final List<VehicleUsage> vehicles;
  final List<FailureReason> failureReasons;

  factory ReportSummary.fromJson(Map<String, dynamic> j) {
    final period = j['period'] is Map ? j['period'] as Map : const {};
    final failures = j['failures'] is Map ? j['failures'] as Map : const {};

    int n(Object? v) => (v as num?)?.toInt() ?? 0;

    return ReportSummary(
      total: n(j['total']),
      success: n(j['success']),
      failed: n(j['failed']),
      inProgress: n(j['in_progress']),
      successRate: n(j['success_rate']),
      from: (period['from'] ?? '') as String,
      to: (period['to'] ?? '') as String,
      daily: (j['daily'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DailyCount((e['date'] ?? '') as String, n(e['count'])))
          .toList(),
      vehicles: (j['vehicles'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => VehicleUsage(
              (e['plate_number'] ?? '') as String,
              n(e['count']),
            ),
          )
          .toList(),
      failureReasons: (failures['reasons'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => FailureReason(
              (e['code'] ?? '') as String,
              (e['label'] ?? '') as String,
              n(e['count']),
            ),
          )
          .toList(),
    );
  }
}
