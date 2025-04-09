import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/utils/json_converters.dart';
import 'processing_options.dart';

part 'character_region.freezed.dart';
part 'character_region.g.dart';

@freezed
class CharacterRegion with _$CharacterRegion {
  const factory CharacterRegion({
    required String id,
    required String pageId,
    @RectConverter() required Rect rect,
    @Default(0.0) double rotation,
    @Default('') String character,
    required DateTime createTime,
    required DateTime updateTime,
    @Default(ProcessingOptions()) ProcessingOptions options,
    @OffsetListConverter() List<Offset>? erasePoints,
    String? characterId,
    @Default(false) bool isSelected, // New property
    @Default(false) bool isModified, // New property
  }) = _CharacterRegion;

  factory CharacterRegion.create({
    required String pageId,
    required Rect rect,
    double rotation = 0.0,
    String character = '',
    ProcessingOptions? options,
    String? characterId,
    bool isSelected = false, // New parameter
    bool isModified = true, // Default to true for new regions
  }) {
    final now = DateTime.now();
    return CharacterRegion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pageId: pageId,
      rect: rect,
      rotation: rotation,
      character: character,
      createTime: now,
      updateTime: now,
      options: options ?? const ProcessingOptions(),
      characterId: characterId,
      isSelected: isSelected, // Set new property
      isModified: isModified, // Set new property
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
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'options': jsonEncode(options.toJson()),
      'erasePoints': erasePoints != null
          ? jsonEncode(erasePoints!.map((p) => {'x': p.dx, 'y': p.dy}).toList())
          : null,
      'characterId': characterId,
      'isSelected': isSelected, // New field
      'isModified': isModified, // New field
    };
  }

  // 从数据库记录创建
  static CharacterRegion fromDbJson(Map<String, dynamic> json) {
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
      options:
          ProcessingOptions.fromJson(jsonDecode(json['options'] as String)),
      erasePoints: json['erasePoints'] != null
          ? (jsonDecode(json['erasePoints'] as String) as List)
              .map(
                  (point) => Offset(point['x'] as double, point['y'] as double))
              .toList()
          : [],
      characterId: json['characterId'] as String?,
      isSelected: json['isSelected'] as bool? ?? false, // New field
      isModified: json['isModified'] as bool? ?? false, // New field
    );
  }
}
