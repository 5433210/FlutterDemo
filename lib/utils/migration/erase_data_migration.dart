import 'package:flutter/material.dart';

import '../../domain/models/character/character_region.dart';
import '../../infrastructure/logging/logger.dart';

/// Utility to handle migration from erasePoints to eraseData format
class EraseDataMigration {
  /// Converts erasePoints to eraseData format if needed
  static List<Map<String, dynamic>>? migrateEraseData(CharacterRegion region) {
    // Add diagnostic logging
    AppLogger.debug('迁移擦除数据', data: {
      'regionId': region.id,
      'hasEraseData': region.eraseData != null,
      'eraseDataCount': region.eraseData?.length ?? 0,
    });

    // Already has new format
    if (region.eraseData != null && region.eraseData!.isNotEmpty) {
      AppLogger.debug('使用现有eraseData格式');

      // Validate eraseData structure
      bool isValid = true;
      for (final pathData in region.eraseData!) {
        if (!pathData.containsKey('points') ||
            !pathData.containsKey('brushSize') ||
            !pathData.containsKey('brushColor')) {
          isValid = false;
          break;
        }
      }

      if (!isValid) {
        AppLogger.warning('eraseData结构无效，尝试重新格式化');
        // Try to restructure if invalid
        return _restructureEraseData(region.eraseData!);
      }

      return region.eraseData;
    }

    AppLogger.debug('没有擦除数据需要迁移');
    return null;
  }

  /// Updates a region to use the new eraseData format if needed
  static CharacterRegion migrateRegion(CharacterRegion region) {
    if (region.eraseData != null && region.eraseData!.isNotEmpty) {
      return region;
    }

    final migratedData = migrateEraseData(region);
    return region.copyWith(
      eraseData: migratedData,
    );
  }

  /// Attempt to fix invalid eraseData structure
  static List<Map<String, dynamic>> _restructureEraseData(
      List<Map<String, dynamic>> eraseData) {
    final result = <Map<String, dynamic>>[];

    for (final pathData in eraseData) {
      final newPathData = <String, dynamic>{};

      // Extract or default points
      if (pathData.containsKey('points')) {
        newPathData['points'] = pathData['points'];
      } else {
        continue; // Skip paths without points
      }

      // Extract or default brushSize
      if (pathData.containsKey('brushSize')) {
        newPathData['brushSize'] = pathData['brushSize'];
      } else {
        newPathData['brushSize'] = 10.0; // Default brush size
      }

      // Extract or default brushColor
      if (pathData.containsKey('brushColor')) {
        newPathData['brushColor'] = pathData['brushColor'];
      } else {
        newPathData['brushColor'] = Colors.white.toARGB32(); // Default color
      }

      result.add(newPathData);
    }

    return result;
  }
}
