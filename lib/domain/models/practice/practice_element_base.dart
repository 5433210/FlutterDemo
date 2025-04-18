import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_element_base.freezed.dart';

/// 元素基础属性
@freezed
class PracticeElementBase with _$PracticeElementBase {
  const factory PracticeElementBase({
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0.0) double rotation,
    required String layerId,
    @Default(false) bool isLocked,
    @Default(1.0) double opacity,
  }) = _PracticeElementBase;

  const PracticeElementBase._();

  /// 获取元素的中心点
  Offset get center => Offset(x + width / 2, y + height / 2);

  /// 获取元素的边界矩形
  Rect get rect => Rect.fromLTWH(x, y, width, height);

  /// 获取元素的变换矩阵
  Matrix4 get transform {
    final matrix = Matrix4.identity();
    // 平移到元素位置
    matrix.translate(x, y);

    // 应用旋转（围绕元素中心）
    if (rotation != 0) {
      matrix.translate(width / 2, height / 2);
      matrix.rotateZ(rotation * (3.1415926535 / 180));
      matrix.translate(-width / 2, -height / 2);
    }

    return matrix;
  }

  /// 检查点是否在元素内
  bool containsPoint(Offset point) {
    // 考虑旋转的情况下，这里需要更复杂的计算
    // 简化版本，只考虑矩形
    return rect.contains(point);
  }
}
