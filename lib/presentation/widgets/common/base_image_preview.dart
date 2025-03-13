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
    _currentIndex = widget.initialIndex;
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

    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: _viewerPadding,
      minScale: _minZoomScale,
      maxScale: _maxZoomScale,
      child: Center(
        child: Image.file(
          file,
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
    );
  }
}
