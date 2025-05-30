import 'dart:convert';

import 'package:charasgem/infrastructure/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/json/rect_converter.dart';
import 'processing_options.dart';

part 'character_region.freezed.dart';
part 'character_region.g.dart';

@freezed
class CharacterRegion with _$CharacterRegion {
  const factory CharacterRegion({
    required String id,
    required String pageId,
    @RectConverter() required Rect rect,
    @Default('') String character,
    String? characterId,
    @Default(ProcessingOptions()) ProcessingOptions options,
    @Default(false) bool isModified,
    @Default(false) bool isSelected,
    DateTime? createTime,
    DateTime? updateTime,
    @Default(0.0) double rotation,

    // New format with brush properties
    List<Map<String, dynamic>>? eraseData,
  }) = _CharacterRegion;

  factory CharacterRegion.create({
    required String pageId,
    required Rect rect,
    required ProcessingOptions options,
    String character = '',
    bool isModified = false,
    bool isSelected = false,
    double rotation = 0.0,
    List<Map<String, dynamic>>? eraseData,
  }) {
    final now = DateTime.now();
    return CharacterRegion(
      id: const Uuid().v4(),
      pageId: pageId,
      rect: rect,
      character: character,
      options: options,
      isModified: isModified,
      isSelected: isSelected,
      createTime: now,
      updateTime: now,
      rotation: rotation,
      eraseData: eraseData,
    );
  }

  factory CharacterRegion.fromJson(Map<String, dynamic> json) =>
      _$CharacterRegionFromJson(json);
}

// Extension for serialization helpers
extension CharacterRegionExt on CharacterRegion {
  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'pageId': pageId,
      'rect_x': rect.left,
      'rect_y': rect.top,
      'rect_width': rect.width,
      'rect_height': rect.height,
      'rotation': rotation,
      'character': character,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'options': jsonEncode(options.toJson()),
      'eraseData':
          eraseData != null ? jsonEncode(_sanitizeEraseData(eraseData!)) : null,
      'characterId': characterId,
      'isSelected': isSelected,
      'isModified': isModified,
    };
  }

  // Helper method to ensure eraseData contains proper brush information
  List<Map<String, dynamic>> _sanitizeEraseData(
      List<Map<String, dynamic>> data) {
    return data.map((pathData) {
      // Ensure each path data has required fields
      final sanitized = Map<String, dynamic>.from(pathData);

      // Ensure brushSize exists
      if (!sanitized.containsKey('brushSize')) {
        sanitized['brushSize'] = options.brushSize;
      }

      // Ensure brushColor exists
      if (!sanitized.containsKey('brushColor')) {
        sanitized['brushColor'] = Colors.white.toARGB32();
      }

      // Ensure points are sanitized for serialization
      if (sanitized.containsKey('points')) {
        final pointsData = sanitized['points'];
        if (pointsData is List) {
          // Convert each point to a serializable format
          final serializedPoints = pointsData.map((point) {
            if (point is Map) {
              return point;
            } else if (point is Offset) {
              return {'dx': point.dx, 'dy': point.dy};
            } else {
              return {'dx': 0.0, 'dy': 0.0}; // Fallback for invalid data
            }
          }).toList();
          sanitized['points'] = serializedPoints;
        }
      }

      return sanitized;
    }).toList();
  }

  // 从数据库记录创建
  static CharacterRegion fromDbJson(Map<String, dynamic> json) {
    final options =
        ProcessingOptions.fromJson(jsonDecode(json['options'] as String));

    List<Map<String, dynamic>>? eraseData;
    if (json['eraseData'] != null) {
      try {
        final decoded = jsonDecode(json['eraseData'] as String) as List;
        eraseData = decoded.map((item) {
          final pathData = Map<String, dynamic>.from(item);

          // Ensure brushSize is a double
          if (pathData.containsKey('brushSize')) {
            pathData['brushSize'] = (pathData['brushSize'] as num).toDouble();
          } else {
            pathData['brushSize'] = options.brushSize;
          }

          // Ensure brushColor is an int
          if (!pathData.containsKey('brushColor')) {
            pathData['brushColor'] = Colors.white.toARGB32();
          }

          return pathData;
        }).toList();
      } catch (e) {
        AppLogger.error('Error decoding eraseData: $e');
        eraseData = null;
      }
    }

    return CharacterRegion(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      rect: Rect.fromLTWH(
        json['rect_x'] as double,
        json['rect_y'] as double,
        json['rect_width'] as double,
        json['rect_height'] as double,
      ),
      rotation: json['rotation'] as double,
      character: json['character'] as String,
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      options: options,
      eraseData: eraseData,
      characterId: json['characterId'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      isModified: json['isModified'] as bool? ?? false,
    );
  }
}
