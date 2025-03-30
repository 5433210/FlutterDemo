import 'package:flutter/material.dart';

import '../../controllers/erase_tool_provider.dart';

/// 擦除预览层
/// 显示实时擦除效果
class PreviewLayer extends StatelessWidget {
  /// 变换控制器
  final TransformationController transformationController;

  /// 构造函数
  const PreviewLayer({
    Key? key,
    required this.transformationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = EraseToolProvider.of(context);

    // 减少重建范围
    return RepaintBoundary(
      child: ValueListenableBuilder<Matrix4>(
        valueListenable: transformationController,
        builder: (context, matrix, _) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              // 仅在擦除状态时显示，减少不必要的绘制
              if (!controller.isErasing || controller.currentPoints.isEmpty) {
                return const SizedBox.shrink();
              }

              return CustomPaint(
                painter: _PreviewPainter(
                  points: controller.currentPoints,
                  brushSize: controller.brushSize,
                  matrix: matrix,
                ),
                size: Size.infinite,
              );
            },
          );
        },
      ),
    );
  }
}

/// 预览层绘制器
class _PreviewPainter extends CustomPainter {
  /// 当前擦除点
  final List<Offset> points;

  /// 笔刷大小
  final double brushSize;

  /// 变换矩阵，使用直接传递而非控制器以减少依赖
  final Matrix4 matrix;

  /// 缓存的画笔
  late final Paint _pathPaint;
  late final Paint _pointPaint;
  late final Paint _highlightPaint;

  /// 构造函数
  _PreviewPainter({
    required this.points,
    required this.brushSize,
    required this.matrix,
  }) {
    // 初始化画笔，减少每次绘制时的创建开销
    _pathPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _pointPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    _highlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    canvas.save();
    canvas.transform(matrix.storage);

    // 绘制路径
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, _pathPaint);
    }

    // 绘制最后一个点的高亮显示，减少不必要的绘制
    if (points.isNotEmpty) {
      canvas.drawCircle(
        points.last,
        brushSize / 2,
        _pointPaint,
      );

      canvas.drawCircle(
        points.last,
        brushSize / 2 + 2,
        _highlightPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    // 优化重绘条件，只有实际变化时才重绘
    if (points.length != oldDelegate.points.length) {
      return true;
    }

    if ((brushSize - oldDelegate.brushSize).abs() > 0.5) {
      return true;
    }

    // 判断矩阵是否有明显变化
    for (int i = 0; i < 16; i++) {
      if ((matrix.storage[i] - oldDelegate.matrix.storage[i]).abs() > 0.01) {
        return true;
      }
    }

    // 检查最后一个点是否变化
    if (points.isNotEmpty && oldDelegate.points.isNotEmpty) {
      if ((points.last - oldDelegate.points.last).distance > 1.0) {
        return true;
      }
    }

    return false;
  }
}
