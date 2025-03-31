import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;

  GridPainter({
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // 绘制网格
    final gridSize = 50.0 * scale;
    final xCount = (size.width / gridSize).ceil() + 1;
    final yCount = (size.height / gridSize).ceil() + 1;

    final xOffset = offset.dx % gridSize;
    final yOffset = offset.dy % gridSize;

    // 绘制垂直线
    for (var i = 0; i < xCount; i++) {
      final x = i * gridSize + xOffset;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (var i = 0; i < yCount; i++) {
      final y = i * gridSize + yOffset;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 绘制坐标轴
    final axisPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    // X轴
    canvas.drawLine(
      Offset(0, size.height / 2 + offset.dy),
      Offset(size.width, size.height / 2 + offset.dy),
      axisPaint,
    );

    // Y轴
    canvas.drawLine(
      Offset(size.width / 2 + offset.dx, 0),
      Offset(size.width / 2 + offset.dx, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.offset != offset;
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('坐标系统测试'),
      ),
      body: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: Container(
          color: Colors.grey[200],
          child: CustomPaint(
            painter: GridPainter(
              scale: _scale,
              offset: _offset,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isDragging = false;
    _lastFocalPoint = null;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _isDragging = true;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // 处理缩放
      _scale = _scale * details.scale;

      // 处理平移
      final delta = details.localFocalPoint - _lastFocalPoint!;
      _offset += delta;
      _lastFocalPoint = details.localFocalPoint;
    });
  }
}
