/// 警报级别
enum AlertLevel {
  info,
  warning,
  error,
  critical,
}

/// 警报记录
class AlertRecord {
  final DateTime timestamp;
  final String type;
  final String message;
  final AlertLevel level;
  final Map<String, dynamic>? details;

  AlertRecord({
    required this.timestamp,
    required this.type,
    required this.message,
    required this.level,
    this.details,
  });

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      message: json['message'] as String,
      level: AlertLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
      ),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'message': message,
        'level': level.toString(),
        'details': details,
      };
}
