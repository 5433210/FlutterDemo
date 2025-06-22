import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Offset 列表的 JSON 转换器
class OffsetListConverter
    implements JsonConverter<List<Offset>?, List<dynamic>?> {
  const OffsetListConverter();

  @override
  List<Offset>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json.map((item) {
      final map = item as Map<String, dynamic>;
      return Offset(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  List<dynamic>? toJson(List<Offset>? offsets) {
    if (offsets == null) return null;
    return offsets
        .map((offset) => {
              'x': offset.dx,
              'y': offset.dy,
            })
        .toList();
  }
}

/// Rect 的 JSON 转换器
class RectConverter implements JsonConverter<Rect, Map<String, dynamic>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      (json['left'] as num).toDouble(),
      (json['top'] as num).toDouble(),
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }
}

/// Size 的 JSON 转换器
class SizeConverter implements JsonConverter<Size, Map<String, dynamic>> {
  const SizeConverter();

  @override
  Size fromJson(Map<String, dynamic> json) {
    return Size(
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Size size) {
    return {
      'width': size.width,
      'height': size.height,
    };
  }
}

class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  /// 构造函数
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return base64Decode(json);
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return base64Encode(object);
  }
}
