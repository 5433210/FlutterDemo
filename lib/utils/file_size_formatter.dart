import 'dart:math';

/// Utility class to format file sizes in human-readable format
class FileSizeFormatter {
  // Natural logarithm of 10
  static const double _LN10 = 2.302585092994046;

  /// Format bytes into a readable string with the appropriate unit
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();

    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Convert logarithm for calculations
  static double log(num x) => logBase(x, 10);

  /// Base-10 logarithm
  static double log10(num x) => x == 0 ? 0 : _log(x) / _LN10;

  /// Calculate logarithm with custom base
  static double logBase(num x, num base) => log10(x) / log10(base);

  // Natural logarithm implementation
  static double _log(num x) {
    if (x <= 0) {
      return double.nan;
    }

    // Use Dart's built-in natural logarithm function if available
    return x.toDouble().log();
  }
}

/// Extension on num to provide log() method
extension LogExtension on double {
  double log() {
    // This uses Dart's native log function
    return _nativeLog(this);
  }

  // Declaration of the native log function
  external double _nativeLog(double x);
}
