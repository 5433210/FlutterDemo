import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/utils/json_converters.dart';

part 'detected_outline.freezed.dart';
part 'detected_outline.g.dart';

class ContourPointsConverter
    implements JsonConverter<List<List<Offset>>, List<dynamic>> {
  const ContourPointsConverter();

  @override
  List<List<Offset>> fromJson(List<dynamic> json) {
    return json.map((contour) {
      return (contour as List).map((point) {
        final Map<String, dynamic> pointMap = point as Map<String, dynamic>;
        return Offset(pointMap['x'] as double, pointMap['y'] as double);
      }).toList();
    }).toList();
  }

  @override
  List<dynamic> toJson(List<List<Offset>> contours) {
    return contours.map((contour) {
      return contour.map((point) => {'x': point.dx, 'y': point.dy}).toList();
    }).toList();
  }
}

@freezed
class DetectedOutline with _$DetectedOutline {
  const factory DetectedOutline({
    @RectConverter() required Rect boundingRect,
    @ContourPointsConverter() required List<List<Offset>> contourPoints,
  }) = _DetectedOutline;

  factory DetectedOutline.fromJson(Map<String, dynamic> json) =>
      _$DetectedOutlineFromJson(json);
}
