import 'dart:math' show cos, sin, sqrt;

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

    // 默认画笔
    final defaultPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final defaultDashPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final defaultLabelStyle = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final labelBackground = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // 绘制所有参考线
    for (final guideline in guidelines) {
      // 使用参考线自己的颜色和线宽（如果已定义）
      final useGuidelineColor = guideline.color != const Color(0xFF4CAF50); // 如果不是默认绿色，则使用自定义颜色
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
          labelBackground
        );
      } else if (guideline.direction == AlignmentDirection.vertical) {
        _drawVerticalGuideline(
          canvas, 
          size, 
          guideline, 
          dashLine ? guidelineDashPaint : guidelinePaint, 
          guidelineLabelStyle, 
          labelBackground
        );
      }
      
      // 禁用特殊中心线样式，全部使用参考线自己的颜色
      // 仅为动态参考线，取消中心线特殊高亮效果
      if (false && (guideline.type == GuidelineType.horizontalCenterLine || 
          guideline.type == GuidelineType.verticalCenterLine)) {
        _drawCenterlineHighlight(canvas, size, guideline, guidelinePaint, guidelineLabelStyle, labelBackground);
      }
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

  /// 绘制中心线高亮
  void _drawCenterlineHighlight(
    Canvas canvas,
    Size size,
    Guideline guideline,
    Paint paint,
    TextStyle labelStyle,
    Paint labelBackground,
  ) {
    // 中心线使用更醒目的样式
    final centerPaint = Paint()
      ..color = Colors.blue // 中心线使用蓝色
      ..strokeWidth = strokeWidth * 1.5 // 加粗
      ..style = PaintingStyle.stroke;

    if (guideline.type == GuidelineType.horizontalCenterLine) {
      // 水平中心线
      final y = guideline.position;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        centerPaint,
      );
      
      // 在两端绘制箭头
      _drawArrow(canvas, Offset(10, y), Offset(30, y), centerPaint);
      _drawArrow(canvas, Offset(size.width - 10, y), Offset(size.width - 30, y), centerPaint);
      
    } else if (guideline.type == GuidelineType.verticalCenterLine) {
      // 垂直中心线
      final x = guideline.position;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        centerPaint,
      );
      
      // 在两端绘制箭头
      _drawArrow(canvas, Offset(x, 10), Offset(x, 30), centerPaint);
      _drawArrow(canvas, Offset(x, size.height - 10), Offset(x, size.height - 30), centerPaint);
    }
  }

  /// 绘制虚线
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final dashWidth = 5.0;
    final dashSpace = 3.0;
    
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

  /// 绘制箭头
  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    canvas.drawLine(start, end, paint);
    
    // 计算箭头方向
    final angle = (end - start).direction;
    
    // 计算箭头两翼的点
    final arrowSize = 6.0;
    final arrowAngle1 = angle + 2.5;
    final arrowAngle2 = angle - 2.5;
    
    final arrowPoint1 = Offset(
      end.dx + arrowSize * cos(arrowAngle1),
      end.dy + arrowSize * sin(arrowAngle1),
    );
    
    final arrowPoint2 = Offset(
      end.dx + arrowSize * cos(arrowAngle2),
      end.dy + arrowSize * sin(arrowAngle2),
    );
    
    // 绘制箭头
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    
    canvas.drawPath(arrowPath, paint);
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
}