
import 'package:flutter/material.dart';

/// 参考线类型枚举
enum GuideLineType {
  // 中线
  horizontalCenter,  // 横向中线
  verticalCenter,    // 纵向中线
  
  // 边线
  top,              // 上边线
  bottom,           // 下边线
  left,             // 左边线
  right,            // 右边线
}

/// 参考线方向枚举
enum GuideLineOrientation {
  horizontal,       // 横向参考线
  vertical,         // 纵向参考线
}

/// 对齐类型枚举
enum AlignmentType {
  // 同类型对齐
  centerToCenter,    // 中线对中线
  edgeToEdge,        // 边线对边线
  
  // 混合对齐
  centerToEdge,      // 中线对边线
  edgeToCenter,      // 边线对中线
}

/// 对齐模式枚举
enum AlignmentMode {
  none,           // 无自动对齐
  grid,          // 网格对齐模式
  guideLine,     // 参考线对齐模式
}

/// 参考线数据结构
class GuideLine {
  final String elementId;              // 关联的元素ID
  final GuideLineType type;            // 参考线类型
  final GuideLineOrientation orientation; // 方向
  final double position;               // 位置坐标
  final Rect elementBounds;           // 元素边界
  
  const GuideLine({
    required this.elementId,
    required this.type,
    required this.orientation,
    required this.position,
    required this.elementBounds,
  });

  /// 计算属性：是否为中心线
  bool get isCenter => type == GuideLineType.horizontalCenter || 
                      type == GuideLineType.verticalCenter;
  
  /// 计算属性：是否为边线
  bool get isEdge => !isCenter;

  @override
  String toString() {
    return 'GuideLine(elementId: $elementId, type: $type, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GuideLine &&
            runtimeType == other.runtimeType &&
            elementId == other.elementId &&
            type == other.type &&
            position == other.position;
  }

  @override
  int get hashCode {
    return elementId.hashCode ^ type.hashCode ^ position.hashCode;
  }
}

/// 对齐匹配结果
class AlignmentMatch {
  final GuideLine sourceLine;         // 被拖拽元素的参考线
  final GuideLine targetLine;         // 目标元素的参考线
  final AlignmentType alignmentType;  // 对齐类型
  final double distance;              // 距离
  final Offset adjustment;            // 需要调整的偏移量
  
  const AlignmentMatch({
    required this.sourceLine,
    required this.targetLine,
    required this.alignmentType,
    required this.distance,
    required this.adjustment,
  });

  /// 优先级：距离越近优先级越高
  double get priority => 1.0 / (distance + 1.0);

  @override
  String toString() {
    return 'AlignmentMatch(type: $alignmentType, distance: ${distance.toStringAsFixed(2)}, adjustment: $adjustment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AlignmentMatch &&
            runtimeType == other.runtimeType &&
            sourceLine == other.sourceLine &&
            targetLine == other.targetLine &&
            alignmentType == other.alignmentType;
  }

  @override
  int get hashCode {
    return sourceLine.hashCode ^ targetLine.hashCode ^ alignmentType.hashCode;
  }
}
