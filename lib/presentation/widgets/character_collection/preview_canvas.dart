import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/services/character/character_service.dart';
import '../../../application/services/image/character_image_processor.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../infrastructure/logging/logger.dart';

/// 擦除绘制器
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

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

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

/// 轮廓绘制器
class OutlinePainter extends CustomPainter {
  final DetectedOutline outline;
  final Color color;
  final double strokeWidth;
  final Size imageSize;
  final Size canvasSize;

  OutlinePainter({
    required this.outline,
    required this.imageSize,
    required this.canvasSize,
    this.color = Colors.blue,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    final offsetX = (canvasSize.width - imageSize.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final contour in outline.contourPoints) {
      if (contour.length < 2) continue;

      // 跳过边框轮廓
      if (_isImageBorderContour(contour, imageSize)) {
        continue;
      }

      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }

      path.close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OutlinePainter oldDelegate) {
    return outline != oldDelegate.outline ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        imageSize != oldDelegate.imageSize ||
        canvasSize != oldDelegate.canvasSize;
  }

  /// 检查是否是图像边框轮廓
  bool _isImageBorderContour(List<Offset> contour, Size size) {
    const threshold = 2.0; // 2像素的容差
    return contour.any((point) =>
        point.dx <= threshold ||
        point.dx >= size.width - threshold ||
        point.dy <= threshold ||
        point.dy >= size.height - threshold);
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
    super.key,
    required this.regionId,
    this.pageImageData,
    this.regionRect,
    required this.isInverted,
    required this.showOutline,
    required this.zoomLevel,
    required this.isErasing,
    required this.brushSize,
    required this.onErasePointsChanged,
  });

  @override
  ConsumerState<PreviewCanvas> createState() => _PreviewCanvasState();
}

