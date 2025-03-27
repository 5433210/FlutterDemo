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
    required String character,
    required DateTime createTime,
    required DateTime updateTime,
    required ProcessingOptions options,
    @OffsetListConverter() List<Offset>? erasePoints, // 新增：擦除点列表
  }) = _CharacterRegion;

  factory CharacterRegion.create({
    required String pageId,
    required Rect rect,
    double rotation = 0.0,
    String character = '',
    ProcessingOptions? options,
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
    );
  }
}
