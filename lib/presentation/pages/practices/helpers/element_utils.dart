import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';

/// Utility class for element operations
class ElementUtils {
  // 🚀 优化：缓存最近的像素尺寸计算结果
  static String? _lastSizeCalculationKey;
  static int _sizeCalculationCount = 0;

  /// Calculate size in pixels from millimeters
  static Size calculatePixelSize(Map<String, dynamic> page) {
    // Get page size (millimeters)
    final width = (page['width'] as num?)?.toDouble() ?? 210.0;
    final height = (page['height'] as num?)?.toDouble() ?? 297.0;
    final orientation = page['orientation'] as String? ?? 'portrait';
    final dpi = (page['dpi'] as num?)?.toInt() ?? 300;

    // 🚀 优化：减少重复的像素尺寸计算日志
    final calculationKey = '${width}_${height}_${orientation}_$dpi';
    _sizeCalculationCount++;

    if (_lastSizeCalculationKey != calculationKey) {
      EditPageLogger.canvasDebug('页面像素尺寸计算', data: {
        'width': width,
        'height': height,
        'orientation': orientation,
        'dpi': dpi,
        'calculationCount': _sizeCalculationCount,
        'changeType': _lastSizeCalculationKey == null
            ? 'first_calculation'
            : 'page_changed',
        'optimization': 'pixel_size_calculation_optimized'
      });
      _lastSizeCalculationKey = calculationKey;
    } else if (_sizeCalculationCount % 50 == 0) {
      // 里程碑记录
      EditPageLogger.canvasDebug('像素尺寸计算里程碑', data: {
        'calculationCount': _sizeCalculationCount,
        'cachedParams': calculationKey,
        'optimization': 'pixel_size_milestone'
      });
    }

    // Convert mm to inches, 1 inch = 25.4mm
    final widthInches = width / 25.4;
    final heightInches = height / 25.4;

    // Calculate pixel size
    final widthPixels = (widthInches * dpi).round().toDouble();
    final heightPixels = (heightInches * dpi).round().toDouble();

    // 🚀 优化：只在首次或参数变化时记录计算结果
    if (_lastSizeCalculationKey == calculationKey &&
        _sizeCalculationCount <= 1) {
      EditPageLogger.canvasDebug('像素尺寸计算结果', data: {
        'widthPixels': widthPixels,
        'heightPixels': heightPixels,
        'optimization': 'first_result_logged'
      });
    }

    return Size(widthPixels, heightPixels);
  }

  /// Find element by ID
  static Map<String, dynamic>? findElementById(
      List<Map<String, dynamic>> elements, String id) {
    for (final element in elements) {
      if (element['id'] == id) {
        return element;
      }

      // Check if it's a group and search inside
      if (element['type'] == 'group') {
        final groupElements = (element['content']['elements'] as List?)
            ?.cast<Map<String, dynamic>>();

        if (groupElements != null) {
          final found = findElementById(groupElements, id);
          if (found != null) {
            return found;
          }
        }
      }
    }

    return null;
  }

  static Color parseColor(String hexColor) {
    try {
      // Handle transparent color
      if (hexColor == 'transparent') {
        return Colors.transparent;
      }

      // Remove # if present
      hexColor = hexColor.toUpperCase().replaceAll('#', '');

      // Add alpha channel if not provided
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha if not provided
      }

      // Parse the color
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      EditPageLogger.editPageError('颜色解析失败',
          data: {'hexColor': hexColor}, error: e);
      return Colors.white; // Default to white on error
    }
  }

  /// Sort elements by layer order
  static List<Map<String, dynamic>> sortElementsByLayerOrder(
      List<Map<String, dynamic>> elements, List<dynamic> layers) {
    // Create layer order mapping
    // Note: Higher index in layers list means top layer, should be rendered later
    final layerOrderMap = <String, int>{};
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i] as Map<String, dynamic>;
      final layerId = layer['id'] as String;
      layerOrderMap[layerId] = i; // Use layer index in list as sort criteria
    }

    // Sort elements
    final sortedElements = List<Map<String, dynamic>>.from(elements);
    sortedElements.sort((a, b) {
      final aLayerId = a['layerId'] as String?;
      final bLayerId = b['layerId'] as String?;

      // If element has no layer ID, put it at the end
      if (aLayerId == null && bLayerId == null) return 0;
      if (aLayerId == null) return 1;
      if (bLayerId == null) return -1;

      // Sort by layer order
      // Higher layer index (more top) should be rendered later
      final aOrder = layerOrderMap[aLayerId] ?? 0;
      final bOrder = layerOrderMap[bLayerId] ?? 0;
      return aOrder.compareTo(
          bOrder); // Lower index renders first, higher index renders later
    });

    return sortedElements;
  }
}
