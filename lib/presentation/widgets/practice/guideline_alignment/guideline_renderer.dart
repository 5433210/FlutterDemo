import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

import 'guideline_types.dart';

/// 参考线渲染器工厂类
/// 用于创建各种类型的参考线渲染器
class GuidelineRenderer {
  /// 创建参考线绘制器
  static CustomPainter createGuidelinePainter({
    required List<Guideline> guidelines,
    Color color = Colors.orange,
    double strokeWidth = 1.0,
    bool showLabels = true,
    bool dashLine = true,
    Rect? viewportBounds,
  }) {
    return _GuidelinePainter(
      guidelines: guidelines,
      color: color,
      strokeWidth: strokeWidth,
      showLabels: showLabels,
      dashLine: dashLine,
      viewportBounds: viewportBounds,
    );
  }
}

/// 参考线绘制器
class _GuidelinePainter extends CustomPainter {
  final List<Guideline> guidelines;
  final Color color;
  final double strokeWidth;
  final bool showLabels;
  final bool dashLine;
  final Rect? viewportBounds;

  _GuidelinePainter({
    required this.guidelines,
    required this.color,
    required this.strokeWidth,
    this.showLabels = true,
    this.dashLine = true,
    this.viewportBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (guidelines.isEmpty) {
      return;
    }

    final labelBackground = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // 绘制所有参考线
    for (final guideline in guidelines) {
      // 使用参考线自己的颜色和线宽（如果已定义）
      final useGuidelineColor =
          guideline.color != const Color(0xFF4CAF50); // 如果不是默认绿色，则使用自定义颜色
      final guidelinePaint = Paint()
        ..color = useGuidelineColor ? guideline.color : color
        ..strokeWidth = useGuidelineColor ? guideline.lineWeight : strokeWidth
        ..style = PaintingStyle.stroke;

      final guidelineDashPaint = Paint()
        ..color = useGuidelineColor ? guideline.color : color
        ..strokeWidth = useGuidelineColor ? guideline.lineWeight : strokeWidth
        ..style = PaintingStyle.stroke;

      final guidelineLabelStyle = TextStyle(
        color: useGuidelineColor ? guideline.color : color,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

      // 根据方向处理
      if (guideline.direction == AlignmentDirection.horizontal) {
        _drawHorizontalGuideline(
            canvas,
            size,
            guideline,
            dashLine ? guidelineDashPaint : guidelinePaint,
            guidelineLabelStyle,
            labelBackground);
      } else if (guideline.direction == AlignmentDirection.vertical) {
        _drawVerticalGuideline(
            canvas,
            size,
            guideline,
            dashLine ? guidelineDashPaint : guidelinePaint,
            guidelineLabelStyle,
            labelBackground);
      }
    }
  }

  @override
  bool shouldRepaint(_GuidelinePainter oldDelegate) {
    // 比较基本属性
    if (guidelines.length != oldDelegate.guidelines.length ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        showLabels != oldDelegate.showLabels ||
        dashLine != oldDelegate.dashLine) {
      return true;
    }

    // 比较参考线的具体内容（位置、颜色等）
    for (int i = 0; i < guidelines.length; i++) {
      final current = guidelines[i];
      final old = oldDelegate.guidelines[i];

      if (current.position != old.position ||
          current.direction != old.direction ||
          current.type != old.type ||
          current.color != old.color ||
          current.lineWeight != old.lineWeight ||
          current.id != old.id) {
        return true;
      }
    }

    return false;
  }

  /// 绘制虚线
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    var currentPosition = 0.0;
    for (var i = 0; i < dashCount; i++) {
      final startX = start.dx + unitDx * currentPosition;
      final startY = start.dy + unitDy * currentPosition;
      currentPosition += dashWidth;
      final endX = start.dx + unitDx * currentPosition;
      final endY = start.dy + unitDy * currentPosition;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );

      currentPosition += dashSpace;
    }
  }

  /// 绘制水平参考线
  void _drawHorizontalGuideline(
    Canvas canvas,
    Size size,
    Guideline guideline,
    Paint paint,
    TextStyle labelStyle,
    Paint labelBackground,
  ) {
    final y = guideline.position;

    // 应用视口裁剪
    if (viewportBounds != null) {
      if (y < viewportBounds!.top || y > viewportBounds!.bottom) {
        return; // 参考线在可视区域外，跳过绘制
      }
    }

    if (dashLine) {
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 绘制标签
    if (showLabels) {
      // 创建标签文本
      String label;
      switch (guideline.type) {
        case GuidelineType.horizontalCenterLine:
          label = '中线';
          break;
        case GuidelineType.horizontalTopEdge:
          label = '上边 ${y.toStringAsFixed(0)}px';
          break;
        case GuidelineType.horizontalBottomEdge:
          label = '下边 ${y.toStringAsFixed(0)}px';
          break;
        default:
          label = '${y.toStringAsFixed(0)}px';
      }

      final textSpan = TextSpan(
        text: label,
        style: labelStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 绘制标签背景
      final labelRect = Rect.fromLTWH(
        8,
        y - textPainter.height / 2,
        textPainter.width + 8,
        textPainter.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(2)),
        labelBackground,
      );

      // 绘制标签文本
      textPainter.paint(
        canvas,
        Offset(12, y - textPainter.height / 2),
      );
    }
  }

  /// 绘制垂直参考线
  void _drawVerticalGuideline(
    Canvas canvas,
    Size size,
    Guideline guideline,
    Paint paint,
    TextStyle labelStyle,
    Paint labelBackground,
  ) {
    final x = guideline.position;

    // 应用视口裁剪
    if (viewportBounds != null) {
      if (x < viewportBounds!.left || x > viewportBounds!.right) {
        return; // 参考线在可视区域外，跳过绘制
      }
    }

    if (dashLine) {
      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制标签
    if (showLabels) {
      // 创建标签文本
      String label;
      switch (guideline.type) {
        case GuidelineType.verticalCenterLine:
          label = '中线';
          break;
        case GuidelineType.verticalLeftEdge:
          label = '左边 ${x.toStringAsFixed(0)}px';
          break;
        case GuidelineType.verticalRightEdge:
          label = '右边 ${x.toStringAsFixed(0)}px';
          break;
        default:
          label = '${x.toStringAsFixed(0)}px';
      }

      final textSpan = TextSpan(
        text: label,
        style: labelStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 绘制标签背景
      final labelRect = Rect.fromLTWH(
        x - textPainter.width / 2,
        8,
        textPainter.width + 8,
        textPainter.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(2)),
        labelBackground,
      );

      // 绘制标签文本
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2 + 4, 8),
      );
    }
  }
}
