import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../canvas_rendering_engine.dart';

/// 数学函数
double cos(double radians) => math.cos(radians);

double sin(double radians) => math.sin(radians);

/// 形状元素专用渲染器
class ShapeElementRenderer extends ElementRenderer {
  @override
  void render(Canvas canvas, ElementData element) {
    final shapeType = element.properties['shapeType'] as String? ?? 'rectangle';

    final paint = _createPaint(element);
    final strokePaint = _createStrokePaint(element);

    switch (shapeType) {
      case 'rectangle':
        _renderRectangle(canvas, element, paint, strokePaint);
        break;
      case 'circle':
        _renderCircle(canvas, element, paint, strokePaint);
        break;
      case 'ellipse':
        _renderEllipse(canvas, element, paint, strokePaint);
        break;
      case 'roundedRectangle':
        _renderRoundedRectangle(canvas, element, paint, strokePaint);
        break;
      case 'triangle':
        _renderTriangle(canvas, element, paint, strokePaint);
        break;
      case 'polygon':
        _renderPolygon(canvas, element, paint, strokePaint);
        break;
      default:
        _renderRectangle(canvas, element, paint, strokePaint);
        break;
    }
  }

  /// 创建填充画笔
  Paint _createPaint(ElementData element) {
    final props = element.properties;
    final paint = Paint()..style = PaintingStyle.fill;

    final fillColor = props['fillColor'] as String?;
    if (fillColor != null) {
      paint.color = _parseColor(fillColor);
    } else {
      paint.color = Colors.transparent;
    }

    return paint;
  }

  /// 创建描边画笔
  Paint? _createStrokePaint(ElementData element) {
    final props = element.properties;
    final strokeColor = props['strokeColor'] as String?;
    final strokeWidth = (props['strokeWidth'] as num?)?.toDouble() ?? 0.0;

    if (strokeColor == null || strokeWidth <= 0) return null;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _parseColor(strokeColor)
      ..strokeWidth = strokeWidth;

    // 设置线条样式
    final strokeStyle = props['strokeStyle'] as String?;
    if (strokeStyle == 'dashed') {
      // TODO: 实现虚线样式
    }

    return paint;
  }

  /// 解析颜色
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    } catch (e) {
      // 解析失败，返回默认颜色
    }
    return Colors.black;
  }

  /// 渲染圆形
  void _renderCircle(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final center = Offset(element.bounds.width / 2, element.bounds.height / 2);
    final radius = element.bounds.width.min(element.bounds.height) / 2;

    if (fillPaint.color != Colors.transparent) {
      canvas.drawCircle(center, radius, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  /// 渲染椭圆
  void _renderEllipse(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final rect =
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height);

    if (fillPaint.color != Colors.transparent) {
      canvas.drawOval(rect, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawOval(rect, strokePaint);
    }
  }

  /// 渲染多边形
  void _renderPolygon(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final sides = (element.properties['sides'] as num?)?.toInt() ?? 6;
    if (sides < 3) return;

    final center = Offset(element.bounds.width / 2, element.bounds.height / 2);
    final radius = element.bounds.width.min(element.bounds.height) / 2;

    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * 3.14159) / sides - 3.14159 / 2; // 从顶部开始
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (fillPaint.color != Colors.transparent) {
      canvas.drawPath(path, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawPath(path, strokePaint);
    }
  }

  /// 渲染矩形
  void _renderRectangle(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final rect =
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height);

    if (fillPaint.color != Colors.transparent) {
      canvas.drawRect(rect, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawRect(rect, strokePaint);
    }
  }

  /// 渲染圆角矩形
  void _renderRoundedRectangle(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final radius =
        (element.properties['cornerRadius'] as num?)?.toDouble() ?? 8.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height),
      Radius.circular(radius),
    );

    if (fillPaint.color != Colors.transparent) {
      canvas.drawRRect(rrect, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  /// 渲染三角形
  void _renderTriangle(
      Canvas canvas, ElementData element, Paint fillPaint, Paint? strokePaint) {
    final width = element.bounds.width;
    final height = element.bounds.height;

    final path = Path()
      ..moveTo(width / 2, 0) // 顶点
      ..lineTo(0, height) // 左下角
      ..lineTo(width, height) // 右下角
      ..close();

    if (fillPaint.color != Colors.transparent) {
      canvas.drawPath(path, fillPaint);
    }

    if (strokePaint != null) {
      canvas.drawPath(path, strokePaint);
    }
  }
}

/// 辅助函数
extension NumExtension on num {
  double min(num other) => this < other ? toDouble() : other.toDouble();
}

// 添加math导入
