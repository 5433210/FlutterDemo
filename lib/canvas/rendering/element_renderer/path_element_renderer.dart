// No longer needed: import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';
import '../rendering_engine.dart';

/// 路径元素专用渲染器
///
/// 为路径元素提供高性能渲染，支持复杂路径绘制和编辑
/// 包括贝塞尔曲线、平滑曲线和多段线段
class PathElementRenderer {
  static const String rendererType = 'path';

  final CanvasStateManager stateManager;

  // 路径缓存
  final Map<String, Path> _pathCache = {};

  PathElementRenderer(this.stateManager);

  /// 清理资源
  void dispose() {
    _pathCache.clear();
  }

  /// 预加载路径资源
  Future<void> preloadResources(ElementData element) async {
    // 解析并缓存路径数据
    final pathData = element.properties['pathData'] as String?;
    if (pathData != null && pathData.isNotEmpty) {
      _getPath(element.id, pathData, element.bounds);
    }
  }

  /// 渲染路径元素到画布
  void renderElement(
      Canvas canvas, ElementData element, RenderingContext context) {
    if (!element.visible) return;

    final rect = element.bounds;
    final pathData = element.properties['pathData'] as String?;
    final fillColor = _parseColor(
        element.properties['fillColor'] as String? ?? 'transparent');
    final strokeColor =
        _parseColor(element.properties['strokeColor'] as String? ?? '#000000');
    final strokeWidth = element.properties['strokeWidth'] as double? ?? 1.0;
    final dashPattern = _parseDashPattern(element.properties['dashPattern']);

    // 应用元素变换
    canvas.save();

    // 处理元素的变换矩阵
    if (element.transform != null) {
      canvas.transform(element.transform!);
    }

    // 获取或创建路径
    final path = _getPath(element.id, pathData, rect);

    // 如果没有有效路径数据，绘制简单线段作为占位符
    if (path == null) {
      _drawPlaceholderPath(canvas, rect, strokeColor, strokeWidth);
    } else {
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
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (dashPattern != null && dashPattern.isNotEmpty) {
          final dashPath = _createDashPath(path, dashPattern);
          canvas.drawPath(dashPath, strokePaint);
        } else {
          canvas.drawPath(path, strokePaint);
        }
      }
    }

    // 如果元素被选中，绘制选择指示器
    if (context.isSelected(element.id)) {
      _drawSelectionIndicator(canvas, rect, context);

      // 如果路径有效，绘制路径控制点
      if (path != null) {
        _drawPathControlPoints(canvas, path, context);
      }
    }

