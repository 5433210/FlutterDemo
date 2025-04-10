import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts between Offset objects and JSON
class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Offset offset) {
    return {
      'dx': offset.dx,
      'dy': offset.dy,
    };
  }
}

/// Converts between List<Offset> objects and JSON
class OffsetListConverter
    implements JsonConverter<List<Offset>, List<dynamic>> {
  const OffsetListConverter();

  @override
  List<Offset> fromJson(List<dynamic> json) {
    return json
        .map((e) => const OffsetConverter().fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<Offset> offsets) {
    return offsets
        .map((offset) => const OffsetConverter().toJson(offset))
        .toList();
  }
}

/// Converts between List<List<Offset>> objects and JSON
class OffsetListListConverter
    implements JsonConverter<List<List<Offset>>, List<dynamic>> {
  const OffsetListListConverter();

  @override
  List<List<Offset>> fromJson(List<dynamic> json) {
    return json
        .map((e) => const OffsetListConverter().fromJson(e as List<dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<List<Offset>> offsetLists) {
    return offsetLists
        .map((list) => const OffsetListConverter().toJson(list))
        .toList();
  }
}
