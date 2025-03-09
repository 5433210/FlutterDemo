/// 作品风格
enum WorkStyle {
  regular('regular', '楷书'),
  running('running', '行书'),
  cursive('cursive', '草书'),
  clerical('clerical', '隶书'),
  seal('seal', '篆书'),
  other('other', '其他');

  final String value;
  final String label;

  const WorkStyle(this.value, this.label);

  String toJson() => value;

  // 用于freezed反序列化的静态方法
  static WorkStyle? deserializeNullable(dynamic value) =>
      value == null ? null : fromValue(value);

  static WorkStyle fromString(String value) {
    return WorkStyle.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => WorkStyle.other,
    );
  }

  static WorkStyle fromValue(dynamic v) {
    if (v is WorkStyle) return v;
    final value = v?.toString() ?? '';
    return fromString(value);
  }

  // 用于freezed序列化的静态方法
  static String? serializeNullable(WorkStyle? style) => style?.value;
}