    canvas.restore();
  }

  /// 判断元素是否需要重绘
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    // 检查关键属性是否变化
    if (oldElement.visible != newElement.visible) return true;
    if (oldElement.transform != newElement.transform) return true;

    final oldPathData = oldElement.properties['pathData'] as String?;
    final newPathData = newElement.properties['pathData'] as String?;
    if (oldPathData != newPathData) {
      // 路径数据变化，需要更新缓存
      _pathCache.remove(newElement.id);
      return true;
    }

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

  /// 创建虚线路径
  Path _createDashPath(Path source, List<double> dashPattern) {
    final dashPath = Path();

    // 计算路径长度
    final pathMetrics = source.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      final dashSum = dashPattern.reduce((a, b) => a + b);

      // 绘制虚线
      while (distance < pathMetric.length) {
        final int dashIndex = (distance ~/ dashSum) % dashPattern.length;
        final double dashLength = dashPattern[dashIndex];
        final double nextDistance = distance + dashLength;

        if (draw) {
          final extractPath = pathMetric.extractPath(
            distance,
            nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
          );
          dashPath.addPath(extractPath, Offset.zero);
        }

        distance = nextDistance;
        draw = !draw;
      }
    }

    return dashPath;
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

  /// 绘制路径控制点
  void _drawPathControlPoints(
      Canvas canvas, Path path, RenderingContext context) {
    const handleSize = 6.0;
    final handlePaint = Paint()
      ..color = context.selectionColor.withAlpha(200)
      ..style = PaintingStyle.fill;

    // 获取路径的关键点
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      // 每隔一定距离取一个点
      final pointInterval = metric.length / 10;
      for (double distance = 0;
          distance <= metric.length;
          distance += pointInterval) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final pointRect = Rect.fromCenter(
            center: tangent.position,
            width: handleSize,
            height: handleSize,
          );
          canvas.drawRect(pointRect, handlePaint);
        }
      }
    }
  }

  /// 绘制占位符路径
  void _drawPlaceholderPath(
      Canvas canvas, Rect rect, Color strokeColor, double strokeWidth) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 绘制简单的"N"形路径作为占位符
    final path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right, rect.top);

    canvas.drawPath(path, paint);
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

  /// 获取缓存的路径或创建新路径
  Path? _getPath(String elementId, String? pathData, Rect bounds) {
    if (pathData == null || pathData.isEmpty) {
      _pathCache.remove(elementId);
      return null;
    }

    if (_pathCache.containsKey(elementId)) {
      return _pathCache[elementId];
    }

    final path = _parseSvgPathData(pathData, bounds);
    _pathCache[elementId] = path;
    return path;
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

  /// 解析SVG路径数据
  Path _parseSvgPathData(String pathData, Rect bounds) {
    final path = Path();

    // 这里简化版的SVG路径解析
    // 实际实现应当完整支持SVG路径命令

    // Properly format the SVG path commands with spaces
    final commands = pathData
        .trim()
        .replaceAllMapped(
            RegExp(r'([a-zA-Z])'), (match) => ' ${match.group(1)} ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ');

    int i = 0;
    double x = 0;
    double y = 0;
    double x1 = 0;
    double y1 = 0;
    double x2 = 0;
    double y2 = 0;
    double? startX;
    double? startY;

    while (i < commands.length) {
      final cmd = commands[i];
      i++;

      switch (cmd) {
        case 'M': // 移动到
          x = double.parse(commands[i++]) * bounds.width;
          y = double.parse(commands[i++]) * bounds.height;
          path.moveTo(x, y);
          startX = x;
          startY = y;
          break;

        case 'm': // 相对移动
          x += double.parse(commands[i++]) * bounds.width;
          y += double.parse(commands[i++]) * bounds.height;
          path.moveTo(x, y);
          startX = x;
          startY = y;
          break;

        case 'L': // 直线到
          x = double.parse(commands[i++]) * bounds.width;
          y = double.parse(commands[i++]) * bounds.height;
          path.lineTo(x, y);
          break;

        case 'l': // 相对直线
          x += double.parse(commands[i++]) * bounds.width;
          y += double.parse(commands[i++]) * bounds.height;
          path.lineTo(x, y);
          break;

        case 'H': // 水平线
          x = double.parse(commands[i++]) * bounds.width;
          path.lineTo(x, y);
          break;

        case 'h': // 相对水平线
          x += double.parse(commands[i++]) * bounds.width;
          path.lineTo(x, y);
          break;

        case 'V': // 垂直线
          y = double.parse(commands[i++]) * bounds.height;
          path.lineTo(x, y);
          break;

        case 'v': // 相对垂直线
          y += double.parse(commands[i++]) * bounds.height;
          path.lineTo(x, y);
          break;

        case 'C': // 三次贝塞尔曲线
          x1 = double.parse(commands[i++]) * bounds.width;
          y1 = double.parse(commands[i++]) * bounds.height;
          x2 = double.parse(commands[i++]) * bounds.width;
          y2 = double.parse(commands[i++]) * bounds.height;
          x = double.parse(commands[i++]) * bounds.width;
          y = double.parse(commands[i++]) * bounds.height;
          path.cubicTo(x1, y1, x2, y2, x, y);
          break;

        case 'c': // 相对三次贝塞尔曲线
          x1 = x + double.parse(commands[i++]) * bounds.width;
          y1 = y + double.parse(commands[i++]) * bounds.height;
          x2 = x + double.parse(commands[i++]) * bounds.width;
          y2 = y + double.parse(commands[i++]) * bounds.height;
          x += double.parse(commands[i++]) * bounds.width;
          y += double.parse(commands[i++]) * bounds.height;
          path.cubicTo(x1, y1, x2, y2, x, y);
          break;

        case 'Q': // 二次贝塞尔曲线
          x1 = double.parse(commands[i++]) * bounds.width;
          y1 = double.parse(commands[i++]) * bounds.height;
          x = double.parse(commands[i++]) * bounds.width;
          y = double.parse(commands[i++]) * bounds.height;
          path.quadraticBezierTo(x1, y1, x, y);
          break;

        case 'q': // 相对二次贝塞尔曲线
          x1 = x + double.parse(commands[i++]) * bounds.width;
          y1 = y + double.parse(commands[i++]) * bounds.height;
          x += double.parse(commands[i++]) * bounds.width;
          y += double.parse(commands[i++]) * bounds.height;
          path.quadraticBezierTo(x1, y1, x, y);
          break;

        case 'Z': // 闭合路径
        case 'z':
          if (startX != null && startY != null) {
            path.close();
          }
          break;

        default:
          // 跳过未知命令
          break;
      }
    }

    return path;
  }
}
