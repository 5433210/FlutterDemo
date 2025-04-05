import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';

class RegionsPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final CoordinateTransformer transformer;
  final String? hoveredId;

  const RegionsPainter({
    required this.regions,
    required this.selectedIds,
    required this.transformer,
    this.hoveredId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 设置裁剪区域
    canvas.clipRect(Offset.zero & size);

    try {
      // 计算可见区域
      final viewportBounds = Rect.fromLTWH(0, 0, size.width, size.height);

      for (final region in regions) {
        try {
          // 转换坐标
          final viewportRect = transformer.imageRectToViewportRect(region.rect);

          // 检查是否在可见区域内
          if (!viewportRect.overlaps(viewportBounds)) {
            continue; // 跳过不可见的区域
          }

          final isSelected = selectedIds.contains(region.id);
          final isHovered = hoveredId == region.id;

          // 绘制选区
          _drawRegion(canvas, viewportRect, region, regions.indexOf(region) + 1,
              isSelected || isHovered);
        } catch (e, stack) {
          debugPrint('区域绘制失败: ${region.id}, error: $e\n$stack');
        }
      }
    } catch (e, stack) {
      debugPrint('RegionsPainter绘制失败: $e\n$stack');
    }
  }

  @override
  bool shouldRepaint(RegionsPainter oldDelegate) {
    return regions != oldDelegate.regions ||
        selectedIds != oldDelegate.selectedIds ||
        transformer != oldDelegate.transformer ||
        hoveredId != oldDelegate.hoveredId;
  }

  void _drawHandles(Canvas canvas, Rect rect, bool isActive) {
    final handlePositions = [
      rect.topLeft,
      rect.topCenter,
      rect.topRight,
      rect.centerRight,
      rect.bottomRight,
      rect.bottomCenter,
      rect.bottomLeft,
      rect.centerLeft,
    ];

    final handlePaths = handlePositions.map((pos) {
      return Path()
        ..addRect(Rect.fromCenter(
          center: pos,
          width: 8.0,
          height: 8.0,
        ));
    }).toList();

    // 批量绘制白色填充
    canvas.drawPath(
      Path.combine(
        PathOperation.union,
        handlePaths[0],
        Path.combine(
          PathOperation.union,
          handlePaths[1],
          Path.combine(
            PathOperation.union,
            handlePaths[2],
            Path.combine(
              PathOperation.union,
              handlePaths[3],
              Path.combine(
                PathOperation.union,
                handlePaths[4],
                Path.combine(
                  PathOperation.union,
                  handlePaths[5],
                  Path.combine(
                    PathOperation.union,
                    handlePaths[6],
                    handlePaths[7],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 批量绘制蓝色边框
    canvas.drawPath(
      Path.combine(
        PathOperation.union,
        handlePaths[0],
        Path.combine(
          PathOperation.union,
          handlePaths[1],
          Path.combine(
            PathOperation.union,
            handlePaths[2],
            Path.combine(
              PathOperation.union,
              handlePaths[3],
              Path.combine(
                PathOperation.union,
                handlePaths[4],
                Path.combine(
                  PathOperation.union,
                  handlePaths[5],
                  Path.combine(
                    PathOperation.union,
                    handlePaths[6],
                    handlePaths[7],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawRegionText(
    Canvas canvas,
    Rect viewportRect,
    CharacterRegion region,
    int index,
    bool isActive,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$index',
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (region.character.isNotEmpty)
            TextSpan(
              text: ' (${region.character})',
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    // 确保maxWidth为正数，且文本在视口内
    final maxWidth = (viewportRect.width - 8).clamp(0.0, double.infinity);
    textPainter.layout(maxWidth: maxWidth);

    final textOffset = viewportRect.topLeft.translate(4, 4);
    textPainter.paint(canvas, textOffset);
  }

  Color _getRegionFillColor(bool isSelected, bool isHovered) {
    if (isSelected) {
      return Colors.blue.withOpacity(0.2);
    } else if (isHovered) {
      return Colors.blue.withOpacity(0.1);
    } else {
      return Colors.green.withOpacity(0.05);
    }
  }

  void _drawRegion(
    Canvas canvas,
    Rect viewportRect,
    CharacterRegion region,
    int index,
    bool isActive,
  ) {
    // 绘制选区填充
    canvas.drawRect(
      viewportRect,
      Paint()
        ..color = _getRegionFillColor(isActive, false)
        ..style = PaintingStyle.fill,
    );

    // 绘制选区边框
    final borderPaint = Paint()
      ..color = isActive ? Colors.blue : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.0 : 1.5;

    // 如果区域有旋转，绘制旋转后的边框
    if (region.rotation != 0) {
      final center = viewportRect.center;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(region.rotation);
      canvas.translate(-center.dx, -center.dy);

      // 绘制旋转后的矩形
      canvas.drawRect(viewportRect, borderPaint);

      canvas.restore();
    } else {
      // 绘制普通矩形
      canvas.drawRect(viewportRect, borderPaint);
    }

    // 计算并显示文本
    _drawRegionText(
      canvas,
      viewportRect,
      region,
      index,
      isActive,
    );

    // 绘制控制点
    if (isActive) {
      _drawHandles(canvas, viewportRect, isActive);
    }
  }
}
