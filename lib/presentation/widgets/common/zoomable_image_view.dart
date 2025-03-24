import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays an image with zoom and pan capabilities
class ZoomableImageView extends StatefulWidget {
  /// Path to the image file
  final String imagePath;

  /// Whether to enable mouse wheel zoom
  final bool enableMouseWheel;

  /// Minimum allowed scale
  final double minScale;

  /// Maximum allowed scale
  final double maxScale;

  /// Called when scale changes
  final Function(double)? onScaleChanged;

  /// Custom error widget builder
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// Custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional tap down callback for specialized interactions
  final Function(Offset)? onTapDown;

  /// Whether to enable gesture interactions
  final bool enableGestures;

  /// Called when zoom is reset
  final VoidCallback? onResetZoom;

  /// Whether to show zoom control buttons
  final bool showControls;

  const ZoomableImageView({
    super.key,
    required this.imagePath,
    this.enableMouseWheel = true,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.onScaleChanged,
    this.errorBuilder,
    this.loadingBuilder,
    this.onTapDown,
    this.onResetZoom,
    this.enableGestures = true,
    this.showControls = false,
  });

  @override
  State<ZoomableImageView> createState() => _ZoomableImageViewState();
}

class _ZoomableImageViewState extends State<ZoomableImageView> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main image with zoom
        Listener(
          onPointerSignal:
              widget.enableMouseWheel ? _handlePointerSignal : null,
          child: GestureDetector(
            onTapDown: widget.onTapDown != null
                ? (details) => widget.onTapDown!(details.localPosition)
                : null,
            child: InteractiveViewer(
              panEnabled: widget.enableGestures,
              transformationController: _transformationController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              onInteractionStart: _handleInteractionStart,
              onInteractionEnd: _handleInteractionEnd,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: frame != null
                        ? child
                        : widget.loadingBuilder?.call(context) ??
                            Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                  );
                },
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
                                '无法加载图片',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ),

        // Zoom controls
        if (widget.showControls && _isZoomed)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: _resetZoom,
              tooltip: '重置缩放',
              child: const Icon(Icons.zoom_out_map),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomed = false);
    widget.onScaleChanged?.call(1.0);
    widget.onResetZoom?.call();
  }
}
