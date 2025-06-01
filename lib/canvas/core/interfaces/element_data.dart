// filepath: lib/canvas/core/interfaces/element_data.dart

import 'dart:ui';

/// 画布元素数据的基础接口
abstract class ElementData {
  /// 元素边界
  Rect get bounds;

  /// 元素唯一标识符
  String get id;

  /// 是否隐藏
  bool get isHidden;

  /// 是否被锁定
  bool get isLocked;

  /// 是否被选中
  bool get isSelected;

  /// 透明度 (0.0 - 1.0)
  double get opacity;

  /// 元素自定义属性
  Map<String, dynamic> get properties;

  /// 旋转角度（弧度）
  double get rotation;

  /// 元素类型
  String get type;

  /// Z轴层级
  int get zIndex;

  /// 创建更新后的副本（不可变模式）
  ElementData copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isSelected,
    bool? isLocked,
    bool? isHidden,
    Map<String, dynamic>? properties,
  });
}
