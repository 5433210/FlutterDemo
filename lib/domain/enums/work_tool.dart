/// 创作工具
enum WorkTool {
  brush('brush', '毛笔'),
  hardPen('hardPen', '硬笔'),
  other('other', '其他');

  final String value;
  final String label;

  const WorkTool(this.value, this.label);

  String toJson() => value;

  static WorkTool? fromJson(dynamic value) =>
      value == null ? null : fromValue(value);

  static WorkTool fromString(String value) {
    return WorkTool.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => WorkTool.other,
    );
  }

  static WorkTool fromValue(dynamic v) {
    if (v is WorkTool) return v;
    final value = v?.toString() ?? '';
    return fromString(value);
  }

  // 用于JSON序列化的静态方法
  static String? serializeNullable(WorkTool? tool) => tool?.value;
}
