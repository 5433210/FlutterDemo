import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  /// Gets a contrasting color (for text/borders against a background)
  static Color getContrastingColor(Color backgroundColor) {
    // Calculate luminance - if the background is light, return dark text color and vice versa
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black.withOpacity(0.8)
        : Colors.white.withOpacity(0.8);
  }

  /// Get the appropriate foreground color for a given background
  static Color getForegroundColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Inverts a color
  static Color invertColor(Color color) {
    return Color.fromARGB(
      color.alpha,
      255 - color.red,
      255 - color.green,
      255 - color.blue,
    );
  }

  /// Checks if a color is considered "light"
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
}
