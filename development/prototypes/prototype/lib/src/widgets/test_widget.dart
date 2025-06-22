import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class CoordinateSystemPainter extends CustomPainter {
  final Matrix4 transformMatrix;
  final double scale;

  CoordinateSystemPainter({
    required this.transformMatrix,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    // 绘制网格
    _drawGrid(canvas, size, paint);

    // 绘制坐标轴
    final axisPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    // X轴
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );

    // Y轴
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );

    // 绘制原点
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5,
      Paint()..color = Colors.blue,
    );
  }

  @override
  bool shouldRepaint(covariant CoordinateSystemPainter oldDelegate) {
    return oldDelegate.transformMatrix != transformMatrix ||
        oldDelegate.scale != scale;
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    final gridSize = 50.0 * scale;
    final xCount = (size.width / gridSize).ceil();
    final yCount = (size.height / gridSize).ceil();

    // 绘制垂直线
    for (var i = 0; i <= xCount; i++) {
      final x = i * gridSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (var i = 0; i <= yCount; i++) {
      final y = i * gridSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  Matrix4 _transformMatrix = Matrix4.identity();
  Offset _lastFocalPoint = Offset.zero;
  double _scale = 1.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: CustomPaint(
        size: Size.infinite,
        painter: CoordinateSystemPainter(
          transformMatrix: _transformMatrix,
          scale: _scale,
        ),
      ),
    );
  }

  // 屏幕坐标到世界坐标的转换
  Offset screenToWorld(Offset screenPoint) {
    final invertedMatrix = Matrix4.inverted(_transformMatrix);
    final vector = Vector4(screenPoint.dx, screenPoint.dy, 0, 1);
    final transformed = invertedMatrix.transform(vector);
    return Offset(transformed.x, transformed.y);
  }

  // 世界坐标到屏幕坐标的转换
  Offset worldToScreen(Offset worldPoint) {
    final vector = Vector4(worldPoint.dx, worldPoint.dy, 0, 1);
    final transformed = _transformMatrix.transform(vector);
    return Offset(transformed.x, transformed.y);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isDragging = false;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _isDragging = true;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // 计算缩放
      final newScale = details.scale * _scale;

      // 计算平移
      final delta = details.localFocalPoint - _lastFocalPoint;
      final oldMatrix = _transformMatrix;

      // 创建新的变换矩阵
      _transformMatrix = Matrix4.identity()
        ..translate(delta.dx, delta.dy)
        ..multiply(oldMatrix)
        ..scale(details.scale);

      _scale = newScale;
      _lastFocalPoint = details.localFocalPoint;
    });
  }
}
