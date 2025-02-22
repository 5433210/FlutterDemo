enum WorkStyle {
  seal('篆书', 'seal'),
  official('隶书', 'official'),
  regular('楷书', 'regular'),
  running('行书', 'running'),
  cursive('草书', 'cursive');

  final String label;
  final String value;

  const WorkStyle(this.label, this.value);

  static WorkStyle? fromValue(String? value) {
    if (value == null) return null;
    return WorkStyle.values.firstWhere(
      (style) => style.value == value,
      orElse: () => WorkStyle.regular,
    );
  }
}