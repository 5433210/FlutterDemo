import 'package:collection/collection.dart';

enum WorkStyle {
  regular('楷书'),
  running('行书'),
  cursive('草书'),
  clerical('隶书'),
  seal('篆书');

  final String label;
  const WorkStyle(this.label);

  static WorkStyle? fromString(String? value) {
    if (value == null) return null;
    return WorkStyle.values.firstWhereOrNull(
      (style) => style.toString() == 'CalligraphyStyle.$value'
    );
  }
}