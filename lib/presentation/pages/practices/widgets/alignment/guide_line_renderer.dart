import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'alignment_config.dart';
import 'alignment_types.dart';

/// 参考线渲染器
///
/// 采用多层次的信息传达策略，确保用户能够清晰理解当前的对齐状态。
class GuideLineRenderer {
  /// 高亮显示特定元素的边界框（调试用）
  ///
  /// 用于验证元素边界计算是否正确
  static void highlightElementBounds(
    Canvas canvas,
    Map<String, dynamic> element,
  ) {
    if (!AlignmentConfig.showDebugInfo) return;

    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    final bounds = Rect.fromLTWH(x, y, width, height);

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(bounds, paint);

    // 绘制边界框轮廓
    final strokePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(bounds, strokePaint);
  }

  /// 绘制所有元素的参考线（调试用）
  ///
  /// 显示画布上所有元素的参考线，用于调试对齐算法
  static void paintAllGuideLines(
    Canvas canvas,
    Size canvasSize,
    List<GuideLine> guideLines,
  ) {
    if (!AlignmentConfig.showDebugInfo) return;

    EditPageLogger.rendererDebug('绘制所有元素参考线', data: {
      'guideLinesCount': guideLines.length,
      'operation': 'guide_line_debug_all',
    });

    final debugPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final guideLine in guideLines) {
      _drawGuideLine(canvas, canvasSize, guideLine, debugPaint);
    }
  }

  /// 绘制调试信息
  ///
  /// 在开发模式下显示对齐距离和调整信息
  static void paintDebugInfo(
    Canvas canvas,
    Size canvasSize,
    List<AlignmentMatch> activeAlignments,
  ) {
    if (!AlignmentConfig.showDebugInfo) return;

    EditPageLogger.rendererDebug('绘制对齐调试信息', data: {
      'alignmentsCount': activeAlignments.length,
      'operation': 'guide_line_debug_paint',
    });

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < activeAlignments.length; i++) {
      final alignment = activeAlignments[i];

      // 构建调试文本
      final debugText = 'Alignment ${i + 1}\n'
          'Type: ${alignment.alignmentType}\n'
          'Distance: ${alignment.distance.toStringAsFixed(1)}px\n'
          'Adjustment: (${alignment.adjustment.dx.toStringAsFixed(1)}, ${alignment.adjustment.dy.toStringAsFixed(1)})';

      textPainter.text = TextSpan(
        text: debugText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          backgroundColor: Colors.white,
        ),
      );

      textPainter.layout();

      // 在画布右上角绘制调试信息
      final position = Offset(
        canvasSize.width - textPainter.width - 10,
        10 + i * (textPainter.height + 5),
      );

      textPainter.paint(canvas, position);
    }
  }

  /// 绘制拖拽过程中的参考线
  ///
  /// 渲染层次设计：
  /// 1. 参考线主体：使用虚线绘制，减少视觉干扰
  /// 2. 吸附指示器：在关键交点绘制圆点，明确对齐位置
  /// 3. 方向箭头：显示调整方向，帮助用户理解移动意图
  /// 4. 距离标注：调试模式下显示精确距离信息
  ///
  /// 性能优化策略：
  /// - 空检查：活跃对齐为空时立即返回，避免无效绘制
  /// - 批量绘制：使用相同Paint对象绘制同类型元素
  /// - 条件渲染：调试信息只在需要时绘制
  static void paintGuideLines(
    Canvas canvas,
    Size canvasSize,
    List<AlignmentMatch> activeAlignments,
    String draggedElementId,
  ) {
    EditPageLogger.rendererDebug('开始绘制参考线', data: {
      'activeAlignmentsCount': activeAlignments.length,
      'canvasSize': '$canvasSize',
      'draggedElementId': draggedElementId,
      'operation': 'guide_line_paint_start',
    });

    if (activeAlignments.isEmpty) {
      EditPageLogger.rendererDebug('无活跃对齐，跳过绘制', data: {
        'operation': 'guide_line_paint_skip',
      });
      return;
    }

    EditPageLogger.rendererDebug('绘制参考线渲染', data: {
      'alignmentsCount': activeAlignments.length,
      'operation': 'guide_line_paint_render',
    });

    final guideLinePaint = AlignmentConfig.guideLinePaint;
    final snapIndicatorPaint = AlignmentConfig.snapIndicatorPaint;

    for (final alignment in activeAlignments) {
      EditPageLogger.rendererDebug('绘制单条对齐线', data: {
        'lineType': alignment.targetLine.type.toString(),
        'operation': 'guide_line_paint_single',
      });

      // 绘制参考线
      _drawGuideLine(canvas, canvasSize, alignment.targetLine, guideLinePaint);

      // 绘制吸附指示器
      _drawSnapIndicator(canvas, alignment, snapIndicatorPaint);
    }

    EditPageLogger.rendererDebug('参考线绘制完成', data: {
      'operation': 'guide_line_paint_complete',
    });
  }

  /// 计算两条参考线的交点
  ///
  /// 用于确定吸附指示器的位置
  static Offset _calculateIntersection(GuideLine line1, GuideLine line2) {
    final isLine1Vertical = line1.type == GuideLineType.horizontalCenter ||
        line1.type == GuideLineType.left ||
        line1.type == GuideLineType.right;
    final isLine2Vertical = line2.type == GuideLineType.horizontalCenter ||
        line2.type == GuideLineType.left ||
        line2.type == GuideLineType.right;

    if (isLine1Vertical && !isLine2Vertical) {
      // line1是垂直线，line2是水平线
      return Offset(line1.position, line2.position);
    } else if (!isLine1Vertical && isLine2Vertical) {
      // line1是水平线，line2是垂直线
      return Offset(line2.position, line1.position);
    } else {
      // 两条线平行，返回其中一条线上的点
      if (isLine1Vertical) {
        // 两条垂直线
        return Offset(line1.position, line1.elementBounds.center.dy);
      } else {
        // 两条水平线
        return Offset(line1.elementBounds.center.dx, line1.position);
      }
    }
  }

  /// 绘制虚线
  ///
  /// 使用间断绘制技术创建虚线效果
  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const double dashLength = 5.0;
    const double dashSpace = 3.0;

    final distance = (end - start).distance;
    const dashAndSpaceLength = dashLength + dashSpace;
    final dashCount = (distance / dashAndSpaceLength).floor();

    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (i * dashAndSpaceLength);
      final dashEnd = start + direction * (i * dashAndSpaceLength + dashLength);
      canvas.drawLine(dashStart, dashEnd, paint);
    }

    // 绘制最后一段（如果有剩余）
    final remainingDistance = distance % dashAndSpaceLength;
    if (remainingDistance > dashSpace) {
      final lastDashStart =
          start + direction * (dashCount * dashAndSpaceLength);
      final lastDashEnd = start +
          direction *
              math.min(
                dashCount * dashAndSpaceLength + dashLength,
                distance,
              );
      canvas.drawLine(lastDashStart, lastDashEnd, paint);
    }
  }

  /// 绘制单条参考线
  ///
  /// 使用虚线绘制，提供视觉指导但不造成干扰
  static void _drawGuideLine(
    Canvas canvas,
    Size canvasSize,
    GuideLine guideLine,
    Paint paint,
  ) {
    final isVertical = guideLine.type == GuideLineType.horizontalCenter ||
        guideLine.type == GuideLineType.left ||
        guideLine.type == GuideLineType.right;

    // 计算线条的起点和终点
    final Offset start = isVertical
        ? Offset(guideLine.position, 0)
        : Offset(0, guideLine.position);
    final Offset end = isVertical
        ? Offset(guideLine.position, canvasSize.height)
        : Offset(canvasSize.width, guideLine.position);

    // 绘制虚线
    _drawDashedLine(canvas, start, end, paint);
  }

  /// 绘制吸附指示器
  ///
  /// 在对齐点绘制圆点，明确显示吸附位置
  static void _drawSnapIndicator(
    Canvas canvas,
    AlignmentMatch alignment,
    Paint paint,
  ) {
    // 计算指示器位置
    final sourceLine = alignment.sourceLine;
    final targetLine = alignment.targetLine;

    Offset indicatorPosition;

    // 根据对齐类型确定指示器位置
    switch (alignment.alignmentType) {
      case AlignmentType.centerToCenter:
      case AlignmentType.centerToEdge:
      case AlignmentType.edgeToCenter:
      case AlignmentType.edgeToEdge:
        // 计算两条线的交点
        indicatorPosition = _calculateIntersection(sourceLine, targetLine);
        break;
    }

    // 绘制圆形指示器
    canvas.drawCircle(
        indicatorPosition, AlignmentConfig.snapIndicatorRadius, paint);

    // 绘制内部高亮点
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorPosition,
        AlignmentConfig.snapIndicatorRadius * 0.5, innerPaint);
  }
}
