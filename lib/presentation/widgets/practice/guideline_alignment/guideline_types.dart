import 'package:flutter/material.dart';

/// 对齐检测配置
class AlignmentConfig {
  /// 默认配置
  static const AlignmentConfig defaultConfig = AlignmentConfig();
  final double snapThreshold;
  final bool enableHorizontalAlignment;
  final bool enableVerticalAlignment;
  final bool enableCenterLineAlignment;

  final bool enableEdgeAlignment;

  const AlignmentConfig({
    this.snapThreshold = 5.0,
    this.enableHorizontalAlignment = true,
    this.enableVerticalAlignment = true,
    this.enableCenterLineAlignment = true,
    this.enableEdgeAlignment = true,
  });

  /// 判断是否启用指定类型的参考线
  bool isGuidelineTypeEnabled(GuidelineType type) {
    switch (type) {
      case GuidelineType.horizontalCenterLine:
        return enableHorizontalAlignment && enableCenterLineAlignment;
      case GuidelineType.verticalCenterLine:
        return enableVerticalAlignment && enableCenterLineAlignment;
      case GuidelineType.horizontalTopEdge:
      case GuidelineType.horizontalBottomEdge:
        return enableHorizontalAlignment && enableEdgeAlignment;
      case GuidelineType.verticalLeftEdge:
      case GuidelineType.verticalRightEdge:
        return enableVerticalAlignment && enableEdgeAlignment;
    }
  }
}

/// 对齐方向枚举
enum AlignmentDirection {
  horizontal, // 水平方向
  vertical, // 垂直方向
}

/// 对齐模式枚举
enum AlignmentMode {
  none, // 无辅助
  gridSnap, // 网格贴附
  guideline, // 参考线对齐
}

/// 对齐结果
class AlignmentResult {
  final bool hasAlignment;
  final Map<String, double> alignedProperties;
  final List<Guideline> activeGuidelines;
  final Rect? alignedBounds;

  const AlignmentResult({
    required this.hasAlignment,
    required this.alignedProperties,
    required this.activeGuidelines,
    this.alignedBounds,
  });

  /// 创建无对齐结果
  factory AlignmentResult.noAlignment() {
    return const AlignmentResult(
      hasAlignment: false,
      alignedProperties: {},
      activeGuidelines: [],
    );
  }

  /// 创建有对齐结果
  factory AlignmentResult.withAlignment({
    required Map<String, double> alignedProperties,
    required List<Guideline> activeGuidelines,
    Rect? alignedBounds,
  }) {
    return AlignmentResult(
      hasAlignment: true,
      alignedProperties: alignedProperties,
      activeGuidelines: activeGuidelines,
      alignedBounds: alignedBounds,
    );
  }

  @override
  String toString() {
    return 'AlignmentResult{hasAlignment: $hasAlignment, alignedProperties: $alignedProperties, activeGuidelines: ${activeGuidelines.length} guidelines}';
  }
}

/// 参考线数据类
class Guideline {
  final String id;
  final GuidelineType type;
  final double position; // 在坐标轴上的位置
  final AlignmentDirection direction;
  final String? sourceElementId;
  final Rect? sourceElementBounds;

  /// 🔧 新增：视觉高亮相关属性
  final bool isHighlighted;
  final double? distanceToTarget;
  final bool canSnap;
  
  /// 🔹 新增：参考线外观属性
  final Color color;
  final double lineWeight;

  const Guideline({
    required this.id,
    required this.type,
    required this.position,
    required this.direction,
    this.sourceElementId,
    this.sourceElementBounds,
    this.isHighlighted = false,
    this.distanceToTarget,
    this.canSnap = false,
    this.color = const Color(0xFF4CAF50), // 默认绿色
    this.lineWeight = 1.5, // 默认线宽
  });

  @override
  int get hashCode =>
      id.hashCode ^ type.hashCode ^ position.hashCode ^ direction.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Guideline &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          position == other.position &&
          direction == other.direction;

