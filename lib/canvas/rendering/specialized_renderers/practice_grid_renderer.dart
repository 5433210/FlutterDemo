/// Canvas系统重构 - Phase 3: 练习编辑网格渲染器
///
/// 专门用于练习编辑页面的网格和引导线渲染
/// 职责：
/// 1. 渲染字帖编辑所需的网格系统
/// 2. 绘制引导线和对齐辅助
/// 3. 支持不同的字帖布局模式
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../element_renderer.dart';

/// 练习编辑网格渲染器
class PracticeGridRenderer extends ElementRenderer<ElementData> {
  bool _initialized = false;
  final Map<String, ui.Image> _gridCache = {};

  @override
  String get elementType => 'practice_grid';

  @override
  bool get isInitialized => _initialized;

  @override
  bool get supportsCaching => true;

  @override
  bool get supportsGpuAcceleration => false;

  @override
  bool canRender(ElementData element) {
    return element.type == 'practice_grid' || element.type == 'grid';
  }

  @override
  void clearCache([String? elementId]) {
    if (elementId != null) {
      _gridCache.remove(elementId);
    } else {
      _gridCache.clear();
    }
  }

  @override
  void dispose() {
    clearCache();
    _initialized = false;
  }

  @override
  int estimateRenderTime(ElementData element, RenderQuality quality) {
    final gridSize = element.properties['gridSize'] as double? ?? 30.0;
    final bounds = element.bounds;
    final cellCount = (bounds.width / gridSize) * (bounds.height / gridSize);

    // 基础渲染时间 + 网格单元数量影响
    int baseTime = 2;
    baseTime += (cellCount / 100).ceil();

    switch (quality) {
      case RenderQuality.low:
        return baseTime;
      case RenderQuality.normal:
        return (baseTime * 1.2).toInt();
      case RenderQuality.high:
        return (baseTime * 1.5).toInt();
    }
  }

  @override
  Rect getBounds(ElementData element, [Matrix4? transform]) {
    return element.bounds;
  }

  @override
  Path getHitTestPath(ElementData element, [Matrix4? transform]) {
    final path = Path();
    path.addRect(element.bounds);
    return path;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  @override
  Future<ui.Image?> prerender(
      ElementData element, RenderContext context) async {
    final cacheKey = _generateCacheKey(element);
    if (_gridCache.containsKey(cacheKey)) {
      return _gridCache[cacheKey];
    }

    // 预渲染网格到图像
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    _renderGridInternal(element, canvas, context.quality);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      element.bounds.width.toInt(),
      element.bounds.height.toInt(),
    );

    _gridCache[cacheKey] = image;
    picture.dispose();

    return image;
  }

  @override
  void render(ElementData element, RenderContext context) {
    final visible = element.properties['visible'] as bool? ?? true;
    if (!visible) return;

    // 如果有缓存的图像，直接绘制
    final cacheKey = _generateCacheKey(element);
    final cachedImage = _gridCache[cacheKey];

    if (cachedImage != null && context.cachePolicy != CachePolicy.none) {
      context.canvas.drawImage(
        cachedImage,
        element.bounds.topLeft,
        Paint(),
      );
      return;
    }

    // 否则直接渲染
    _renderGridInternal(element, context.canvas, context.quality);
  }

  @override
  void renderSelection(ElementData element, RenderContext context) {
    // 网格元素通常不需要选择状态渲染
    // 但可以在这里添加边框高亮
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    context.canvas.drawRect(element.bounds, paint);
  }

  @override
  void updateCache(ElementData element) {
    clearCache(element.id);
  }

  /// 绘制书法网格（米字格）
  void _drawCalligraphyGrid(
      Canvas canvas, Rect bounds, double gridSize, Paint paint) {
    final lightPaint = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth * 0.5;

    // 先绘制基础方形网格
    _drawSquareGrid(canvas, bounds, gridSize, paint);

    // 在每个方格中绘制米字格
    for (double x = bounds.left; x < bounds.right; x += gridSize) {
      for (double y = bounds.top; y < bounds.bottom; y += gridSize) {
        final cellBounds = Rect.fromLTWH(x, y, gridSize, gridSize);
        _drawMiziCell(canvas, cellBounds, lightPaint);
      }
    }
  }

