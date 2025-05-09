import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

/// Uint8List JSON 转换器
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
