import 'dart:async';
import 'dart:developer' as developer;

/// Collection edit page debugging helper
class CollectionDebugHelper {
  static const String _TAG = 'CollectionDebug';

  /// Debug state changes
  static void logStateChange(
      String component, String action, Map<String, dynamic> data) {
    final message = '[$component] $action';
    developer.log(
      message,
      name: _TAG,
      time: DateTime.now(),
      level: 800, // Info level
      zone: Zone.current,
      error: null,
      stackTrace: null,
    );

    // Also print to console for immediate visibility
    print('🔍 $message');
    if (data.isNotEmpty) {
      data.forEach((key, value) {
        print('   $key: $value');
      });
    }
  }

  /// Debug UI interactions
  static void logUIEvent(String event, [Map<String, dynamic>? data]) {
    logStateChange('UI', event, data ?? {});
  }

  /// Debug character operations
  static void logCharacterOp(String operation, [Map<String, dynamic>? data]) {
    logStateChange('Character', operation, data ?? {});
  }

  /// Debug text operations
  static void logTextOp(String operation, [Map<String, dynamic>? data]) {
    logStateChange('Text', operation, data ?? {});
  }

  /// Debug segment operations
  static void logSegmentOp(String operation, [Map<String, dynamic>? data]) {
    logStateChange('Segment', operation, data ?? {});
  }

  /// Debug render operations
  static void logRenderOp(String operation, [Map<String, dynamic>? data]) {
    logStateChange('Render', operation, data ?? {});
  }

  /// Validate state consistency
  static bool validateState(Map<String, dynamic> element) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) {
        logStateChange('Validation', 'ERROR: Missing content', {});
        return false;
      }

      final characters = content['characters'] as String? ?? '';
      final characterImages =
          content['characterImages'] as Map<String, dynamic>? ?? {};
      final wordMatchingMode =
          content['wordMatchingPriority'] as bool? ?? false;
      final segments = content['segments'] as List<dynamic>? ?? [];

      logStateChange('Validation', 'State check', {
        'characters_length': characters.length,
        'images_count': characterImages.length,
        'word_matching': wordMatchingMode,
        'segments_count': segments.length,
      });

      // Check for common issues
      if (wordMatchingMode && segments.isEmpty && characters.isNotEmpty) {
        logStateChange(
            'Validation', 'WARNING: Word matching mode but no segments', {
          'characters': characters,
        });
        return false;
      }

      return true;
    } catch (e) {
      logStateChange('Validation', 'ERROR: Exception during validation', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Check for UI freeze conditions
  static void checkUIFreeze(String operation, [Map<String, dynamic>? data]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    logStateChange('UIFreeze', operation, {
      'timestamp': timestamp,
      ...?data,
    });
  }
}