  /// 绘制点状网格
  void _drawDotGrid(Canvas canvas, Rect bounds, double gridSize, Paint paint) {
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (double x = bounds.left; x <= bounds.right; x += gridSize) {
      for (double y = bounds.top; y <= bounds.bottom; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  /// 绘制网格
  void _drawGrid(
    Canvas canvas,
    Rect bounds,
    double gridSize,
    String gridType,
    Color gridColor,
    RenderQuality quality,
  ) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = quality == RenderQuality.high ? 0.5 : 1.0;

    switch (gridType) {
      case 'square':
        _drawSquareGrid(canvas, bounds, gridSize, paint);
        break;
      case 'dot':
        _drawDotGrid(canvas, bounds, gridSize, paint);
        break;
      case 'calligraphy':
        _drawCalligraphyGrid(canvas, bounds, gridSize, paint);
        break;
      default:
        _drawSquareGrid(canvas, bounds, gridSize, paint);
    }
  }

  /// 绘制引导线
  void _drawGuideLines(
    Canvas canvas,
    Rect bounds,
    double gridSize,
    Color guideLineColor,
    RenderQuality quality,
  ) {
    final paint = Paint()
      ..color = guideLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = quality == RenderQuality.high ? 1.0 : 1.5;

    // 绘制基线（每5个网格一条）
    for (double y = bounds.top; y <= bounds.bottom; y += gridSize * 5) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        paint,
      );
    }

    // 绘制边距线
    final margin = gridSize * 2;
    canvas.drawLine(
      Offset(bounds.left + margin, bounds.top),
      Offset(bounds.left + margin, bounds.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.right - margin, bounds.top),
      Offset(bounds.right - margin, bounds.bottom),
      paint,
    );
  }

  /// 绘制单个米字格单元
  void _drawMiziCell(Canvas canvas, Rect cellBounds, Paint paint) {
    final center = cellBounds.center;

    // 中间的十字线
    canvas.drawLine(
      Offset(cellBounds.left, center.dy),
      Offset(cellBounds.right, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, cellBounds.top),
      Offset(center.dx, cellBounds.bottom),
      paint,
    );

    // 对角线
    canvas.drawLine(
      cellBounds.topLeft,
      cellBounds.bottomRight,
      paint,
    );
    canvas.drawLine(
      cellBounds.topRight,
      cellBounds.bottomLeft,
      paint,
    );
  }

  /// 绘制方形网格
  void _drawSquareGrid(
      Canvas canvas, Rect bounds, double gridSize, Paint paint) {
    // 垂直线
    for (double x = bounds.left; x <= bounds.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, bounds.top),
        Offset(x, bounds.bottom),
        paint,
      );
    }

    // 水平线
    for (double y = bounds.top; y <= bounds.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        paint,
      );
    }
  }

  /// 生成缓存键
  String _generateCacheKey(ElementData element) {
    final props = element.properties;
    return '${element.id}_${element.bounds}_'
        '${props['gridSize']}_${props['gridType']}_'
        '${props['showGrid']}_${props['showGuideLines']}_'
        '${props['gridColor']}_${props['guideLineColor']}';
  }

  /// 解析颜色字符串
  Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') {
      return Colors.transparent;
    }

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
    return Colors.grey;
  }

  /// 内部网格渲染逻辑
  void _renderGridInternal(
      ElementData element, Canvas canvas, RenderQuality quality) {
    final bounds = element.bounds;
    final gridSize = element.properties['gridSize'] as double? ?? 30.0;
    final showGrid = element.properties['showGrid'] as bool? ?? true;
    final showGuideLines =
        element.properties['showGuideLines'] as bool? ?? true;
    final gridType = element.properties['gridType'] as String? ?? 'square';
    final gridColor = _parseColor(
      element.properties['gridColor'] as String? ?? '#E0E0E0',
    );
    final guideLineColor = _parseColor(
      element.properties['guideLineColor'] as String? ?? '#FFCDD2',
    );

    if (showGrid) {
      _drawGrid(canvas, bounds, gridSize, gridType, gridColor, quality);
    }

    if (showGuideLines) {
      _drawGuideLines(canvas, bounds, gridSize, guideLineColor, quality);
    }
  }
}
