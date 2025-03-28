import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';

/// 调试覆盖层
/// 用于可视化显示坐标系统、网格和调试信息
class DebugOverlay extends CustomPainter {
  final CoordinateTransformer transformer;
  final bool showGrid;
  final bool showCoordinates;
  final bool showDetails;
  final bool showImageInfo;
  final bool showRegionCenter;
  final double gridSize;
  final double textScale;
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final double opacity;
  final Rect? lastCropRect;

  const DebugOverlay({
    required this.transformer,
    this.showGrid = true,
    this.showCoordinates = true,
    this.showDetails = true,
    this.showImageInfo = true,
    this.showRegionCenter = true,
    this.gridSize = 50.0,
    this.textScale = 1.0,
    this.regions = const [],
    this.selectedIds = const {},
    this.opacity = 0.5,
    this.lastCropRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      _drawImageBounds(canvas);
      if (showGrid) _drawGrid(canvas);
      if (showCoordinates) _drawAxis(canvas, size);
      if (showDetails) {
        _drawCoordinateSystems(canvas, size);
        for (final region in regions) {
          _drawRegionInfo(canvas, region);
        }
      }
      if (lastCropRect != null) _drawLastCropRect(canvas);
      if (showImageInfo) _drawViewInfo(canvas, size);
    } catch (e) {
      _drawError(canvas, e.toString());
    }
  }

  @override
  bool shouldRepaint(covariant DebugOverlay oldDelegate) {
    return transformer != oldDelegate.transformer ||
        showGrid != oldDelegate.showGrid ||
        showCoordinates != oldDelegate.showCoordinates ||
        showDetails != oldDelegate.showDetails ||
        showImageInfo != oldDelegate.showImageInfo ||
        showRegionCenter != oldDelegate.showRegionCenter ||
        gridSize != oldDelegate.gridSize ||
        textScale != oldDelegate.textScale ||
        regions != oldDelegate.regions ||
        selectedIds != oldDelegate.selectedIds ||
        opacity != oldDelegate.opacity ||
        lastCropRect != oldDelegate.lastCropRect;
  }

  void _drawAxis(Canvas canvas, Size size) {
    final displayRect = transformer.displayRect;
    final axisColor = Colors.red.withOpacity(opacity);

    // X轴（从原点向右）
    canvas.drawLine(
      Offset(displayRect.left, displayRect.top),
      Offset(displayRect.right, displayRect.top),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
    );

    // Y轴（从原点向下）
    canvas.drawLine(
      Offset(displayRect.left, displayRect.top),
      Offset(displayRect.left, displayRect.bottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
    );

    // 原点指示
    canvas.drawCircle(
      Offset(displayRect.left, displayRect.top),
      4,
      Paint()..color = axisColor,
    );

    if (showCoordinates) {
      _drawText(
        canvas,
        'O',
        Offset(displayRect.left - 15, displayRect.top - 15),
        color: axisColor,
        fontSize: 12 * textScale,
      );

      _drawText(
        canvas,
        'X →',
        Offset(displayRect.right + 5, displayRect.top),
        color: axisColor,
        fontSize: 12 * textScale,
      );

      _drawText(
        canvas,
        'Y ↓',
        Offset(displayRect.left - 20, displayRect.bottom),
        color: axisColor,
        fontSize: 12 * textScale,
      );
    }
  }

  void _drawCoordinateSystems(Canvas canvas, Size size) {
    final rectWidth = 160.0 * textScale;
    final rectHeight = 180.0 * textScale;
    final rect = Rect.fromLTWH(size.width - rectWidth - 10,
        size.height - rectHeight - 10, rectWidth, rectHeight);

    // 背景
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // 边框
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final padding = 8.0 * textScale;
    _drawText(
      canvas,
      '坐标系统说明 (左上角为原点)：\n'
      '1. 视口坐标：相对于组件左上角\n'
      '2. 视图坐标：相对于图像左上角\n'
      '\n'
      '坐标转换：\n'
      '视口 → 视图: (p - o) / s\n'
      '视图 → 视口: p * s + o\n'
      '其中: p=点, o=偏移, s=缩放',
      Offset(rect.left + padding, rect.top + padding),
      color: Colors.black.withOpacity(0.8),
      fontSize: 11 * textScale,
      bgColor: Colors.white.withOpacity(0.8),
      padding: EdgeInsets.all(padding),
    );
  }

  void _drawError(Canvas canvas, String error) {
    _drawText(
      canvas,
      '绘制错误: $error',
      const Offset(10, 10),
      color: Colors.red,
      fontSize: 14 * textScale,
      bgColor: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.all(4),
    );
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final lines = transformer.calculateGridLines(gridSize);
    for (int i = 0; i < lines.length; i += 2) {
      canvas.drawLine(lines[i], lines[i + 1], paint);
    }
  }

  void _drawImageBounds(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final displayRect = transformer.displayRect;
    canvas.drawRect(displayRect, paint);
  }

  void _drawLastCropRect(Canvas canvas) {
    if (lastCropRect == null) return;
    final viewportRect = transformer.imageRectToViewportRect(lastCropRect!);
    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = Colors.red.withOpacity(opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawRegionInfo(Canvas canvas, CharacterRegion region) {
    final isSelected = selectedIds.contains(region.id);
    final viewportRect = transformer.imageRectToViewportRect(region.rect);
    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = (isSelected ? Colors.blue : Colors.green).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = Colors.black,
    double fontSize = 12,
    TextAlign alignment = TextAlign.left,
    Color? bgColor,
    EdgeInsets? padding,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          shadows: bgColor == null
              ? [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.white.withOpacity(opacity * 0.8),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignment,
    );

    textPainter.layout();

    switch (alignment) {
      case TextAlign.right:
        position = position.translate(-textPainter.width, -textPainter.height);
        break;
      case TextAlign.center:
        position = position.translate(-textPainter.width / 2, 0);
        break;
      default:
        break;
    }

    if (bgColor != null && padding != null) {
      final rect = Rect.fromLTWH(
        position.dx - padding.left,
        position.dy - padding.top,
        textPainter.width + padding.horizontal,
        textPainter.height + padding.vertical,
      );
      canvas.drawRect(
        rect,
        Paint()..color = bgColor,
      );
    }

    textPainter.paint(canvas, position);
  }

  void _drawViewInfo(Canvas canvas, Size size) {
    final scale = transformer.currentScale;
    final baseScale = transformer.baseScale;
    final offset = transformer.currentOffset;
    final imageSize = transformer.imageSize;
    final viewportSize = transformer.viewportSize;
    final displayRect = transformer.displayRect;

    final info = [
      '图像信息',
      ' - 原始尺寸: ${imageSize.width.toInt()}x${imageSize.height.toInt()}px',
      ' - 视口尺寸: ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}px',
      ' - 显示位置: (${displayRect.left.toInt()},${displayRect.top.toInt()})',
      ' - 显示尺寸: ${displayRect.width.toInt()}x${displayRect.height.toInt()}px',
      '缩放比例',
      ' - 基础比例: ${(baseScale * 100).toInt()}%',
      ' - 当前比例: ${(scale * 100).toInt()}%',
      ' - 实际偏移: (${offset.dx.toStringAsFixed(2)}, ${offset.dy.toStringAsFixed(2)})',
      '选中区域',
      ' - 区域总数: ${regions.length}',
      ' - 选中数量: ${selectedIds.length}',
    ].join('\n');

    _drawText(
      canvas,
      info,
      const Offset(10, 10),
      color: Colors.black.withOpacity(opacity),
      fontSize: 10 * textScale,
      bgColor: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.all(4),
    );
  }
}
