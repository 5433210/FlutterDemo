import 'dart:ui' as ui;

// No longer needed: import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';
import '../rendering_engine.dart';

/// 形状元素专用渲染器
///
/// 为形状元素提供高性能渲染，支持各种基础几何图形
/// 包括矩形、圆形、椭圆、三角形等标准形状
class ShapeElementRenderer {
  static const String rendererType = 'shape';

  final CanvasStateManager stateManager;

  // 形状绘制缓存
  final Map<String, ui.Image> _shapeCache = {};

  ShapeElementRenderer(this.stateManager);

  double cos(double x) => _sinCache(x + 3.14159 / 2);

  /// 创建虚线路径
  Path dashLinePath(
    Path originalPath,
    List<double> dashPattern,
    double advance,
    double phase,
  ) {
    final Path dashPath = Path();

    // 计算路径长度
    final pathMetrics = originalPath.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      final dashSum = dashPattern.reduce((a, b) => a + b);
      final normalizedPhase = phase % dashSum;

      // 初始偏移
      distance = normalizedPhase;

      // 确定初始是否绘制
      int dashIndex = 0;
      double currentDash = dashPattern[dashIndex];

      while (distance > currentDash) {
        distance -= currentDash;
        dashIndex = (dashIndex + 1) % dashPattern.length;
        currentDash = dashPattern[dashIndex];
        draw = !draw;
      }

      // 绘制虚线
      while (distance < pathMetric.length) {
        final double currentDistance = distance;
        final double nextDistance = currentDistance + currentDash - distance;

        if (draw) {
          final extractPath = pathMetric.extractPath(
            currentDistance,
            nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
          );
          dashPath.addPath(extractPath, Offset.zero);
        }

        distance = nextDistance;
        draw = !draw;
        dashIndex = (dashIndex + 1) % dashPattern.length;
        currentDash = dashPattern[dashIndex];
      }
    }

