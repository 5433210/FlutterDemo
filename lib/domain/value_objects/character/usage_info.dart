class UsageInfo {
  final String practiceId;

  const UsageInfo({
    required this.practiceId,
  });

  Map<String, dynamic> toJson() => {
    'practiceId': practiceId,
  };

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
    practiceId: json['practiceId'] as String,
  );
}