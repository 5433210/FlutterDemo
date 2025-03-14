import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/logger.dart';

class BaseImagePreview extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(int)? onIndexChanged;
  final bool showThumbnails;
  final bool enableZoom;
  final BoxDecoration? previewDecoration;
  final EdgeInsets? padding;

  const BaseImagePreview({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showThumbnails = true,
    this.enableZoom = true,
    this.previewDecoration,
    this.padding,
  });

  @override
  State<BaseImagePreview> createState() => _BaseImagePreviewState();
}

class _BaseImagePreviewState extends State<BaseImagePreview> {
  static const double _minZoomScale = 0.1;
  static const double _maxZoomScale = 10.0;
  static const EdgeInsets _viewerPadding = EdgeInsets.all(20.0);

  final TransformationController _transformationController =
      TransformationController();
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('BaseImagePreview build', tag: 'BaseImagePreview', data: {
      'hasPaths': widget.imagePaths.isNotEmpty,
      'pathCount': widget.imagePaths.length,
      'currentIndex': _currentIndex,
      'currentPath': widget.imagePaths.isNotEmpty
          ? widget.imagePaths[_currentIndex]
          : null,
    });

    return Container(
      decoration: widget.previewDecoration ??
          BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
      child: widget.imagePaths.isNotEmpty
          ? _buildImageViewer()
          : const Center(child: Text('没有图片')),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imagePaths.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
  }

  Widget _buildImageViewer() {
    final currentPath = widget.imagePaths[_currentIndex];
    final file = File(currentPath);

    // Check if file exists
    AppLogger.debug('BaseImagePreview loading image',
        tag: 'BaseImagePreview',
        data: {
          'path': currentPath,
          'exists': file.existsSync(),
          'size': file.existsSync() ? file.lengthSync() : null,
        });

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (_isZoomed) return; // 如果已缩放则不切换图片

        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 0 && _currentIndex > 0) {
          // 向右滑动，显示上一张
          _updateIndex(_currentIndex - 1);
        } else if (details.primaryVelocity! < 0 &&
            _currentIndex < widget.imagePaths.length - 1) {
          // 向左滑动，显示下一张
          _updateIndex(_currentIndex + 1);
        }
      },
      onTapDown: (details) {
        if (_isZoomed) return; // 如果已缩放则不切换图片

        final x = details.localPosition.dx;
        final screenWidth = context.size?.width ?? 0;
        if (x < screenWidth / 3) {
          // 点击左侧三分之一区域，显示上一张
          if (_currentIndex > 0) {
            _updateIndex(_currentIndex - 1);
          }
        } else if (x > screenWidth * 2 / 3) {
          // 点击右侧三分之一区域，显示下一张
          if (_currentIndex < widget.imagePaths.length - 1) {
            _updateIndex(_currentIndex + 1);
          }
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: _viewerPadding,
        minScale: _minZoomScale,
        maxScale: _maxZoomScale,
        onInteractionStart: (details) {
          if (details.pointerCount > 1) {
            _isZoomed = true;
          }
        },
        onInteractionEnd: (details) {
          // 检查是否恢复到原始大小
          final matrix = _transformationController.value;
          if (matrix == Matrix4.identity()) {
            _isZoomed = false;
          }
        },
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Image.file(
              file,
              key: ValueKey(currentPath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error(
                  '图片加载失败',
                  tag: 'BaseImagePreview',
                  error: error,
                  stackTrace: stackTrace,
                  data: {'path': currentPath},
                );
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('图片加载失败', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _updateIndex(int newIndex) {
    if (newIndex != _currentIndex &&
        newIndex >= 0 &&
        newIndex < widget.imagePaths.length) {
      setState(() {
        _currentIndex = newIndex;
        // 重置缩放
        _transformationController.value = Matrix4.identity();
        _isZoomed = false;
      });
      widget.onIndexChanged?.call(_currentIndex);
    }
  }
}
