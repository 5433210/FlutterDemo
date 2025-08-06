import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../image/cached_image.dart';
import 'cross_platform_svg_picture.dart';

/// 可缩放的图像查看器组件
class ZoomableImageView extends StatefulWidget {
  final String imagePath;
  final bool enableMouseWheel;
  final double minScale;
  final double maxScale;
  final bool showControls;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final VoidCallback? onResetZoom;
  final Function(double)? onScaleChanged;

  const ZoomableImageView({
    super.key,
    required this.imagePath,
    this.enableMouseWheel = true,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.showControls = true,
    this.errorBuilder,
    this.onResetZoom,
    this.onScaleChanged,
  });

  @override
  State<ZoomableImageView> createState() => _ZoomableImageViewState();
}

class _ZoomableImageViewState extends State<ZoomableImageView> {
  late TransformationController _transformationController;
  // ignore: unused_field
  bool _isZoomed = false; // 為未來的縮放UI功能預留

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerSignal: widget.enableMouseWheel ? _handlePointerSignal : null,
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            onInteractionStart: _handleInteractionStart,
            onInteractionEnd: _handleInteractionEnd,
            child: Center(
              child: _buildImageWidget(theme),
            ),
          ),
          // if (widget.showControls) ...[
          //   Positioned(
          //     top: 16,
          //     right: 16,
          //     child: Container(
          //       decoration: BoxDecoration(
          //         color: theme.colorScheme.surface.withOpacity(0.9),
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           IconButton(
          //             icon: const Icon(Icons.zoom_in),
          //             onPressed: () => _handleZoom(0.5),
          //             tooltip: 'Zoom In',
          //           ),
          //           IconButton(
          //             icon: const Icon(Icons.zoom_out),
          //             onPressed: () => _handleZoom(-0.5),
          //             tooltip: 'Zoom Out',
          //           ),
          //           if (_isZoomed)
          //             IconButton(
          //               icon: const Icon(Icons.zoom_out_map),
          //               onPressed: _resetZoom,
          //               tooltip: 'Reset Zoom',
          //             ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  /// Builds the appropriate image widget based on file extension
  Widget _buildImageWidget(ThemeData theme) {
    final path = widget.imagePath;
    final extension = path.toLowerCase().split('.').last;
    final isSvg = extension == 'svg';
    final l10n = AppLocalizations.of(context);

    if (isSvg) {
      // SVG rendering with error handling
      return _buildSvgImageSafe(path, theme);
    } else {
      // Regular image rendering
      return CachedImage(
        path: path,
        fit: BoxFit.contain,
        errorBuilder: widget.errorBuilder ??
            (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.imageLoadError(error.toString()),
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
      );
    }
  }

  Widget _buildSvgImageSafe(String path, ThemeData theme) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<void>(
      future: _validateSvgFile(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(
                context,
                snapshot.error!,
                snapshot.stackTrace,
              ) ??
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.imageLoadError('SVG文件加载失败: ${snapshot.error}'),
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
        }

        return CrossPlatformSvgPicture.fromPath(
          path,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  // 用于预先验证SVG文件的方法
  Future<void> _validateSvgFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('SVG文件不存在: $path');
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw Exception('SVG文件为空');
      }

      if (!content.toLowerCase().contains('<svg')) {
        throw Exception('不是有效的SVG文件格式');
      }
    } catch (e) {
      throw Exception('SVG文件验证失败: $e');
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    final matrix = _transformationController.value;
    if (matrix == Matrix4.identity()) {
      setState(() => _isZoomed = false);
      widget.onScaleChanged?.call(1.0);
    }
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    if (details.pointerCount > 1) {
      setState(() => _isZoomed = true);
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      final delta = event.scrollDelta.dy * 0.001;
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      final newScale =
          (currentScale - delta).clamp(widget.minScale, widget.maxScale);

      _transformationController.value = Matrix4.identity()..scale(newScale);

      setState(() => _isZoomed = newScale > 1.0);
      widget.onScaleChanged?.call(newScale);
    }
  }
}
