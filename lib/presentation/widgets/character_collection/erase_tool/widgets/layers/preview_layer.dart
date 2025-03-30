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

    // 使用ListenableBuilder简化构建过程
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          // 添加调试日志帮助排查问题
          print(
              'PreviewLayer rebuild - isErasing: ${controller.isErasing}, points: ${controller.currentPoints.length}');

          // 即使没有点也创建一个空画布，保持渲染区域存在
          return CustomPaint(
            painter: _PreviewPainter(
              points: controller.currentPoints,
              brushSize: controller.brushSize,
              matrix: transformationController.value,
              isErasing: controller.isErasing,
            ),
            // 使用无限大尺寸确保预览层覆盖整个可见区域
            size: Size.infinite,
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

  /// 变换矩阵
  final Matrix4 matrix;

  /// 是否处于擦除状态
  final bool isErasing;

  /// 缓存的画笔
  late final Paint _pathPaint;
  late final Paint _pointPaint;
  late final Paint _highlightPaint;

  /// 构造函数
  _PreviewPainter({
    required this.points,
    required this.brushSize,
    required this.matrix,
    required this.isErasing,
  }) {
    // 使用更高的不透明度和更鲜明的颜色提高可见性
    _pathPaint = Paint()
      ..color = Colors.red.withOpacity(0.8) // 提高不透明度
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _pointPaint = Paint()
      ..color = Colors.white.withOpacity(0.7) // 提高不透明度
      ..style = PaintingStyle.fill;

    _highlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.9) // 提高不透明度
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 即使没有点，也应该进入绘制流程，保证画布存在
    print(
        '_PreviewPainter.paint - points: ${points.length}, isErasing: $isErasing');

    // 保存当前画布状态
    canvas.save();

    // 应用变换矩阵
    canvas.transform(matrix.storage);

    // 绘制擦除路径
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, _pathPaint);
    }

    // 绘制最后一个点作为光标
    if (points.isNotEmpty) {
      final lastPoint = points.last;

      // 绘制内圆填充
      canvas.drawCircle(
        lastPoint,
        brushSize / 2,
        _pointPaint,
      );

      // 绘制外圈高亮
      canvas.drawCircle(
        lastPoint,
        brushSize / 2 + 2,
        _highlightPaint,
      );

      // 添加辅助线帮助定位
      if (isErasing) {
        final crossPaint = Paint()
          ..color = Colors.cyan.withOpacity(0.8)
          ..strokeWidth = 1.5;

        // 绘制十字准星
        canvas.drawLine(
          Offset(lastPoint.dx - brushSize / 2, lastPoint.dy),
          Offset(lastPoint.dx + brushSize / 2, lastPoint.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(lastPoint.dx, lastPoint.dy - brushSize / 2),
          Offset(lastPoint.dx, lastPoint.dy + brushSize / 2),
          crossPaint,
        );
      }
    }

    // 恢复画布状态
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    // 优化重绘条件，确保状态变化时能正确重绘
    if (isErasing != oldDelegate.isErasing) {
      return true;
    }

    if (points.length != oldDelegate.points.length) {
      return true;
    }

    if ((brushSize - oldDelegate.brushSize).abs() > 0.1) {
      return true;
    }

    // 检查最后一个点是否变化
    if (points.isNotEmpty && oldDelegate.points.isNotEmpty) {
      if ((points.last - oldDelegate.points.last).distance > 0.5) {
        return true;
      }
    }

    // 判断矩阵是否有变化
    for (int i = 0; i < 16; i++) {
      if ((matrix.storage[i] - oldDelegate.matrix.storage[i]).abs() > 0.01) {
        return true;
      }
    }

    return false;
  }
}
