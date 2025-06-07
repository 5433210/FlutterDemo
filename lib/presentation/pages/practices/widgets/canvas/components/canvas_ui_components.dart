import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/logger.dart';

/// 选择框状态类 - 用于保存和管理选择框的当前状态
class SelectionBoxState {
  final bool isActive;
  final Offset? startPoint;
  final Offset? endPoint;

  SelectionBoxState({
    this.isActive = false,
    this.startPoint,
    this.endPoint,
  });

  SelectionBoxState copyWith({
    bool? isActive,
    Offset? startPoint,
    Offset? endPoint,
  }) {
    return SelectionBoxState(
      isActive: isActive ?? this.isActive,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
    );
  }
}

/// 网格绘制器
class CanvasGridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  CanvasGridPainter({
    required this.gridSize,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8  // 🔧 更细更优雅的线条
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CanvasGridPainter oldDelegate) {
    final shouldRepaint = oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
    
    if (shouldRepaint) {
      AppLogger.debug(
        '网格需要重绘',
        tag: 'Canvas',
        data: {
          'oldGridSize': oldDelegate.gridSize,
          'newGridSize': gridSize,
          'colorChanged': oldDelegate.gridColor != gridColor,
        },
      );
    }
    
    return shouldRepaint;
  }
} 