import 'package:flutter/material.dart';

import 'alignment_config.dart';
import 'alignment_types.dart';
import 'guide_line_generator.dart';

/// 对齐检测器
///
/// 负责识别拖拽元素与其他元素之间的潜在对齐关系。
/// 算法采用穷举搜索策略，确保不遗漏任何可能的对齐机会。
class AlignmentDetector {
  /// 检测指定元素与其他元素的对齐关系（用于静态分析）
  ///
  /// 参数:
  /// - [elementId]: 要分析的元素ID
  /// - [allElements]: 所有元素列表
  ///
  /// 返回:
  /// - 该元素的所有对齐关系
  static List<AlignmentMatch> analyzeElementAlignments(
    String elementId,
    List<Map<String, dynamic>> allElements,
  ) {
    final targetElement = allElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (targetElement.isEmpty) return [];

    final otherElements =
        allElements.where((e) => e['id'] != elementId).toList();
    return detectAlignments(targetElement, otherElements);
  }

  /// 检测最佳对齐匹配
  ///
  /// 算法步骤详解：
  /// 1. 参考线生成阶段：为被拖拽元素和所有其他元素生成参考线
  /// 2. 两两比较阶段：对拖拽元素的每条参考线，与所有其他元素的参考线进行比较
  /// 3. 距离筛选阶段：只保留距离小于等于阈值的匹配
  /// 4. 匹配信息构建：为每个有效匹配创建AlignmentMatch对象
  ///
  /// 参数:
  /// - [draggedElement]: 被拖拽的元素
  /// - [otherElements]: 其他所有元素
  /// - [scaleFactor]: 当前缩放因子（可选，默认1.0）
  ///
  /// 返回:
  /// - 按优先级排序的对齐匹配列表（最多2个：水平+垂直各1个）
  static List<AlignmentMatch> detectAlignments(
    Map<String, dynamic> draggedElement,
    List<Map<String, dynamic>> otherElements, {
    double scaleFactor = 1.0,
  }) {
    final draggedLines = GuideLineGenerator.generateGuideLines(draggedElement);
    final allMatches = <AlignmentMatch>[];
    final threshold = AlignmentConfig.getScaledThreshold(scaleFactor);

    // 为所有其他元素生成参考线
    for (final element in otherElements) {
      if (element['id'] == draggedElement['id']) continue;

      final targetLines = GuideLineGenerator.generateGuideLines(element);

      // 检测每条拖拽元素参考线与目标参考线的匹配
      for (final sourceLine in draggedLines) {
        for (final targetLine in targetLines) {
          final match = _checkAlignment(sourceLine, targetLine, threshold);
          if (match != null) {
            allMatches.add(match);
          }
        }
      }
    }

    // 按优先级排序并过滤最佳匹配
    allMatches.sort((a, b) => b.priority.compareTo(a.priority));
    return _filterBestMatches(allMatches);
  }

  /// 计算调整偏移量
  ///
  /// 计算公式：
  /// - 偏移量 = 目标位置 - 当前位置
  /// - 水平参考线：返回(0, delta)，只调整Y坐标
  /// - 垂直参考线：返回(delta, 0)，只调整X坐标
  ///
  /// 这确保了每次只在一个方向上进行对齐调整，避免了复杂的多维度调整
  static Offset _calculateAdjustment(GuideLine source, GuideLine target) {
    final delta = target.position - source.position;

    if (source.orientation == GuideLineOrientation.horizontal) {
      return Offset(0, delta);
    } else {
      return Offset(delta, 0);
    }
  }

  /// 检查两条参考线是否可以对齐
  ///
  /// 算法逻辑：
  /// 1. 方向检查：只检查相同方向的参考线
  /// 2. 距离检查：距离必须在阈值范围内
  /// 3. 类型判断：确定对齐类型（中线对中线、边线对边线等）
  /// 4. 偏移计算：计算需要调整的偏移量
  ///
  /// 参数:
  /// - [source]: 源参考线（被拖拽元素的）
  /// - [target]: 目标参考线（其他元素的）
  /// - [threshold]: 距离阈值
  ///
  /// 返回:
  /// - 如果可以对齐返回AlignmentMatch对象，否则返回null
  static AlignmentMatch? _checkAlignment(
    GuideLine source,
    GuideLine target,
    double threshold,
  ) {
    // 只检查相同方向的参考线
    if (source.orientation != target.orientation) return null;

    final distance = (source.position - target.position).abs();
    if (distance > threshold) return null;

    // 确定对齐类型
    final alignmentType = _determineAlignmentType(source, target);

    // 计算调整偏移量
    final adjustment = _calculateAdjustment(source, target);

    return AlignmentMatch(
      sourceLine: source,
      targetLine: target,
      alignmentType: alignmentType,
      distance: distance,
      adjustment: adjustment,
    );
  }

  /// 确定对齐类型
  ///
  /// 对齐类型分类：
  /// - 中线对中线（centerToCenter）：最常用的对齐方式，视觉效果最佳
  /// - 边线对边线（edgeToEdge）：适合元素边界对齐的场景
  /// - 中线对边线（centerToEdge）：一个元素的中心对齐到另一个元素的边界
  /// - 边线对中线（edgeToCenter）：一个元素的边界对齐到另一个元素的中心
  ///
  /// 判断优先级：中线对中线 > 边线对边线 > 混合对齐
  static AlignmentType _determineAlignmentType(
      GuideLine source, GuideLine target) {
    if (source.isCenter && target.isCenter) {
      return AlignmentType.centerToCenter;
    } else if (source.isEdge && target.isEdge) {
      return AlignmentType.edgeToEdge;
    } else if (source.isCenter && target.isEdge) {
      return AlignmentType.centerToEdge;
    } else {
      return AlignmentType.edgeToCenter;
    }
  }

  /// 过滤最佳匹配（每个方向只保留最优匹配）
  ///
  /// 过滤策略：
  /// 1. 方向独立性：水平和垂直方向的对齐是独立的，用户可以同时在两个方向上对齐
  /// 2. 单方向唯一性：每个方向只保留一个最佳匹配，避免同一方向的多重对齐冲突
  /// 3. 距离优先原则：由于输入的匹配列表已按距离排序，取第一个即为最近距离的匹配
  ///
  /// 算法效果：
  /// - 最多返回2个匹配：一个水平方向，一个垂直方向
  /// - 确保对齐结果的确定性和可预测性
  /// - 避免了复杂的多重对齐导致的位置混乱
  static List<AlignmentMatch> _filterBestMatches(
      List<AlignmentMatch> allMatches) {
    final bestHorizontal = allMatches
        .where(
            (m) => m.sourceLine.orientation == GuideLineOrientation.horizontal)
        .take(1);

    final bestVertical = allMatches
        .where((m) => m.sourceLine.orientation == GuideLineOrientation.vertical)
        .take(1);

    return [...bestHorizontal, ...bestVertical];
  }
}
