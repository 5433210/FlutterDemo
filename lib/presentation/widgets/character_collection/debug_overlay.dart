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
      // 1. 绘制图像边界
      _drawImageBounds(canvas);

      // 2. 绘制网格
      if (showGrid) {
        _drawGrid(canvas);
      }

      // 3. 绘制坐标轴
      if (showCoordinates) {
        _drawAxis(canvas, size);
      }

      // 4. 绘制坐标系示意图
      if (showDetails) {
        _drawCoordinateSystems(canvas, size);
      }

      // 5. 绘制区域信息
      if (showDetails) {
        for (final region in regions) {
          _drawRegionInfo(canvas, region);
        }
      }

      // 6. 绘制最近裁剪区域
      if (lastCropRect != null) {
        _drawLastCropRect(canvas);
      }

      // 7. 绘制图像信息
      if (showImageInfo) {
        _drawViewInfo(canvas, size);
      }
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
    // 新增：绘制中心点原点的坐标轴
    final viewportCenterX = size.width / 2;
    final viewportCenterY = size.height / 2;

    // 主坐标轴 - 中心点坐标系
    final axisPaint = Paint()
      ..color = Colors.purple.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // X轴
    canvas.drawLine(
      Offset(viewportCenterX - 300, viewportCenterY),
      Offset(viewportCenterX + 300, viewportCenterY),
      axisPaint,
    );

    // Y轴
    canvas.drawLine(
      Offset(viewportCenterX, viewportCenterY - 300),
      Offset(viewportCenterX, viewportCenterY + 300),
      axisPaint,
    );

    // 中心点
    canvas.drawCircle(
      Offset(viewportCenterX, viewportCenterY),
      5,
      Paint()..color = Colors.purple.withOpacity(opacity),
    );

    // 标注
    _drawText(
      canvas,
      'O (视口中心点)',
      Offset(viewportCenterX + 10, viewportCenterY + 10),
      color: Colors.purple.withOpacity(opacity),
      fontSize: 12 * textScale,
    );

    // 还绘制传统坐标轴以便比较
    final displayRect = transformer.displayRect;
    final axisColor = Colors.red.withOpacity(opacity);

    // 传统X轴
    canvas.drawLine(
      Offset(displayRect.left, displayRect.bottom),
      Offset(displayRect.right, displayRect.bottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
    );

    // 传统Y轴
    canvas.drawLine(
      Offset(displayRect.left, displayRect.top),
      Offset(displayRect.left, displayRect.bottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
    );

    if (showCoordinates) {
      _drawText(
        canvas,
        'X',
        Offset(displayRect.right + 10, displayRect.bottom),
        color: axisColor,
        fontSize: 12 * textScale,
      );
      _drawText(
        canvas,
        'Y',
        Offset(displayRect.left, displayRect.top - 20),
        color: axisColor,
        fontSize: 12 * textScale,
      );
    }
  }

  // 绘制坐标系示意图
  void _drawCoordinateSystems(Canvas canvas, Size size) {
    // 在右下角绘制坐标系示意图
    final rectWidth = 160.0 * textScale;
    final rectHeight = 250.0 * textScale; // 增加高度以容纳更多说明
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

    // 标题
    _drawText(
      canvas,
      '坐标系统 (统一使用视口中心点作为原点)',
      Offset(rect.left + 5, rect.top + 5),
      color: Colors.black.withOpacity(0.8),
      fontSize: 12 * textScale,
    );

    // 视口坐标系 (红色)
    final viewportRect = Rect.fromLTWH(
        rect.left + 10, rect.top + 25, rectWidth - 20, 40 * textScale);

    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // 添加中心点标记
    final viewportCenter = Offset(
      viewportRect.left + viewportRect.width / 2,
      viewportRect.top + viewportRect.height / 2,
    );

    // 绘制十字标记
    canvas.drawLine(
      Offset(viewportCenter.dx - 5, viewportCenter.dy),
      Offset(viewportCenter.dx + 5, viewportCenter.dy),
      Paint()..color = Colors.red,
    );
    canvas.drawLine(
      Offset(viewportCenter.dx, viewportCenter.dy - 5),
      Offset(viewportCenter.dx, viewportCenter.dy + 5),
      Paint()..color = Colors.red,
    );

    _drawText(
      canvas,
      '视口坐标系 (Viewport - 原点在视口中心)',
      Offset(viewportRect.left + 5, viewportRect.bottom + 5),
      color: Colors.red,
      fontSize: 10 * textScale,
    );

    // 视图坐标系 (蓝色)
    final viewRect = Rect.fromLTWH(
        rect.left + 25, rect.top + 90, rectWidth - 50, 25 * textScale);

    canvas.drawRect(
      viewRect,
      Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // 添加中心点标记
    final viewCenter = Offset(
      viewRect.left + viewRect.width / 2,
      viewRect.top + viewRect.height / 2,
    );

    // 绘制十字标记
    canvas.drawLine(
      Offset(viewCenter.dx - 5, viewCenter.dy),
      Offset(viewCenter.dx + 5, viewCenter.dy),
      Paint()..color = Colors.blue,
    );
    canvas.drawLine(
      Offset(viewCenter.dx, viewCenter.dy - 5),
      Offset(viewCenter.dx, viewCenter.dy + 5),
      Paint()..color = Colors.blue,
    );

    _drawText(
      canvas,
      '视图坐标系 (View - 原点也在视口中心)',
      Offset(viewRect.left, viewRect.bottom + 5),
      color: Colors.blue,
      fontSize: 10 * textScale,
    );

    // 坐标转换公式说明
    final formulaRect = Rect.fromLTWH(
        rect.left + 10, rect.top + 150, rectWidth - 20, 60 * textScale);

    canvas.drawRect(
      formulaRect,
      Paint()
        ..color = Colors.purple.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    _drawText(
      canvas,
      '坐标转换公式:\n'
      '视口 → 视图: (p-c-o)/s\n'
      '视图 → 视口: p*s+o+c\n'
      '其中: p=点, c=中心, o=偏移, s=缩放',
      Offset(formulaRect.left + 5, formulaRect.top + 5),
      color: Colors.purple,
      fontSize: 9 * textScale,
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

  // 绘制最近的裁剪区域
  void _drawLastCropRect(Canvas canvas) {
    // 确保lastCropRect不为空
    if (lastCropRect == null) return;

    // 转换为视口坐标
    final viewportRect = transformer.imageRectToViewportRect(lastCropRect!);

    // 绘制裁剪区域
    final paint = Paint()
      ..color = Colors.red.withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(viewportRect, paint);

    // 绘制区域信息
    _drawText(
      canvas,
      '最近裁剪: ${lastCropRect!.width.toInt()}x${lastCropRect!.height.toInt()} px',
      Offset(viewportRect.right + 5, viewportRect.top),
      color: Colors.red.withOpacity(opacity),
      fontSize: 12 * textScale,
      bgColor: Colors.white.withOpacity(0.7),
      padding: const EdgeInsets.all(4),
    );
  }

  void _drawRegionInfo(Canvas canvas, CharacterRegion region) {
    final isSelected = selectedIds.contains(region.id);
    // 使用新的坐标转换方法
    final viewportRect = transformer.imageRectToViewportRect(region.rect);

    // 绘制区域边框
    final paint = Paint()
      ..color = (isSelected ? Colors.blue : Colors.green).withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(viewportRect, paint);

    // 绘制区域信息
    if (showDetails) {
      final info = [
        '区域 ${region.id.substring(0, 6)}...',
        '位置: (${region.rect.left.toInt()}, ${region.rect.top.toInt()})',
        '大小: ${region.rect.width.toInt()}x${region.rect.height.toInt()} px',
        if (region.character.isNotEmpty) '字: ${region.character}',
        if (region.rotation != 0) '旋转: ${region.rotation}°',
      ].join('\n');

      _drawText(
        canvas,
        info,
        Offset(viewportRect.left, viewportRect.top - 60),
        color: (isSelected ? Colors.blue : Colors.green).withOpacity(opacity),
        fontSize: 10 * textScale,
        bgColor: Colors.white.withOpacity(0.8),
        padding: const EdgeInsets.all(4),
      );
    }

    // 绘制中心点
    if (showRegionCenter) {
      final center = Offset(
        viewportRect.left + viewportRect.width / 2,
        viewportRect.top + viewportRect.height / 2,
      );
      canvas.drawCircle(
        center,
        3,
        Paint()
          ..color =
              (isSelected ? Colors.blue : Colors.green).withOpacity(opacity),
      );
    }
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

    // 根据对齐方式调整位置
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

    // 绘制背景
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

    // 绘制文本
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
      // 改用当前可用的属性
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
