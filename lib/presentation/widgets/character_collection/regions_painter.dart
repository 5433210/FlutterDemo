import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/character_region_state.dart';
import '../../../infrastructure/logging/logger.dart';
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
  final List<String> selectedIds; // 添加选中的区域ID列表以支持多选
  // 添加创建中选区的支持
  final bool isSelecting; // 是否正在创建选区
  final Offset? selectionStart; // 选区创建起点
  final Offset? selectionEnd; // 选区创建终点
  // 添加控制点状态支持
  final String? pressedRegionId; // 被点压的选区ID
  final int? pressedHandleIndex; // 被点压的控制点索引
  final bool isHandlePressed; // 是否有控制点被点压

  const RegionsPainter({
    required this.regions,
    required this.transformer,
    this.hoveredId,
    this.adjustingRegionId, // 接收调整中的区域ID
    required this.currentTool, // 当前工具模式
    this.isAdjusting = false, // 是否处于调整状态
    this.selectedIds = const [], // 默认为空列表
    // 创建中选区的参数
    this.isSelecting = false,
    this.selectionStart,
    this.selectionEnd,
    // 控制点状态参数
    this.pressedRegionId,
    this.pressedHandleIndex,
    this.isHandlePressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 设置裁剪区域
    canvas.clipRect(Offset.zero & size);

    try {
      // 计算可见区域
      final viewportBounds = Rect.fromLTWH(0, 0, size.width, size.height);

      // 调试信息
      debugPrint(
          '🎨 RegionsPainter paint开始 - regions: ${regions.length}, isSelecting: $isSelecting');
      if (isSelecting && selectionStart != null && selectionEnd != null) {
        debugPrint(
            '📐 创建中选区: start=${selectionStart!.dx}, ${selectionStart!.dy}, end=${selectionEnd!.dx}, ${selectionEnd!.dy}');
      }

      for (final region in regions) {
        try {
          // 转换坐标
          final viewportRect = transformer.imageRectToViewportRect(region.rect);

          // 检查是否在可见区域内
          if (!viewportRect.overlaps(viewportBounds)) {
            continue; // 跳过不可见的区域
          } // 确定区域状态 - using region.isSelected property
          final isSelected =
              region.isSelected; // Use object property instead of selectedIds
          final isHovered = region.id == hoveredId;
          final isRegionAdjusting =
              isAdjusting && region.id == adjustingRegionId;
          final isSaved =
              !region.isModified; // Use object property instead of modifiedIds

          // 检查是否为多选状态
          final isMultiSelected = selectedIds.length > 1 && isSelected;

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
            isMultiSelected,
          );
        } catch (e, stack) {
          debugPrint('区域绘制失败: ${region.id}, error: $e\n$stack');
        }
      }

      // 绘制创建中的选区
      if (isSelecting && selectionStart != null && selectionEnd != null) {
        _drawCreatingRegion(canvas, selectionStart!, selectionEnd!);
      }
    } catch (e, stack) {
      debugPrint('RegionsPainter绘制失败: $e\n$stack');
    }
  }

  @override
  bool shouldRepaint(RegionsPainter oldDelegate) {
    // 🚀 优化：先检查最可能变化的属性，短路求值提升性能
    if (oldDelegate.hoveredId != hoveredId ||
        oldDelegate.adjustingRegionId != adjustingRegionId ||
        oldDelegate.isAdjusting != isAdjusting) {
      return true;
    }

    // 检查创建选区状态变化
    if (oldDelegate.isSelecting != isSelecting ||
        oldDelegate.selectionStart != selectionStart ||
        oldDelegate.selectionEnd != selectionEnd) {
      return true;
    }

    // 检查控制点状态变化
    if (oldDelegate.isHandlePressed != isHandlePressed ||
        oldDelegate.pressedRegionId != pressedRegionId ||
        oldDelegate.pressedHandleIndex != pressedHandleIndex) {
      return true;
    }

    // 检查选中状态变化
    if (oldDelegate.selectedIds.length != selectedIds.length ||
        !_listsEqual(oldDelegate.selectedIds, selectedIds)) {
      return true;
    }

    // 最后检查较复杂的对象比较
    return oldDelegate.regions != regions ||
        oldDelegate.transformer != transformer ||
        oldDelegate.currentTool != currentTool;
  }

  // 🚀 优化：添加高效的列表比较方法
  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _drawHandles(Canvas canvas, Rect rect, bool isActive, String regionId) {
    // 🔧 更新为角落标记式风格，与AdjustableRegionPainter保持一致，优化间距和样式

    // 绘制包围元素区域的细线框
    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.25) // 🔧 优化：更淡的透明度，更精致
      ..strokeWidth = 0.6 // 🔧 优化：更细的边框线，更精致
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, borderPaint);

    // 🔧 优化控制点参数：减少间距和大小，使其更精致
    const double markLength = 8.0; // 进一步减小标记长度，更加精致
    const double inset = 4.0; // 大幅减少内偏移量，控制点更靠近边框

    // 计算所有8个控制点位置（在元素内部但更靠近边缘）
    final controlPoints = [
      Offset(rect.left + inset, rect.top + inset), // 左上角
      Offset(rect.center.dx, rect.top + inset), // 上中
      Offset(rect.right - inset, rect.top + inset), // 右上角
      Offset(rect.right - inset, rect.center.dy), // 右中
      Offset(rect.right - inset, rect.bottom - inset), // 右下角
      Offset(rect.center.dx, rect.bottom - inset), // 下中
      Offset(rect.left + inset, rect.bottom - inset), // 左下角
      Offset(rect.left + inset, rect.center.dy), // 左中
    ];

    // 为每个控制点位置绘制L形或T形标记
    for (int i = 0; i < controlPoints.length; i++) {
      // 判断此控制点是否被点压
      final isPressed = isHandlePressed &&
          pressedRegionId == regionId &&
          pressedHandleIndex == i;

      final markPaint = isPressed
          ? (Paint()
            ..color = Colors.orange.shade600 // 优化按下时的颜色
            ..strokeWidth = 1.0 // 🔧 优化：减细按下状态线宽，更精致
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round) // 🔧 圆角端点，更精致
          : (Paint()
            ..color = Colors.blue.withValues(alpha: 0.6) // 🔧 适度提高透明度
            ..strokeWidth = 1.0 // 🔧 优化：进一步减细线条，更精致
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round); // 🔧 圆角端点，更精致

      _drawControlPointMark(canvas, markPaint, controlPoints[i], i, markLength);
    }

    AppLogger.debug('🎨 _drawHandles 绘制角落标记式控制点', data: {
      'regionId': regionId,
      'isHandlePressed': isHandlePressed,
      'pressedRegionId': pressedRegionId,
      'pressedHandleIndex': pressedHandleIndex,
      'style': 'corner_marks',
    });
  }

  void _drawControlPointMark(Canvas canvas, Paint paint, Offset controlPoint,
      int index, double markLength) {
    // 根据控制点位置确定L形或T形标记的方向
    switch (index) {
      case 0: // 左上角 - L形开口向右下
        canvas.drawLine(
            controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 1: // 上中 - T形向下
        canvas.drawLine(controlPoint.translate(-markLength / 2, 0),
            controlPoint.translate(markLength / 2, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 2: // 右上角 - L形开口向左下
        canvas.drawLine(
            controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 3: // 右中 - T形向左
        canvas.drawLine(
            controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(controlPoint.translate(0, -markLength / 2),
            controlPoint.translate(0, markLength / 2), paint);
        break;
      case 4: // 右下角 - L形开口向左上
        canvas.drawLine(
            controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 5: // 下中 - T形向上
        canvas.drawLine(controlPoint.translate(-markLength / 2, 0),
            controlPoint.translate(markLength / 2, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 6: // 左下角 - L形开口向右上
        canvas.drawLine(
            controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(
            controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 7: // 左中 - T形向右
        canvas.drawLine(
            controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(controlPoint.translate(0, -markLength / 2),
            controlPoint.translate(0, markLength / 2), paint);
        break;
    }
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
    bool isMultiSelected,
  ) {
    // 使用RegionStateUtils获取颜色和边框宽度
    final Color borderColor = RegionStateUtils.getBorderColor(
      state: regionState,
      isSaved: isSaved,
      isHovered: isHovered,
      isMultiSelected: isMultiSelected,
    );

    final Color fillColor = RegionStateUtils.getFillColor(
      state: regionState,
      isSaved: isSaved,
      isHovered: isHovered,
      isMultiSelected: isMultiSelected,
    );

    final double borderWidth = RegionStateUtils.getBorderWidth(
      state: regionState,
      isMultiSelected: isMultiSelected,
    );

    // 🔧 优化填充和边框样式，增强精致感
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round // 圆角端点，更精致
      ..strokeJoin = StrokeJoin.round; // 圆角连接，更精致

    // 🔧 为选中状态添加精致的光晕效果
    Paint? glowPaint;
    if (isSelected || isMultiSelected) {
      glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 0.5; // 🔧 优化：减小光晕宽度，更精致
    }

    // 🔧 为多选状态添加额外的强调边框
    Paint? emphasisPaint;
    if (isMultiSelected) {
      emphasisPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 0.0 // 🔧 优化：减小强调边框宽度
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }

    // 如果区域有旋转，需要应用旋转变换
    if (region.rotation != 0) {
      final center = viewportRect.center;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(region.rotation);
      canvas.translate(-center.dx, -center.dy);

      // 绘制所有元素并应用旋转
      // 1. 绘制光晕（如果存在）
      if (glowPaint != null) {
        canvas.drawRect(viewportRect, glowPaint);
      }

      // 2. 绘制填充
      canvas.drawRect(viewportRect, fillPaint);

      // 3. 绘制强调边框（多选状态）
      if (emphasisPaint != null) {
        canvas.drawRect(viewportRect, emphasisPaint);
      }

      // 4. 绘制主边框
      canvas.drawRect(viewportRect, borderPaint);

      // 5. 绘制文字
      _drawRegionText(
          canvas, viewportRect, region, index, isSelected, borderColor);

      // 6. 如果处于调整状态，绘制控制点
      if (regionState == CharacterRegionState.adjusting) {
        _drawHandles(canvas, viewportRect, true, region.id);
      }

      canvas.restore();
    } else {
      // 无旋转 - 直接绘制
      // 1. 绘制光晕（如果存在）
      if (glowPaint != null) {
        canvas.drawRect(viewportRect, glowPaint);
      }

      // 2. 绘制填充
      canvas.drawRect(viewportRect, fillPaint);

      // 3. 绘制强调边框（多选状态）
      if (emphasisPaint != null) {
        canvas.drawRect(viewportRect, emphasisPaint);
      }

      // 4. 绘制主边框
      canvas.drawRect(viewportRect, borderPaint);

      // 5. 绘制文字
      _drawRegionText(
          canvas, viewportRect, region, index, isSelected, borderColor);

      // 6. 如果处于调整状态，绘制控制点
      if (regionState == CharacterRegionState.adjusting) {
        _drawHandles(canvas, viewportRect, true, region.id);
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

  /// 绘制创建中的选区
  void _drawCreatingRegion(Canvas canvas, Offset start, Offset end) {
    // 计算选区矩形
    final rect = Rect.fromPoints(start, end);

    debugPrint('🎨 _drawCreatingRegion 绘制创建中选区');
    debugPrint(
        '📐 选区矩形: ${rect.left}, ${rect.top}, ${rect.width}x${rect.height}');

    // 🔧 优化创建中选区的样式：更精致的虚线边框和填充
    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 // 🔧 优化：减细边框线条
      ..strokeCap = StrokeCap.round; // 圆角端点

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.08) // 更淡的填充
      ..style = PaintingStyle.fill;

    // 🔧 添加光晕效果
    final glowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // 🔧 优化：减小光晕宽度

    // 1. 绘制光晕
    canvas.drawRect(rect, glowPaint);

    // 2. 绘制填充
    canvas.drawRect(rect, fillPaint);

    // 3. 绘制精致的虚线边框
    _drawDashedRect(canvas, rect, borderPaint);

    debugPrint('✅ _drawCreatingRegion 绘制完成');
  }

  /// 绘制虚线矩形
  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    // 🔧 优化虚线参数，使其更精致
    const dashWidth = 6.0; // 稍长的实线段
    const dashSpace = 4.0; // 稍短的空隙

    // 绘制上边
    _drawDashedLine(
        canvas, rect.topLeft, rect.topRight, paint, dashWidth, dashSpace);
    // 绘制右边
    _drawDashedLine(
        canvas, rect.topRight, rect.bottomRight, paint, dashWidth, dashSpace);
    // 绘制下边
    _drawDashedLine(
        canvas, rect.bottomRight, rect.bottomLeft, paint, dashWidth, dashSpace);
    // 绘制左边
    _drawDashedLine(
        canvas, rect.bottomLeft, rect.topLeft, paint, dashWidth, dashSpace);
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashWidth, double dashSpace) {
    final distance = (end - start).distance;
    final unitVector = (end - start) / distance;

    double currentDistance = 0.0;
    bool drawing = true;

    // 🔧 优化虚线绘制，确保线条平滑
    while (currentDistance < distance) {
      final segmentLength = drawing ? dashWidth : dashSpace;
      final nextDistance =
          (currentDistance + segmentLength).clamp(0.0, distance);

      if (drawing) {
        final segmentStart = start + unitVector * currentDistance;
        final segmentEnd = start + unitVector * nextDistance;
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance = nextDistance;
      drawing = !drawing;
    }
  }
}
