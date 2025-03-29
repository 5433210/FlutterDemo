import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/providers/image_providers.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../infrastructure/logging/logger.dart';

/// 擦除绘制器
class ErasePainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;

  const ErasePainter({
    required this.points,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
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
  }

  @override
  bool shouldRepaint(covariant ErasePainter oldDelegate) {
    return points != oldDelegate.points || brushSize != oldDelegate.brushSize;
  }
}

/// 轮廓绘制器
class OutlinePainter extends CustomPainter {
  final DetectedOutline outline;
  final Size imageSize;
  final Size canvasSize;

  const OutlinePainter({
    required this.outline,
    required this.imageSize,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final offsetX = (canvasSize.width - imageSize.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final contour in outline.contourPoints) {
      if (contour.length < 2) continue;

      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }

      path.close();

      // 先用填充色绘制轮廓内部
      canvas.drawPath(path, fillPaint);
      // 再用描边色绘制轮廓线
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OutlinePainter oldDelegate) {
    return outline != oldDelegate.outline ||
        imageSize != oldDelegate.imageSize ||
        canvasSize != oldDelegate.canvasSize;
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
  bool _isProcessing = false;

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
            if (snapshot.connectionState == ConnectionState.waiting &&
                _isProcessing) {
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

  void _handleErasePanEnd(DragEndDetails details) {
    if (!_isErasing || _currentErasePoints.isEmpty) return;
    widget.onErasePointsChanged(_currentErasePoints);
    setState(() {
      _isErasing = false;
    });
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
          !_isProcessing &&
          widget.isInverted == _lastInverted &&
          widget.showOutline == _lastShowOutline) {
        return true;
      }

      _isProcessing = true;

      AppLogger.debug('开始加载预览图像', data: {
        'regionId': widget.regionId,
        'hasPageImage': widget.pageImageData != null,
        'hasRect': widget.regionRect != null,
      });

      final processingOptions = ProcessingOptions(
        inverted: widget.isInverted,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: widget.showOutline,
      );

      try {
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
        } else if (widget.regionId.isNotEmpty) {
          final savedImage = await ref
              .read(characterProvider)
              .getCharacterImage(widget.regionId, CharacterImageType.binary);

          if (savedImage != null) {
            final imageSize = Size(
              _currentImage?.width.toDouble() ?? 0,
              _currentImage?.height.toDouble() ?? 0,
            );

            final imageRect = Rect.fromLTWH(
              0,
              0,
              imageSize.width,
              imageSize.height,
            );

            final preview = await ref
                .read(characterImageProcessorProvider)
                .previewProcessing(
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
          }
        }

        _isProcessing = false;
        return true;
      } catch (e) {
        _isProcessing = false;
        rethrow;
      }
    } catch (e, stack) {
      AppLogger.error('预览处理失败', error: e, stackTrace: stack);
      _isProcessing = false;
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
