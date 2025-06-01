// filepath: lib/canvas/core/models/element_data.dart

import 'dart:ui';

import '../interfaces/element_data.dart';

/// 画布元素数据的具体实现
class CanvasElementData implements ElementData {
  @override
  final String id;

  @override
  final String type;

  @override
  final Rect bounds;

  @override
  final double rotation;

  @override
  final double opacity;

  @override
  final int zIndex;

  @override
  final bool isSelected;

  @override
  final bool isLocked;

  @override
  final bool isHidden;

  @override
  final Map<String, dynamic> properties;

  const CanvasElementData({
    required this.id,
    required this.type,
    required this.bounds,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.isSelected = false,
    this.isLocked = false,
    this.isHidden = false,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? const {};

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasElementData && other.id == id;
  }

  @override
  ElementData copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isSelected,
    bool? isLocked,
    bool? isHidden,
    Map<String, dynamic>? properties,
  }) {
    return CanvasElementData(
      id: id,
      type: type,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isSelected: isSelected ?? this.isSelected,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      properties: properties ?? Map.from(this.properties),
    );
  }

  @override
  String toString() => 'CanvasElementData(id: $id, type: $type)';
}
