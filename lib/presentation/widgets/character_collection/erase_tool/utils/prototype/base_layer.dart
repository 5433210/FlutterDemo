import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'coordinate_transformer.dart';
import 'performance_monitor.dart';

/// 调试绘制工具
mixin DebugPaintMixin {
  /// 绘制调试网格
  void drawDebugGrid(
    Canvas canvas,
    Size size, {
    double gridSize = 50.0,
    Color color = const Color(0x40FF0000),
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制竖线
    for (var x = 0.0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制横线
    for (var y = 0.0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 绘制中心点
    final centerPaint = Paint()
      ..color = const Color(0x80FF0000)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 5.0, centerPaint);
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      centerPaint,
    );
  }

  /// 绘制调试信息
  void drawDebugInfo(Canvas canvas, Size size, Map<String, String> info) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    var y = 10.0;
    for (final entry in info.entries) {
      textPainter.text = TextSpan(
        text: '${entry.key}: ${entry.value}',
        style: const TextStyle(
          color: Color(0xFFFF0000),
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y));
      y += textPainter.height + 5;
    }
  }
}

/// 图层基类 - 原型验证版本
abstract class PrototypeBaseLayer extends StatefulWidget {
  /// 坐标转换器
  final PrototypeCoordinateTransformer transformer;

  /// 性能监控器
  final PrototypePerformanceMonitor monitor;

  /// 图层尺寸
  final Size size;

  /// 是否开启调试模式
  final bool debugMode;

  const PrototypeBaseLayer({
    Key? key,
    required this.transformer,
    required this.monitor,
    required this.size,
    this.debugMode = false,
  }) : super(key: key);

  @override
  PrototypeBaseLayerState createState();
}

/// 图层状态基类
abstract class PrototypeBaseLayerState<T extends PrototypeBaseLayer>
    extends State<T> {
  /// 重绘通知器
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  /// 绘制开始时间
  int? _paintStartTime;

  /// 是否正在测量性能
  bool _isMeasuring = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: widget.size,
        isComplex: true,
        willChange: true,
        painter: _PerformanceWrappedPainter(
          painter: createPainter(),
          onPaintStart: _onPaintStart,
          onPaintEnd: _onPaintEnd,
        ),
      ),
    );
  }

  /// 创建绘制器
  CustomPainter createPainter();

  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repaintNotifier.addListener(_onRepaint);
  }

  /// 请求重绘
  void requestRepaint() {
    _repaintNotifier.value++;
  }

  /// 绘制结束回调
  void _onPaintEnd() {
    if (_isMeasuring || _paintStartTime == null) return;

    _isMeasuring = true;
    final paintTime =
        (DateTime.now().microsecondsSinceEpoch - _paintStartTime!) / 1000.0;

    // 使用post-frame回调来记录性能数据
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.monitor.recordFrameTime(paintTime);
        _paintStartTime = null;
        _isMeasuring = false;
      }
    });
  }

  /// 绘制开始回调
  void _onPaintStart() {
    if (_isMeasuring) return;
    _paintStartTime = DateTime.now().microsecondsSinceEpoch;
  }

  /// 重绘回调
  void _onRepaint() {
    if (mounted) {
      setState(() {});
    }
  }
}

/// 性能包装绘制器
class _PerformanceWrappedPainter extends CustomPainter {
  final CustomPainter painter;
  final VoidCallback onPaintStart;
  final VoidCallback onPaintEnd;

  _PerformanceWrappedPainter({
    required this.painter,
    required this.onPaintStart,
    required this.onPaintEnd,
  }) : super(repaint: painter);

  @override
  void paint(Canvas canvas, Size size) {
    onPaintStart();
    painter.paint(canvas, size);
    onPaintEnd();
  }

  @override
  bool shouldRepaint(covariant _PerformanceWrappedPainter oldDelegate) {
    return painter.shouldRepaint(oldDelegate.painter);
  }
}
