import 'dart:io';

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../image/cached_image.dart';

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
  final Map<String, bool> _fileExistsCache = {};

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
      child: widget.imagePaths.isEmpty
          ? Center(child: Text(AppLocalizations.of(context).noImages))
          : _buildImageViewer(),
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
    _checkImageFiles();
  }

  Widget _buildImageViewer() {
    final currentPath = widget.imagePaths[_currentIndex];
    final fileExists = _fileExistsCache[currentPath] ?? false;
    if (!fileExists) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).imageFileNotExists),
          ],
        ),
      );
    }

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
            child: CachedImage(
              path: currentPath,
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context).imageLoadFailed,
                          style: const TextStyle(color: Colors.red)),
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

  Future<void> _checkImageFiles() async {
    for (final path in widget.imagePaths) {
      try {
        final file = File(path);
        _fileExistsCache[path] = await file.exists();
      } catch (e) {
        _fileExistsCache[path] = false;
        AppLogger.error('检查图片文件失败',
            tag: 'BaseImagePreview', error: e, data: {'path': path});
      }
    }
    if (mounted) {
      setState(() {});
    }
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