    return dashPath;
  }

  /// 清理资源
  void dispose() {
    _shapeCache.forEach((_, image) => image.dispose());
    _shapeCache.clear();
  }

  /// 求两数最小值（避免导入math库）
  double min(double a, double b) => a < b ? a : b;

  /// 预加载形状资源
  Future<void> preloadResources(ElementData element) async {
    // 形状渲染不需要特殊预加载
    return;
  }

  /// 渲染形状元素到画布
  void renderElement(
      Canvas canvas, ElementData element, RenderingContext context) {
    if (!element.visible) return;

    final rect = element.bounds;
    final shapeType = element.properties['type'] as String? ?? 'rectangle';
    final fillColor = _parseColor(
        element.properties['fillColor'] as String? ?? 'transparent');
    final strokeColor =
        _parseColor(element.properties['strokeColor'] as String? ?? '#000000');
    final strokeWidth = element.properties['strokeWidth'] as double? ?? 1.0;
    final cornerRadius = element.properties['cornerRadius'] as double? ?? 0.0;
    final dashPattern = _parseDashPattern(element.properties['dashPattern']);

    // 应用元素变换
    canvas.save();

    // 处理元素的变换矩阵
    if (element.transform != null) {
      canvas.transform(element.transform!);
    }

    // 根据形状类型绘制不同图形
    switch (shapeType.toLowerCase()) {
      case 'rectangle':
        _drawRectangle(canvas, rect, fillColor, strokeColor, strokeWidth,
            cornerRadius, dashPattern);
        break;
      case 'circle':
        _drawCircle(
            canvas, rect, fillColor, strokeColor, strokeWidth, dashPattern);
        break;
      case 'ellipse':
        _drawEllipse(
            canvas, rect, fillColor, strokeColor, strokeWidth, dashPattern);
        break;
      case 'triangle':
        _drawTriangle(
            canvas, rect, fillColor, strokeColor, strokeWidth, dashPattern);
        break;
      case 'star':
        _drawStar(canvas, rect, fillColor, strokeColor, strokeWidth,
            element.properties['points'] as int? ?? 5, dashPattern);
        break;
      case 'polygon':
        _drawPolygon(canvas, rect, fillColor, strokeColor, strokeWidth,
            element.properties['sides'] as int? ?? 6, dashPattern);
        break;
      default:
        _drawRectangle(canvas, rect, fillColor, strokeColor, strokeWidth,
            cornerRadius, dashPattern);
    }

    // 如果元素被选中，绘制选择指示器
    if (context.isSelected(element.id)) {
      _drawSelectionIndicator(canvas, rect, context);
    }

    canvas.restore();
  }

  /// 判断元素是否需要重绘
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    // 检查关键属性是否变化
    if (oldElement.visible != newElement.visible) return true;
    if (oldElement.transform != newElement.transform) return true;

    final oldType = oldElement.properties['type'] as String? ?? 'rectangle';
    final newType = newElement.properties['type'] as String? ?? 'rectangle';
    if (oldType != newType) return true;

    final oldFillColor =
        oldElement.properties['fillColor'] as String? ?? 'transparent';
    final newFillColor =
        newElement.properties['fillColor'] as String? ?? 'transparent';
    if (oldFillColor != newFillColor) return true;

    final oldStrokeColor =
        oldElement.properties['strokeColor'] as String? ?? '#000000';
    final newStrokeColor =
        newElement.properties['strokeColor'] as String? ?? '#000000';
    if (oldStrokeColor != newStrokeColor) return true;

    final oldStrokeWidth =
        oldElement.properties['strokeWidth'] as double? ?? 1.0;
    final newStrokeWidth =
        newElement.properties['strokeWidth'] as double? ?? 1.0;
    if (oldStrokeWidth != newStrokeWidth) return true;

    // 其他属性的变化检查...

    return false;
  }

  /// 简单三角函数（避免导入math库）
  double sin(double x) => _sinCache(x);

  /// 绘制圆形
  void _drawCircle(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    List<double>? dashPattern,
  ) {
    final center = rect.center;
    final radius = min(rect.width, rect.height) / 2;

    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        final path = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radius));

        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawCircle(center, radius, strokePaint);
      }
    }
  }

  /// 绘制控制点
  void _drawControlHandles(Canvas canvas, Rect rect, RenderingContext context) {
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.fill;

    // 角控制点
    final handles = [
      Rect.fromCenter(
          center: rect.topLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.topRight, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomRight, width: handleSize, height: handleSize),
    ];

    // 边控制点
    handles.addAll([
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.top),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.right, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.bottom),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
    ]);

    for (var handle in handles) {
      canvas.drawRect(handle, handlePaint);
    }
  }

  /// 绘制椭圆
  void _drawEllipse(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    List<double>? dashPattern,
  ) {
    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawOval(rect, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        final path = Path()..addOval(rect);

        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawOval(rect, strokePaint);
      }
    }
  }

  /// 绘制多边形
  void _drawPolygon(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    int sides,
    List<double>? dashPattern,
  ) {
    final path = Path();
    final center = rect.center;
    final radius = min(rect.width, rect.height) / 2;

    final angleStep = (2 * 3.14159) / sides;

    path.moveTo(
      center.dx + radius * cos(0),
      center.dy + radius * sin(0),
    );

    for (int i = 1; i < sides; i++) {
      final angle = angleStep * i;

      path.lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }

    path.close();

    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  /// 绘制矩形
  void _drawRectangle(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    double cornerRadius,
    List<double>? dashPattern,
  ) {
    final path = Path();

    if (cornerRadius > 0) {
      path.addRRect(RRect.fromRectAndRadius(
        rect,
        Radius.circular(cornerRadius),
      ));
    } else {
      path.addRect(rect);
    }

    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        strokePaint.shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [strokeColor, strokeColor],
          [0, 1],
        );

        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  /// 绘制选择指示器
  void _drawSelectionIndicator(
      Canvas canvas, Rect rect, RenderingContext context) {
    final paint = Paint()
      ..color = context.selectionColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(rect, borderPaint);

    // 绘制控制点
    _drawControlHandles(canvas, rect, context);
  }

  /// 绘制星形
  void _drawStar(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    int points,
    List<double>? dashPattern,
  ) {
    final path = Path();
    final center = rect.center;
    final outerRadius = min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * 0.4;

    final angleStep = (2 * 3.14159) / (points * 2);

    path.moveTo(
      center.dx + outerRadius * cos(0),
      center.dy + outerRadius * sin(0),
    );

    for (int i = 1; i < points * 2; i++) {
      final radius = i.isOdd ? innerRadius : outerRadius;
      final angle = angleStep * i;

      path.lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }

    path.close();

    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  /// 绘制三角形
  void _drawTriangle(
    Canvas canvas,
    Rect rect,
    Color fillColor,
    Color strokeColor,
    double strokeWidth,
    List<double>? dashPattern,
  ) {
    final path = Path();

    path.moveTo(rect.left + rect.width / 2, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.close();

    // 填充
    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // 描边
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      if (dashPattern != null && dashPattern.isNotEmpty) {
        final dashPath = Path();
        const advance = 4.0;
        const phase = 0.0;

        dashPath.addPath(
          dashLinePath(path, dashPattern, advance, phase),
          Offset.zero,
        );

        canvas.drawPath(dashPath, strokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') {
      return Colors.transparent;
    }

    if (colorStr.startsWith('#')) {
      String hexColor = colorStr.replaceAll('#', '');

      if (hexColor.length == 3) {
        // 扩展3位色值为6位
        hexColor = hexColor.split('').map((e) => '$e$e').join('');
      }

      if (hexColor.length == 6) {
        // 添加不透明度
        hexColor = 'FF$hexColor';
      }

      return Color(int.parse(hexColor, radix: 16));
    }

    // 默认黑色
    return Colors.black;
  }

  /// 解析虚线模式
  List<double>? _parseDashPattern(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      return value.map((e) => e is num ? e.toDouble() : 0.0).toList();
    } else if (value is String) {
      return value
          .split(',')
          .map((e) => double.tryParse(e.trim()) ?? 0.0)
          .toList();
    }

    return null;
  }

  /// sin函数近似计算
  double _sinApprox(double x) {
    // 使用泰勒级数近似
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    return x - x3 / 6 + x5 / 120;
  }

  /// 简化版sin函数缓存计算
  double _sinCache(double x) {
    // 标准化到0-2π范围
    x = x % (2 * 3.14159);
    if (x < 0) x += 2 * 3.14159;

    // 简化的sin函数实现
    if (x < 3.14159) {
      if (x < 3.14159 / 2) {
        return _sinApprox(x);
      } else {
        return _sinApprox(3.14159 - x);
      }
    } else {
      if (x < 3 * 3.14159 / 2) {
        return -_sinApprox(x - 3.14159);
      } else {
        return -_sinApprox(2 * 3.14159 - x);
      }
    }
  }
}