  /// 计算对齐后的目标位置
  double calculateAlignedPosition(Rect targetBounds, String property) {
    switch (type) {
      case GuidelineType.horizontalCenterLine:
        if (property == 'y') return position - targetBounds.height / 2;
        break;
      case GuidelineType.verticalCenterLine:
        if (property == 'x') return position - targetBounds.width / 2;
        break;
      case GuidelineType.horizontalTopEdge:
        if (property == 'y') return position;
        break;
      case GuidelineType.horizontalBottomEdge:
        if (property == 'y') return position - targetBounds.height;
        break;
      case GuidelineType.verticalLeftEdge:
        if (property == 'x') return position;
        break;
      case GuidelineType.verticalRightEdge:
        if (property == 'x') return position - targetBounds.width;
        break;
    }
    throw ArgumentError('Invalid property $property for guideline type $type');
  }

  /// 创建带高亮信息的参考线副本
  Guideline copyWith({
    String? id,
    GuidelineType? type,
    double? position,
    AlignmentDirection? direction,
    String? sourceElementId,
    Rect? sourceElementBounds,
    bool? isHighlighted,
    double? distanceToTarget,
    bool? canSnap,
    Color? color, // 🔹 新增支持颜色
    double? lineWeight, // 🔹 新增支持线宽
  }) {
    return Guideline(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      direction: direction ?? this.direction,
      sourceElementId: sourceElementId ?? this.sourceElementId,
      sourceElementBounds: sourceElementBounds ?? this.sourceElementBounds,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      distanceToTarget: distanceToTarget ?? this.distanceToTarget,
      canSnap: canSnap ?? this.canSnap,
      color: color ?? this.color, // 🔹 复制颜色
      lineWeight: lineWeight ?? this.lineWeight, // 🔹 复制线宽
    );
  }

  /// 计算与目标边界的距离
  double distanceTo(Rect targetBounds) {
    switch (type) {
      case GuidelineType.horizontalCenterLine:
        return (targetBounds.center.dy - position).abs();
      case GuidelineType.verticalCenterLine:
        return (targetBounds.center.dx - position).abs();
      case GuidelineType.horizontalTopEdge:
        return (targetBounds.top - position).abs();
      case GuidelineType.horizontalBottomEdge:
        return (targetBounds.bottom - position).abs();
      case GuidelineType.verticalLeftEdge:
        return (targetBounds.left - position).abs();
      case GuidelineType.verticalRightEdge:
        return (targetBounds.right - position).abs();
    }
  }

  /// 判断两个参考线是否等价
  bool isEquivalentTo(Guideline other) {
    // 位置误差范围（像素）
    const positionTolerance = 0.5;

    return type == other.type &&
        direction == other.direction &&
        (position - other.position).abs() < positionTolerance;
  }

  @override
  String toString() =>
      'Guideline{id: $id, type: $type, position: $position, direction: $direction}';

  /// 创建水平参考线
  static Guideline horizontal({
    required String id,
    required double y,
    GuidelineType type = GuidelineType.horizontalCenterLine,
    String? sourceElementId,
    Rect? sourceElementBounds,
  }) {
    return Guideline(
      id: id,
      type: type,
      position: y,
      direction: AlignmentDirection.horizontal,
      sourceElementId: sourceElementId,
      sourceElementBounds: sourceElementBounds,
    );
  }

  /// 创建垂直参考线
  static Guideline vertical({
    required String id,
    required double x,
    GuidelineType type = GuidelineType.verticalCenterLine,
    String? sourceElementId,
    Rect? sourceElementBounds,
  }) {
    return Guideline(
      id: id,
      type: type,
      position: x,
      direction: AlignmentDirection.vertical,
      sourceElementId: sourceElementId,
      sourceElementBounds: sourceElementBounds,
    );
  }
}

/// 参考线候选项（用于距离排序）
class GuidelineCandidate {
  final Guideline guideline;
  final double distance;

  const GuidelineCandidate(this.guideline, this.distance);

  @override
  String toString() {
    return 'GuidelineCandidate{guideline: ${guideline.id}, distance: $distance}';
  }
}

/// 参考线类型枚举
enum GuidelineType {
  horizontalCenterLine, // 横向中线
  verticalCenterLine, // 纵向中线
  horizontalTopEdge, // 横向上边线
  horizontalBottomEdge, // 横向下边线
  verticalLeftEdge, // 纵向左边线
  verticalRightEdge, // 纵向右边线
}
