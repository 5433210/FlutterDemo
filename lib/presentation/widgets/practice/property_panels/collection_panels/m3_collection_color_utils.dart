import 'package:flutter/material.dart';

import '../../../../widgets/common/m3_color_picker.dart';

/// Shows a Material 3 color picker dialog with localization support
Future<void> showColorPickerDialog(
  BuildContext context,
  String initialColor,
  Function(Color) onColorSelected,
) async {
  final color = CollectionColorUtils.hexToColor(initialColor);

  final selectedColor = await M3ColorPicker.show(
    context,
    initialColor: color,
    enableAlpha: true,
    enableColorCode: true,
  );

  if (selectedColor != null) {
    onColorSelected(selectedColor);
  }
}

/// Collection panel color and drawing utility class with Material 3 support
class CollectionColorUtils {
  /// Converts a Color to hexadecimal string
  static String colorToHex(Color color) {
    // Handle transparent color
    if (color == Colors.transparent) {
      return 'transparent';
    }

    // Handle common colors
    if (color == Colors.black) return '#000000';
    if (color == Colors.white) return '#ffffff';
    if (color == Colors.red) return '#ff0000';
    if (color == Colors.green) return '#00ff00';
    if (color == Colors.blue) return '#0000ff';
    if (color == Colors.yellow) return '#ffff00';
    if (color == Colors.cyan) return '#00ffff';
    if (color == Colors.purple.shade200) {
      return '#ff00ff'; // Approximation of magenta
    }
    if (color == Colors.orange) return '#ffa500';
    if (color == Colors.purple) return '#800080';
    if (color == Colors.pink) return '#ffc0cb';
    if (color == Colors.brown) return '#a52a2a';
    if (color == Colors.grey) return '#808080';

    try {
      // Get the RGB values of the color
      final int r = color.red;
      final int g = color.green;
      final int b = color.blue;

      // Convert to hex, ensuring each component has 2 digits
      final String hexR = r.toRadixString(16).padLeft(2, '0');
      final String hexG = g.toRadixString(16).padLeft(2, '0');
      final String hexB = b.toRadixString(16).padLeft(2, '0');

      // Combine into a full hex string
      return '#$hexR$hexG$hexB';
    } catch (e) {
      return '#000000'; // Return black as default in case of error
    }
  }

  /// Get subscript character for a number
  static String getSubscript(int number) {
    const Map<String, String> subscripts = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };

    final String numberStr = number.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      result.write(subscripts[numberStr[i]] ?? numberStr[i]);
    }

    return result.toString();
  }

  /// Convert hex color string to Color object
  static Color hexToColor(String hexString) {
    // Handle transparent color
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    // Handle common color names
    switch (hexString.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'cyan':
        return Colors.cyan;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
    }

    // Handle specific hex color values
    switch (hexString.toLowerCase()) {
      case '#000000':
        return Colors.black;
      case '#ffffff':
        return Colors.white;
      case '#ff0000':
        return Colors.red;
      case '#00ff00':
        return Colors.green;
      case '#0000ff':
        return Colors.blue;
      case '#ffff00':
        return Colors.yellow;
      case '#00ffff':
        return Colors.cyan;
      case '#ff00ff':
        return Colors.purple.shade200; // Approximation of magenta
      case '#ffa500':
        return Colors.orange;
      case '#800080':
        return Colors.purple;
      case '#ffc0cb':
        return Colors.pink;
      case '#a52a2a':
        return Colors.brown;
      case '#808080':
        return Colors.grey;
    }

    try {
      // Remove leading # if present
      String cleanHex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;

      // Process hex string based on its length
      if (cleanHex.length == 6) {
        // RRGGBB format - add alpha channel
        cleanHex = 'ff$cleanHex';
      } else if (cleanHex.length == 8) {
        // AARRGGBB format - already includes alpha
      } else if (cleanHex.length == 3) {
        // RGB format - expand to RRGGBB and add alpha
        cleanHex =
            'ff${cleanHex[0]}${cleanHex[0]}${cleanHex[1]}${cleanHex[1]}${cleanHex[2]}${cleanHex[2]}';
      } else {
        return Colors.black; // Invalid format
      }

      // Parse the hex string to a color value
      final int colorValue = int.parse(cleanHex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return Colors.black; // Return black in case of error
    }
  }
}
