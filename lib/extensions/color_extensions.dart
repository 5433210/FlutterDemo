import 'package:flutter/material.dart';

/// Extension methods for Color class
extension ColorExtensions on Color {
  /// Create a copy of the color with specific values changed
  Color withValues({int? red, int? green, int? blue, int? alpha}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}
