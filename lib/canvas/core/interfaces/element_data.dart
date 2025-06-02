// filepath: lib/canvas/core/interfaces/element_data.dart

import 'dart:ui';
import 'dart:typed_data' show Float64List;

/// 画布元素数据的基础接口
class ElementData {
  /// 元素边界
  final Rect bounds;

  /// 元素唯一标识符
  final String id;
  
  /// 所属图层ID
  final String layerId;

  /// 是否可见
  final bool visible;

  /// 是否被锁定
  final bool locked;

  /// 透明度 (0.0 - 1.0)
  final double opacity;

  /// 元素自定义属性
  final Map<String, dynamic> properties;

  /// 旋转角度（弧度）
  final double rotation;

  /// 变换矩阵
  final Float64List? transform;

  /// 元素类型
  final String type;

  /// Z轴层级
  final int zIndex;
  
  /// 构造函数
  const ElementData({
    required this.id,
    required this.type,
    required this.layerId,
    this.bounds = const Rect.fromLTWH(0, 0, 100, 100),
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.transform,
    this.zIndex = 0,
    this.properties = const {},
  });

  /// 创建更新后的副本（不可变模式）
  ElementData copyWith({
    String? layerId,
    Rect? bounds,
    double? rotation,
    Float64List? transform,
    double? opacity,
    int? zIndex,
    bool? visible,
    bool? locked,
    Map<String, dynamic>? properties,
  }) {
    return ElementData(
      id: this.id,
      type: this.type,
      layerId: layerId ?? this.layerId,
      bounds: bounds ?? this.bounds,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      transform: transform ?? this.transform,
      zIndex: zIndex ?? this.zIndex,
      properties: properties ?? this.properties,
    );
  }
  
  /// 元素是否被选中 (兼容旧版API)
  bool get isSelected => false;
  
  /// 元素是否隐藏 (兼容旧版API)
  bool get isHidden => !visible;
  
  /// 元素是否被锁定 (兼容旧版API)
  bool get isLocked => locked;
}
