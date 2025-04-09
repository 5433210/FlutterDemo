import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/character_region_state.dart';
import '../../../presentation/providers/character/tool_mode_provider.dart';
import '../../../utils/coordinate_transformer.dart';
import 'regions_state_utils.dart';

class RegionsPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final CoordinateTransformer transformer;
  final String? hoveredId;
  final String? adjustingRegionId; // 当前正在调整的区域ID
  final Tool currentTool; // 当前工具模式
  final bool isAdjusting; // 是否处于调整状态

  const RegionsPainter({
    required this.regions,
    required this.transformer,
    this.hoveredId,
    this.adjustingRegionId, // 接收调整中的区域ID
    required this.currentTool, // 当前工具模式
    this.isAdjusting = false, // 是否处于调整状态
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 设置裁剪区域
    canvas.clipRect(Offset.zero & size);

    try {
      // 计算可见区域
      final viewportBounds = Rect.fromLTWH(0, 0, size.width, size.height);

      for (final region in regions) {
        // 如果区域正在被其他组件调整，则跳过绘制
        if (region.id == adjustingRegionId) {
          continue;
        }

        try {
          // 转换坐标
          final viewportRect = transformer.imageRectToViewportRect(region.rect);

          // 检查是否在可见区域内
          if (!viewportRect.overlaps(viewportBounds)) {
            continue; // 跳过不可见的区域
          }

          // 确定区域状态 - using region.isSelected property
          final isSelected =
              region.isSelected; // Use object property instead of selectedIds
          final isHovered = region.id == hoveredId;
          final isRegionAdjusting =
              isAdjusting && region.id == adjustingRegionId;
          final isSaved =
              !region.isModified; // Use object property instead of modifiedIds

          // 获取区域状态
          final regionState = RegionStateUtils.getRegionState(
            currentTool: currentTool,
            isSelected: isSelected,
            isAdjusting: isRegionAdjusting,
          );

          // 绘制选区
          _drawRegion(
            canvas,
            viewportRect,
            region,
            regions.indexOf(region) + 1,
            regionState,
            isSelected,
            isHovered,
            isSaved,
          );
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
    return oldDelegate.regions != regions ||
        oldDelegate.transformer != transformer ||
        oldDelegate.hoveredId != hoveredId ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.adjustingRegionId != adjustingRegionId ||
        oldDelegate.isAdjusting != isAdjusting;
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

  void _drawRegion(
    Canvas canvas,
    Rect viewportRect,
    CharacterRegion region,
    int index,
    CharacterRegionState regionState,
    bool isSelected,
    bool isHovered,
    bool isSaved,
  ) {
    // 使用RegionStateUtils获取颜色
    final Color borderColor = RegionStateUtils.getBorderColor(
      state: regionState,
      isSaved: isSaved,
      isHovered: isHovered,
    );

    final Color fillColor = RegionStateUtils.getFillColor(
      state: regionState,
      isSaved: isSaved,
      isHovered: isHovered,
    );

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;

    // 如果区域有旋转，需要应用旋转变换
    if (region.rotation != 0) {
      final center = viewportRect.center;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(region.rotation);
      canvas.translate(-center.dx, -center.dy);

      // 绘制所有元素并应用旋转
      // 1. 绘制填充
      canvas.drawRect(viewportRect, fillPaint);

      // 2. 绘制边框
      canvas.drawRect(viewportRect, borderPaint);

      // 3. 绘制文字
      _drawRegionText(
          canvas, viewportRect, region, index, isSelected, borderColor);

      // 4. 如果处于Select模式并且是选中状态，绘制控制点
      if (isSelected && currentTool == Tool.select) {
        _drawHandles(canvas, viewportRect, true);
      }

      canvas.restore();
    } else {
      // 无旋转 - 直接绘制
      // 1. 绘制填充
      canvas.drawRect(viewportRect, fillPaint);

      // 2. 绘制边框
      canvas.drawRect(viewportRect, borderPaint);

      // 3. 绘制文字
      _drawRegionText(
          canvas, viewportRect, region, index, isSelected, borderColor);

      // 4. 如果处于Select模式并且是选中状态，绘制控制点
      if (isSelected && currentTool == Tool.select) {
        _drawHandles(canvas, viewportRect, true);
      }
    }
  }

  void _drawRegionText(
    Canvas canvas,
    Rect viewportRect,
    CharacterRegion region,
    int index,
    bool isSelected,
    Color textColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: region.character.isNotEmpty ? region.character : '$index',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        viewportRect.left + 5,
        viewportRect.top + 5,
      ),
    );
  }
}
