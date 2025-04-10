import 'package:flutter/foundation.dart';

/// Logging configuration to control verbosity of different components
class LoggingConfig {
  /// Controls storage service logging detail
  static bool verboseStorageLogging = false;

  /// Controls thumbnail operations logging
  static bool verboseThumbnailLogging = false;

  /// Controls region state change logging
  static bool verboseRegionStateLogging = false;

  /// Controls database query logging
  static bool verboseDatabaseLogging = false;

  /// Enables detailed performance tracking for file operations
  static bool fileOperationPerformanceLogging = false;

  /// Master switch to enable/disable all debug prints
  static bool enableDebugPrints =
      kDebugMode && false; // Set to true only when needed

  /// Print only if debug printing is enabled
  static void debugPrint(String message) {
    if (enableDebugPrints) {
      print(message);
    }
  }
}
