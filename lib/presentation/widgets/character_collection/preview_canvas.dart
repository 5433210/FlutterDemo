import 'dart:typed_data';
import 'dart:ui';

import 'package:demo/application/services/character/character_service.dart';
import 'package:demo/application/services/image/character_image_processor.dart';
import 'package:demo/domain/models/character/character_image_type.dart';
import 'package:demo/infrastructure/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/processing_options.dart';

// 擦除绘制器
class ErasePainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;
  final Color color;

  ErasePainter({
    required this.points,
    required this.brushSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 创建路径
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 绘制路径
    canvas.drawPath(path, paint);

    // 在每个点画圆点，使线条更平滑
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, brushSize / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ErasePainter oldDelegate) {
    return points != oldDelegate.points ||
        brushSize != oldDelegate.brushSize ||
        color != oldDelegate.color;
  }
}

class PreviewCanvas extends ConsumerStatefulWidget {
  final String regionId;
  final Uint8List? pageImageData;
  final Rect? regionRect;
  final bool isInverted;
  final bool showOutline;
  final double zoomLevel;
  final bool isErasing;
  final double brushSize;
  final Function(List<Offset>) onErasePointsChanged;

  const PreviewCanvas({
    Key? key,
    required this.regionId,
    this.pageImageData,
    this.regionRect,
    required this.isInverted,
    required this.showOutline,
    required this.zoomLevel,
    required this.isErasing,
    required this.brushSize,
    required this.onErasePointsChanged,
  }) : super(key: key);

  @override
  ConsumerState<PreviewCanvas> createState() => _PreviewCanvasState();
}

class _PreviewCanvasState extends ConsumerState<PreviewCanvas> {
  // 变换控制器
  final TransformationController _transformationController =
      TransformationController();

  // 擦除状态
  final List<Offset> _currentErasePoints = [];
  bool _isErasing = false;

  @override
  Widget build(BuildContext context) {
    // 使用FutureBuilder加载并显示字符图像
    return FutureBuilder<Uint8List?>(
      future: _loadCharacterImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '加载图像失败: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('无图像数据'),
          );
        }

        // 图像加载成功
        return Stack(
          children: [
            // 预览容器
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),

            // 擦除层 - 仅在擦除模式下显示
            if (widget.isErasing)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: _handleErasePanStart,
                  onPanUpdate: _handleErasePanUpdate,
                  onPanEnd: _handleErasePanEnd,
                  child: CustomPaint(
                    painter: ErasePainter(
                      points: _currentErasePoints,
                      brushSize: widget.brushSize,
                      color: Colors.red.withOpacity(0.6),
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),

            // 轮廓层 - 仅在显示轮廓时显示
            if (widget.showOutline)
              Positioned.fill(
                child: FutureBuilder<String?>(
                  future: _loadOutlineSvg(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      // 在实际应用中，这里应该使用SvgPicture显示SVG轮廓
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Text(
                            'SVG Outline',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(PreviewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 缩放级别变化时更新变换
    if (widget.zoomLevel != oldWidget.zoomLevel) {
      _updateTransform();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 创建占位图像 - 用于加载失败时显示
  Future<Uint8List> _createPlaceholderImage(
      int width, int height, Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 绘制背景
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    // 绘制错误图标
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制简单的X形
    canvas.drawLine(Offset(width * 0.3, height * 0.3),
        Offset(width * 0.7, height * 0.7), iconPaint);
    canvas.drawLine(Offset(width * 0.3, height * 0.7),
        Offset(width * 0.7, height * 0.3), iconPaint);

    final picture = recorder.endRecording();
    final img = picture.toImageSync(width, height);
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to byte data');
    }

    return byteData.buffer.asUint8List();
  }

  // 处理擦除结束
  void _handleErasePanEnd(DragEndDetails details) {
    if (!_isErasing || _currentErasePoints.isEmpty) return;

    // 通知擦除点变化
    widget.onErasePointsChanged(_currentErasePoints);

    setState(() {
      _isErasing = false;
      _currentErasePoints.clear();
    });
  }

  // 处理擦除开始
  void _handleErasePanStart(DragStartDetails details) {
    if (!widget.isErasing) return;

    setState(() {
      _isErasing = true;
      _currentErasePoints.clear();
      _currentErasePoints.add(details.localPosition);
    });
  }

  // 处理擦除更新
  void _handleErasePanUpdate(DragUpdateDetails details) {
    if (!_isErasing) return;

    setState(() {
      _currentErasePoints.add(details.localPosition);
    });
  }

  // 加载字符图像
  Future<Uint8List?> _loadCharacterImage() async {
    try {
      // 检查基本条件
      if (widget.regionId.isEmpty) {
        return null;
      }

      // 设置处理选项
      final processingOptions = ProcessingOptions(
        inverted: widget.isInverted,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: false,
      );

      // 尝试从仓库加载已保存的图像
      final savedImage = await ref
          .read(characterServiceProvider)
          .getCharacterImage(widget.regionId, CharacterImageType.binary);

      if (savedImage != null) {
        return savedImage;
      }

      // 如果没有找到已保存的图像，且提供了页面图像数据和区域，则从页面截取
      if (widget.pageImageData != null && widget.regionRect != null) {
        AppLogger.debug('从页面图像中截取区域', data: {
          'regionId': widget.regionId,
          'rect':
              '${widget.regionRect!.left},${widget.regionRect!.top},${widget.regionRect!.width},${widget.regionRect!.height}'
        });

        final result = await ref
            .read(characterImageProcessorProvider)
            .processCharacterRegion(
              widget.pageImageData!,
              widget.regionRect!,
              processingOptions,
              null,
            );
        return result.binaryImage;
      }

      return null;
    } catch (e) {
      print('加载字符图像失败: $e');
      // 在开发阶段，返回一个占位图像而不是抛出异常
      // 这样UI可以显示一个错误状态而不是崩溃
      return _createPlaceholderImage(100, 100, Colors.red);
    }
  }

  // 加载轮廓SVG
  Future<String?> _loadOutlineSvg() async {
    try {
      // 如果不显示轮廓或区域ID为空，则返回null
      if (!widget.showOutline || widget.regionId.isEmpty) {
        return null;
      }

      return 'data:image/svg+xml,<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg"></svg>';
    } catch (e) {
      print('加载轮廓失败: $e');
      return null;
    }
  }

  void _updateTransform() {
    // 计算基于当前缩放和平移的变换
    final scale = Matrix4.identity()
      ..scale(widget.zoomLevel, widget.zoomLevel, 1.0);
    _transformationController.value = scale;
  }
}
