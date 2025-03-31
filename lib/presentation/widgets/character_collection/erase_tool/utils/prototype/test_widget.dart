import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'base_layer.dart';
import 'coordinate_transformer.dart';
import 'performance_monitor.dart';

/// 原型测试图层
class PrototypeTestLayer extends PrototypeBaseLayer {
  final ui.Image image;

  const PrototypeTestLayer({
    Key? key,
    required this.image,
    required super.transformer,
    required super.monitor,
    required super.size,
    super.debugMode = true,
  }) : super(key: key);

  @override
  PrototypeBaseLayerState<PrototypeBaseLayer> createState() =>
      _PrototypeTestLayerState();
}

/// 原型测试组件
class PrototypeTestWidget extends StatefulWidget {
  final ui.Image image;

  const PrototypeTestWidget({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  State<PrototypeTestWidget> createState() => _PrototypeTestWidgetState();
}

class _PrototypeTestLayerState
    extends PrototypeBaseLayerState<PrototypeTestLayer> {
  Offset? _lastTapPosition;
  Offset? _lastTransformedPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: super.build(context),
    );
  }

  @override
  CustomPainter createPainter() {
    return _TestLayerPainter(
      image: widget.image,
      debugMode: widget.debugMode,
      lastTapPosition: _lastTapPosition,
      lastTransformedPosition: _lastTransformedPosition,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _lastTapPosition = details.localPosition;
      _lastTransformedPosition =
          widget.transformer.viewportToImage(details.localPosition);
    });

    // 记录转换延迟
    widget.monitor.recordOperationLatency(
      widget.transformer.averageConversionTime,
    );
  }
}

class _PrototypeTestWidgetState extends State<PrototypeTestWidget> {
  late final PrototypePerformanceMonitor _monitor;
  late final TransformationController _transformationController;
  late final ValueNotifier<Size> _sizeNotifier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要测试区域
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (_sizeNotifier.value != size) {
              _sizeNotifier.value = size;
            }

            return ValueListenableBuilder<Size>(
              valueListenable: _sizeNotifier,
              builder: (context, size, child) {
                final transformer = PrototypeCoordinateTransformer(
                  viewportSize: size,
                  imageSize: Size(
                    widget.image.width.toDouble(),
                    widget.image.height.toDouble(),
                  ),
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  transform: _transformationController.value,
                  debugMode: true,
                );

                return InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionEnd: (_) => setState(() {}),
                  child: PrototypeTestLayer(
                    image: widget.image,
                    transformer: transformer,
                    monitor: _monitor,
                    size: size,
                  ),
                );
              },
            );
          },
        ),

        // 性能监控显示
        Positioned(
          top: 16,
          right: 16,
          child: PerformanceMonitorWidget(
            monitor: _monitor,
            showDetails: true,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _monitor.dispose();
    _transformationController.dispose();
    _sizeNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _monitor = PrototypePerformanceMonitor()..start();
    _transformationController = TransformationController();
    _sizeNotifier = ValueNotifier(Size.zero);
  }
}

class _TestLayerPainter extends CustomPainter with DebugPaintMixin {
  final ui.Image image;
  final bool debugMode;
  final Offset? lastTapPosition;
  final Offset? lastTransformedPosition;

  _TestLayerPainter({
    required this.image,
    this.debugMode = true,
    this.lastTapPosition,
    this.lastTransformedPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景图像
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.contain,
    );

    if (debugMode) {
      // 绘制调试网格
      drawDebugGrid(canvas, size);

      // 绘制点击位置
      if (lastTapPosition != null) {
        final paint = Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        // 绘制原始点击位置
        canvas.drawCircle(lastTapPosition!, 10, paint);
        canvas.drawLine(
          lastTapPosition! - const Offset(15, 0),
          lastTapPosition! + const Offset(15, 0),
          paint,
        );
        canvas.drawLine(
          lastTapPosition! - const Offset(0, 15),
          lastTapPosition! + const Offset(0, 15),
          paint,
        );
      }

      // 绘制转换后的位置
      if (lastTransformedPosition != null) {
        final paint = Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(lastTransformedPosition!, 5, paint);
        canvas.drawRect(
          lastTransformedPosition! - const Offset(10, 10) & const Size(20, 20),
          paint,
        );
      }

      // 绘制调试信息
      final info = {
        'Image Size': '${image.width}x${image.height}',
        'View Size':
            '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}',
        if (lastTapPosition != null)
          'Tap Position':
              '(${lastTapPosition!.dx.toStringAsFixed(1)}, ${lastTapPosition!.dy.toStringAsFixed(1)})',
        if (lastTransformedPosition != null)
          'Transformed':
              '(${lastTransformedPosition!.dx.toStringAsFixed(1)}, ${lastTransformedPosition!.dy.toStringAsFixed(1)})',
      };
      drawDebugInfo(canvas, size, info);
    }
  }

  @override
  bool shouldRepaint(covariant _TestLayerPainter oldDelegate) {
    return image != oldDelegate.image ||
        debugMode != oldDelegate.debugMode ||
        lastTapPosition != oldDelegate.lastTapPosition ||
        lastTransformedPosition != oldDelegate.lastTransformedPosition;
  }
}
