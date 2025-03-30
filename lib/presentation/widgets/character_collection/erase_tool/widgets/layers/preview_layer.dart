import 'package:flutter/foundation.dart';
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
          final points = controller.currentPoints;
          final brushSize = controller.brushSize;
          final isErasing = controller.isErasing;

          if (kDebugMode && points.isNotEmpty) {
            print(
                '🖊️ PreviewLayer绘制 - 点数: ${points.length}, 笔刷: $brushSize, 擦除中: $isErasing');
            if (points.isNotEmpty) {
              print('  - 最后点: ${points.last}');
            }
          }

          // 即使没有点也创建一个空画布，保持渲染区域存在
          return CustomPaint(
            painter: _PreviewPainter(
              points: points,
              brushSize: brushSize,
              matrix: transformationController.value,
              isErasing: isErasing,
            ),
            // 使用无限大尺寸确保预览层覆盖整个可见区域
            size: Size.infinite,
            isComplex: points.length > 100, // 当点数很多时标记为复杂绘制
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
  late final Paint _cursorPaint;

  /// 构造函数
  _PreviewPainter({
    required this.points,
    required this.brushSize,
    required this.matrix,
    required this.isErasing,
  }) {
    // 路径画笔 - 显示擦除线条
    _pathPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 点填充画笔 - 光标内圆
    _pointPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 高亮画笔 - 光标外圈
    _highlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 光标十字线画笔
    _cursorPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
  }

  /// 判断是否为单位矩阵
  bool isIdentityMatrix(Matrix4 matrix) {
    final identity = Matrix4.identity();
    return matrixEquals(matrix, identity);
  }

  /// 判断两个矩阵是否相等
  bool matrixEquals(Matrix4 a, Matrix4 b) {
    for (int i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 保存当前画布状态，便于后续恢复
    canvas.save();

    try {
      // 应用矩阵变换
      // 注意：我们需要小心处理这里的变换，确保正确应用
      if (!isIdentityMatrix(matrix)) {
        canvas.transform(matrix.storage);
      }

      // 绘制擦除路径
      if (points.length > 1) {
        _drawErasePath(canvas);
      }

      // 绘制擦除光标 (只在有点且处于擦除状态时绘制)
      if (points.isNotEmpty) {
        _drawEraseCursor(canvas, points.last);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 绘制预览层时出错: $e');
      }
    } finally {
      // 恢复画布状态
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    // 优化重绘条件，减少不必要的重绘
    // 1. 擦除状态变化时重绘
    if (isErasing != oldDelegate.isErasing) {
      return true;
    }

    // 2. 点数变化时重绘
    if (points.length != oldDelegate.points.length) {
      return true;
    }

    // 3. 笔刷大小有明显变化时重绘
    if ((brushSize - oldDelegate.brushSize).abs() > 0.5) {
      return true;
    }

    // 4. 最后一个点变化时重绘 (光标位置更新)
    if (points.isNotEmpty && oldDelegate.points.isNotEmpty) {
      if ((points.last - oldDelegate.points.last).distance > 0.5) {
        return true;
      }
    }

    // 5. 变换矩阵变化时重绘
    if (!matrixEquals(matrix, oldDelegate.matrix)) {
      return true;
    }

    return false;
  }

  /// 绘制擦除光标
  void _drawEraseCursor(Canvas canvas, Offset position) {
    // 计算光标尺寸
    final cursorSize = brushSize / 2;

    // 绘制内圆填充
    canvas.drawCircle(
      position,
      cursorSize,
      _pointPaint,
    );

    // 绘制外圈高亮
    canvas.drawCircle(
      position,
      cursorSize + 2,
      _highlightPaint,
    );

    // 绘制十字准星辅助线
    if (isErasing) {
      // 水平线
      canvas.drawLine(
        Offset(position.dx - cursorSize, position.dy),
        Offset(position.dx + cursorSize, position.dy),
        _cursorPaint,
      );

      // 垂直线
      canvas.drawLine(
        Offset(position.dx, position.dy - cursorSize),
        Offset(position.dx, position.dy + cursorSize),
        _cursorPaint,
      );
    }
  }

  /// 绘制擦除路径
  void _drawErasePath(Canvas canvas) {
    final path = Path();

    // 移动到第一个点
    path.moveTo(points.first.dx, points.first.dy);

    // 如果只有两个点，直接连线
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
    }
    // 如果有多个点，可以使用曲线平滑过渡
    else if (points.length > 2) {
      // 使用三次贝塞尔曲线连接前两个点
      path.lineTo(points[1].dx, points[1].dy);

      // 使用平滑曲线连接其余点
      for (int i = 1; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        // 简单线段连接
        path.lineTo(p1.dx, p1.dy);
      }
    }

    // 绘制路径
    canvas.drawPath(path, _pathPaint);
  }
}
