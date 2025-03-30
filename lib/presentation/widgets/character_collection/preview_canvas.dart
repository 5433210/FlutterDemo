import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/providers/image_providers.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../infrastructure/logging/logger.dart';
import 'erase_tool/controllers/erase_tool_controller.dart';
import 'erase_tool/widgets/erase_tool_widget.dart';

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
  final Function(EraseToolController)? onEraseControllerReady;

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
    this.onEraseControllerReady,
  });

  @override
  ConsumerState<PreviewCanvas> createState() => _PreviewCanvasState();
}

class _PreviewCanvasState extends ConsumerState<PreviewCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _containerKey = GlobalKey();

  final List<Offset> _currentErasePoints = [];
  final bool _isErasing = false;
  DetectedOutline? _currentOutline;
  img.Image? _currentImage;
  Size? _currentImageSize;
  Size? _currentCanvasSize;
  bool _isProcessing = false;
  EraseToolController? _eraseController;

  // 缓存处理状态
  bool _lastInverted = false;
  bool _lastShowOutline = false;

  // 图像缓存相关
  Uint8List? _lastImageBytes;
  Widget? _cachedEraseToolWidget;
  ui.Image? _lastUiImage;
  Completer<ui.Image>? _pendingImageConversion;
  final int _imageHash = 0; // 用于跟踪图像内容变化

  // 添加独立的擦除工具状态跟踪
  final bool _isEraseToolInitializing = false;
  bool _eraseToolInitialized = false;
  String _lastRegionId = '';
  GlobalKey _eraseToolKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // 检查区域是否变化，变化则重置擦除工具状态
    if (_lastRegionId != widget.regionId) {
      _lastRegionId = widget.regionId;
      _eraseToolInitialized = false;
      _cachedEraseToolWidget = null;
      _lastUiImage = null;
      _eraseToolKey = GlobalKey();
    }

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
                if (widget.isErasing && _currentImage != null)
                  _buildEraseToolLayer(),
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
    // 清理控制器引用，避免潜在的内存泄漏
    _eraseController = null;
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanvasSize());
  }

  // 添加调试信息组件，帮助排查问题
  Widget _buildDebugInfo() {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Brush: ${widget.brushSize.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  // 进一步简化擦除工具层，专注解决画布阻塞问题
  Widget _buildEraseToolLayer() {
    if (!widget.isErasing) {
      return const SizedBox.shrink();
    }

    // 使用Positioned.fill确保擦除工具层完全覆盖画布
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 如果缓存存在且有效，直接返回
          if (_cachedEraseToolWidget != null && _eraseToolInitialized) {
            return _cachedEraseToolWidget!;
          }

          if (_lastUiImage == null) {
            // 异步准备图像，不阻塞UI
            _prepareImageAsync();
            return const Center(
                child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2),
            ));
          }

          if (_cachedEraseToolWidget == null) {
            print(
                '🔨 创建擦除工具实例 (${_lastUiImage!.width}x${_lastUiImage!.height})');

            // 使用GestureDetector和IgnorePointer确保手势正确传递
            _cachedEraseToolWidget = Stack(
              children: [
                // 底层画布 - 透明背景
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ClipRect(
                      child: EraseToolWidget(
                        key: ValueKey(
                            'eraser_${widget.regionId}_${DateTime.now().millisecondsSinceEpoch}'),
                        image: _lastUiImage!,
                        initialBrushSize: widget.brushSize,
                        onEraseComplete: _handleEraseComplete,
                        onControllerReady: (controller) {
                          _eraseToolInitialized = true;
                          _handleControllerReady(controller);
                        },
                      ),
                    ),
                  ),
                ),

                // 调试信息层 - 帮助排查问题
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _buildDebugInfo(),
                ),
              ],
            );
          }

          return _cachedEraseToolWidget!;
        },
      ),
    );
  }

  // 处理擦除控制器初始化
  void _handleControllerReady(EraseToolController controller) {
    _eraseController = controller;
    if (widget.onEraseControllerReady != null) {
      widget.onEraseControllerReady!(controller);
    }
  }

  // 简化图像处理完成回调
  Future<void> _handleEraseComplete(ui.Image processedImage) async {
    if (!mounted) return;

    try {
      // 先清除状态，避免UI冻结感
      setState(() {
        // 清除缓存状态，后续会重建
        _eraseToolInitialized = false;
        // 不立即清除缓存视图，避免闪烁
      });

      // 利用isolate转换图像，避免阻塞UI线程
      final bytes =
          await processedImage.toByteData(format: ui.ImageByteFormat.png);
      final imgImage = await compute((ByteData data) {
        return img.decodePng(data.buffer.asUint8List())!;
      }, bytes!);

      if (!mounted) return;

      setState(() {
        _currentImage = imgImage;
        _currentErasePoints.clear();
        _cachedEraseToolWidget = null;
        _lastUiImage = null;
      });

      widget.onErasePointsChanged(_currentErasePoints);
    } catch (e) {
      print('图像处理失败: $e');
    }
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

  // 优化图像准备方法
  void _prepareImageAsync() {
    if (_pendingImageConversion != null || _lastUiImage != null) return;

    // 使用微任务避免阻塞UI
    Future.microtask(() {
      if (!mounted) return;

      final bytes = Uint8List.fromList(img.encodePng(_currentImage!));
      // 设置标志，防止重复调用
      _pendingImageConversion = Completer<ui.Image>();

      ui.decodeImageFromList(bytes, (image) {
        if (!mounted) return;

        setState(() {
          _lastUiImage = image;
          _pendingImageConversion = null;
        });
      });
    });
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

  // 静态方法用于在isolate中解码图像
  static img.Image _decodeImage(ByteData? byteData) {
    if (byteData == null) {
      throw Exception('Cannot decode null image data');
    }
    final bytes = byteData.buffer.asUint8List();
    return img.decodePng(bytes)!;
  }
}
