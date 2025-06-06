import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/practice/drag_state_manager.dart';

/// 选中元素高亮组件
/// 为多选状态提供清晰的视觉反馈
/// 支持实时跟随元素的拖拽、缩放、旋转操作
class SelectedElementsHighlight extends StatelessWidget {
  final List<Map<String, dynamic>> elements;
  final Set<String> selectedElementIds;
  final double canvasScale;
  final Color primaryColor;
  final Color secondaryColor;
  
  /// 可选的拖拽状态管理器，用于获取实时状态
  final DragStateManager? dragStateManager;

  const SelectedElementsHighlight({
    super.key,
    required this.elements,
    required this.selectedElementIds,
    required this.canvasScale,
    required this.primaryColor,
    required this.secondaryColor,
    this.dragStateManager,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedElementIds.isEmpty) {
      return const SizedBox.shrink();
    }

    // 如果有拖拽状态管理器，监听其变化以实时更新
    if (dragStateManager != null) {
      return ListenableBuilder(
        listenable: dragStateManager!,
        builder: (context, child) {
          return _buildHighlightStack();
        },
      );
    } else {
      return _buildHighlightStack();
    }
  }

  /// 构建高亮栈
  Widget _buildHighlightStack() {
    return Stack(
      children: [
        // 只为选中的元素绘制高亮效果
        ...elements.where((element) {
          final elementId = element['id'] as String;
          return selectedElementIds.contains(elementId);
        }).map((element) {
          return _buildElementHighlight(element, true);
        }).toList(),
        
        // 多选计数器（右上角）
        if (selectedElementIds.length > 1)
          _buildSelectionCounter(),
      ],
    );
  }

  /// 构建单个元素的高亮效果
  Widget _buildElementHighlight(Map<String, dynamic> element, bool isSelected) {
    final elementId = element['id'] as String;
    
    // 尝试从拖拽状态管理器获取实时属性
    Map<String, dynamic>? liveProperties;
    if (dragStateManager != null && dragStateManager!.isDragging) {
      liveProperties = dragStateManager!.getElementPreviewProperties(elementId);
    }
    
    // 使用实时属性或原始属性
    final activeProperties = liveProperties ?? element;
    
    final x = (activeProperties['x'] as num).toDouble();
    final y = (activeProperties['y'] as num).toDouble();
    final width = (activeProperties['width'] as num).toDouble();
    final height = (activeProperties['height'] as num).toDouble();
    final rotation = (activeProperties['rotation'] as num?)?.toDouble() ?? 0.0;

    // L形线条的长度和宽度
    final cornerLength = math.max(12.0, 16.0 / canvasScale);
    final lineWidth = math.max(2.0, 3.0 / canvasScale);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // 左上角
              _buildCornerIndicator(
                left: 0,
                top: 0,
                cornerLength: cornerLength,
                lineWidth: lineWidth,
                isTopLeft: true,
              ),
              // 右上角
              _buildCornerIndicator(
                right: 0,
                top: 0,
                cornerLength: cornerLength,
                lineWidth: lineWidth,
                isTopRight: true,
              ),
              // 左下角
              _buildCornerIndicator(
                left: 0,
                bottom: 0,
                cornerLength: cornerLength,
                lineWidth: lineWidth,
                isBottomLeft: true,
              ),
              // 右下角
              _buildCornerIndicator(
                right: 0,
                bottom: 0,
                cornerLength: cornerLength,
                lineWidth: lineWidth,
                isBottomRight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建角落L形指示器
  Widget _buildCornerIndicator({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double cornerLength,
    required double lineWidth,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SizedBox(
        width: cornerLength,
        height: cornerLength,
        child: CustomPaint(
          painter: _CornerIndicatorPainter(
            primaryColor: primaryColor,
            lineWidth: lineWidth,
            isTopLeft: isTopLeft,
            isTopRight: isTopRight,
            isBottomLeft: isBottomLeft,
            isBottomRight: isBottomRight,
          ),
        ),
      ),
    );
  }

  /// 构建多选计数器
  Widget _buildSelectionCounter() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.done_all,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              '${selectedElementIds.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L形角落指示器的自定义绘制器
class _CornerIndicatorPainter extends CustomPainter {
  final Color primaryColor;
  final double lineWidth;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerIndicatorPainter({
    required this.primaryColor,
    required this.lineWidth,
    required this.isTopLeft,
    required this.isTopRight,
    required this.isBottomLeft,
    required this.isBottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 双色高对比度：白色底色 + 主色边缘
    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = lineWidth + 2.0
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final colorPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (isTopLeft) {
      // 左上角L形
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTopRight) {
      // 右上角L形
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (isBottomLeft) {
      // 左下角L形
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
    } else if (isBottomRight) {
      // 右下角L形
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    // 先画白色底色（较粗）
    canvas.drawPath(path, whitePaint);
    // 再画主色线条（较细）
    canvas.drawPath(path, colorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _CornerIndicatorPainter ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.isTopLeft != isTopLeft ||
        oldDelegate.isTopRight != isTopRight ||
        oldDelegate.isBottomLeft != isBottomLeft ||
        oldDelegate.isBottomRight != isBottomRight;
  }
}