class _PreviewCanvasState extends ConsumerState<PreviewCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _containerKey = GlobalKey();

  final List<Offset> _currentErasePoints = [];
  bool _isErasing = false;
  DetectedOutline? _currentOutline;
  img.Image? _currentImage;
  Size? _currentImageSize;
  Size? _currentCanvasSize;

  // 缓存处理状态
  bool _lastInverted = false;
  bool _lastShowOutline = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _currentCanvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return FutureBuilder<bool>(
          future: _loadCharacterImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              AppLogger.error('预览加载失败', error: snapshot.error);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      '加载图像失败: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else if (_currentImage == null) {
              return const Center(
                child: Text('无图像数据'),
              );
            }

            final displayImage =
                Uint8List.fromList(img.encodePng(_currentImage!));
            _currentImageSize = Size(
              _currentImage!.width.toDouble(),
              _currentImage!.height.toDouble(),
            );

            return Stack(
              children: [
                Container(
                  key: _containerKey,
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
                      constrained: true,
                      clipBehavior: Clip.hardEdge,
                      boundaryMargin: EdgeInsets.zero,
                      child: Center(
                        child: Image.memory(
                          displayImage,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showOutline &&
                    _currentOutline != null &&
                    _currentImageSize != null &&
                    _currentCanvasSize != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: OutlinePainter(
                          outline: _currentOutline!,
                          imageSize: _currentImageSize!,
                          canvasSize: _currentCanvasSize!,
                          color: Colors.blue.withOpacity(0.8),
                          strokeWidth: 1.0,
                        ),
                      ),
                    ),
                  ),
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
              ],
            );
          },
        );
      },
    );
  }

  @override
  void didUpdateWidget(PreviewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.zoomLevel != oldWidget.zoomLevel) {
      _updateTransform();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanvasSize());
  }

  Future<Size?> _getImageSize(Uint8List imageData) async {
    final decodedImage = img.decodeImage(imageData);
    if (decodedImage == null) return null;
    return Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );
  }

  void _handleErasePanEnd(DragEndDetails details) {
    if (!_isErasing || _currentErasePoints.isEmpty) return;
    widget.onErasePointsChanged(_currentErasePoints);
    setState(() {
      _isErasing = false;
    });
    _loadCharacterImage(); // 重新加载以显示擦除效果
  }

  void _handleErasePanStart(DragStartDetails details) {
    if (!widget.isErasing) return;
    setState(() {
      _isErasing = true;
      _currentErasePoints.clear();
      _currentErasePoints.add(_transformPointToImage(details.localPosition));
    });
  }

  void _handleErasePanUpdate(DragUpdateDetails details) {
    if (!_isErasing) return;
    setState(() {
      _currentErasePoints.add(_transformPointToImage(details.localPosition));
    });
  }

  Future<bool> _loadCharacterImage() async {
    try {
      // 仅在必要时重新加载图像
      if (_currentImage != null &&
          !widget.isErasing &&
          widget.isInverted == _lastInverted &&
          widget.showOutline == _lastShowOutline) {
        return true;
      }

      AppLogger.debug('开始加载预览图像', data: {
        'regionId': widget.regionId,
        'hasPageImage': widget.pageImageData != null,
        'hasRect': widget.regionRect != null,
        'isErasing': widget.isErasing,
      });

      final processingOptions = ProcessingOptions(
        inverted: widget.isInverted,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: widget.showOutline,
      );

      // 处理新框选的情况
      if (widget.pageImageData != null && widget.regionRect != null) {
        final preview =
            await ref.read(characterImageProcessorProvider).previewProcessing(
                  widget.pageImageData!,
                  widget.regionRect!,
                  processingOptions,
                  _currentErasePoints.isNotEmpty ? _currentErasePoints : null,
                );

        if (!mounted) return false;

        setState(() {
          _currentImage = preview.processedImage;
          _currentOutline = preview.outline;
          _lastInverted = widget.isInverted;
          _lastShowOutline = widget.showOutline;
        });

        return true;
      }

      // 处理已保存字符的情况
      if (widget.regionId.isNotEmpty) {
        final savedImage = await ref
            .read(characterServiceProvider)
            .getCharacterImage(widget.regionId, CharacterImageType.binary);

        if (savedImage == null) {
          throw Exception('找不到保存的图像');
        }

        final imageSize = await _getImageSize(savedImage);
        if (imageSize == null) {
          throw Exception('无法解码保存的图像');
        }

        final imageRect = Rect.fromLTWH(
          0,
          0,
          imageSize.width,
          imageSize.height,
        );

        final preview =
            await ref.read(characterImageProcessorProvider).previewProcessing(
                  savedImage,
                  imageRect,
                  processingOptions,
                  _currentErasePoints.isNotEmpty ? _currentErasePoints : null,
                );

        if (!mounted) return false;

        setState(() {
          _currentImage = preview.processedImage;
          _currentOutline = preview.outline;
          _lastInverted = widget.isInverted;
          _lastShowOutline = widget.showOutline;
        });

        return true;
      }

      AppLogger.debug('没有有效的图像数据');
      return false;
    } catch (e, stack) {
      AppLogger.error('预览处理失败', error: e, stackTrace: stack);
      return false;
    }
  }

  Offset _transformPointToImage(Offset point) {
    if (_currentImageSize == null || _currentCanvasSize == null) return point;

    final scale = math.min(
      _currentCanvasSize!.width / _currentImageSize!.width,
      _currentCanvasSize!.height / _currentImageSize!.height,
    );

    final offsetX =
        (_currentCanvasSize!.width - _currentImageSize!.width * scale) / 2;
    final offsetY =
        (_currentCanvasSize!.height - _currentImageSize!.height * scale) / 2;

    return Offset(
      (point.dx - offsetX) / scale,
      (point.dy - offsetY) / scale,
    );
  }

  void _updateCanvasSize() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _currentCanvasSize = renderBox.size;
      });
    }
  }

  void _updateTransform() {
    final scale = Matrix4.identity()
      ..scale(widget.zoomLevel, widget.zoomLevel, 1.0);
    _transformationController.value = scale;
  }
}
