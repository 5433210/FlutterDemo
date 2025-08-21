import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../image/cached_image.dart';

/// 高级图片预览组件
/// 支持左右切换、全屏显示、黑白背景切换、缩放和平移
class AdvancedImagePreview extends StatefulWidget {
  /// 图片路径列表
  final List<String> imagePaths;

  /// 初始选中的图片索引
  final int initialIndex;

  /// 图片索引变化回调
  final Function(int)? onIndexChanged;

  /// 是否显示底部缩略图
  final bool showThumbnails;

  /// 是否启用缩放
  final bool enableZoom;

  /// 是否全屏显示
  final bool isFullScreen;

  /// 全屏状态变化回调
  final Function(bool)? onFullScreenChanged;

  /// 容器装饰
  final BoxDecoration? previewDecoration;

  /// 内边距
  final EdgeInsets? padding;

  const AdvancedImagePreview({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showThumbnails = true,
    this.enableZoom = true,
    this.isFullScreen = false,
    this.onFullScreenChanged,
    this.previewDecoration,
    this.padding,
  });

  @override
  State<AdvancedImagePreview> createState() => _AdvancedImagePreviewState();
}

class _AdvancedImagePreviewState extends State<AdvancedImagePreview> {
  static const double _minZoomScale = 0.1;
  static const double _maxZoomScale = 10.0;
  static const EdgeInsets _viewerPadding = EdgeInsets.all(20.0);

  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, bool> _fileExistsCache = {};

  late int _currentIndex;
  bool _isZoomed = false;
  bool _isDarkBackground = false;
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: widget.previewDecoration ??
            BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
              color: _isDarkBackground 
                  ? Theme.of(context).colorScheme.onInverseSurface
                  : Theme.of(context).colorScheme.surface,
            ),
        child: widget.imagePaths.isEmpty
            ? Center(child: Text(AppLocalizations.of(context).noImages))
            : _buildImageViewer(context),
      ),
    );
  }

  @override
  void didUpdateWidget(AdvancedImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle image path changes
    if (widget.imagePaths != oldWidget.imagePaths) {
      _checkImageFiles();

      // Update current index if needed
      if (_currentIndex >= widget.imagePaths.length) {
        _currentIndex =
            widget.imagePaths.isEmpty ? 0 : widget.imagePaths.length - 1;
      }

      // Reset zoom when image changes
      _resetZoom();
    }

    // Handle initial index changes
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex < widget.imagePaths.length) {
      _updateIndex(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imagePaths.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _isFullScreen = widget.isFullScreen;
    _checkImageFiles();

    // 添加键盘监听
    _focusNode.requestFocus();
  }

  Widget _buildImageContent() {
    if (_currentIndex >= widget.imagePaths.length) {
      AppLogger.debug(
          '【AdvancedImagePreview】Current index out of bounds: $_currentIndex');
      return Center(
        child: Text(AppLocalizations.of(context).imageIndexError,
            style: const TextStyle(color: Colors.red)),
      );
    }

    final currentPath = widget.imagePaths[_currentIndex];
    AppLogger.debug(
        '【AdvancedImagePreview】Building image content for: $currentPath');
    final fileExists = _fileExistsCache[currentPath] ?? false;

    if (!fileExists) {
      AppLogger.debug(
          '【AdvancedImagePreview】Image file does not exist: $currentPath');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).imageFileNotExists,
              style: const TextStyle(color: Colors.white)),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: CachedImage(
        path: currentPath,
        key: ValueKey(currentPath), // Use ValueKey to ensure proper rebuilding
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.error(
            '图片加载失败',
            error: error,
            stackTrace: stackTrace,
            data: {'path': currentPath},
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).imageLoadFailed,
                  style: const TextStyle(color: Colors.red)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    AppLogger.debug('【AdvancedImagePreview】Building image viewer:');
    AppLogger.debug(
        '【AdvancedImagePreview】Image paths count: ${widget.imagePaths.length}');
    AppLogger.debug('【AdvancedImagePreview】Current index: $_currentIndex');
    AppLogger.debug(
        '【AdvancedImagePreview】Should show previous button: ${_currentIndex > 0}');
    AppLogger.debug(
        '【AdvancedImagePreview】Should show next button: ${_currentIndex < widget.imagePaths.length - 1}');
    AppLogger.debug('【AdvancedImagePreview】Image paths: ${widget.imagePaths}');

    return Stack(
      fit: StackFit.expand,
      children: [
        // 主图片区域
        GestureDetector(
          onDoubleTap: _toggleFullScreen,
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
                setState(() => _isZoomed = true);
              }
            },
            onInteractionEnd: (details) {
              // 检查是否恢复到原始大小
              final matrix = _transformationController.value;
              if (matrix == Matrix4.identity()) {
                setState(() => _isZoomed = false);
              }
            },
            child: Center(
              child: _buildImageContent(),
            ),
          ),
        ), // 上一张按钮 - 设置更高对比度和更明显的样式
        if (_currentIndex > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  color: Colors.white,
                  onPressed: () {
                    AppLogger.debug(
                        '【AdvancedImagePreview】Previous button pressed, moving from $_currentIndex to ${_currentIndex - 1}');
                    _updateIndex(_currentIndex - 1);
                  },
                  iconSize: 30,
                ),
              ),
            ),
          ), // 下一张按钮 - 设置更高对比度和更明显的样式
        if (_currentIndex < widget.imagePaths.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: Colors.white,
                  onPressed: () {
                    AppLogger.debug(
                        '【AdvancedImagePreview】Next button pressed, moving from $_currentIndex to ${_currentIndex + 1}');
                    _updateIndex(_currentIndex + 1);
                  },
                  iconSize: 30,
                ),
              ),
            ),
          ),

        // 添加缩略图条 - 仅在启用且非缩放状态显示
        if (widget.showThumbnails && !_isZoomed && widget.imagePaths.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildThumbnailStrip(),
          ),
      ],
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 80,
      color: Colors.black45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          final path = widget.imagePaths[index];
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () => _updateIndex(index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    path: path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkImageFiles() async {
    for (int i = 0; i < widget.imagePaths.length; i++) {
      final path = widget.imagePaths[i];
      try {
        final file = File(path);
        final exists = await file.exists();
        _fileExistsCache[path] = exists;
      } catch (e) {
        _fileExistsCache[path] = false;
        AppLogger.error('检查图片文件失败', error: e, data: {'path': path});
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_currentIndex > 0) {
          _updateIndex(_currentIndex - 1);
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (_currentIndex < widget.imagePaths.length - 1) {
          _updateIndex(_currentIndex + 1);
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.escape:
        if (_isFullScreen) {
          _toggleFullScreen();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.keyF:
        _toggleFullScreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        _toggleBackgroundColor();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyR:
        _resetZoom();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit0:
      case LogicalKeyboardKey.numpad0:
        _resetZoom();
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _isZoomed = false;
    });
  }

  void _toggleBackgroundColor() {
    setState(() {
      _isDarkBackground = !_isDarkBackground;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    // 重置缩放状态，避免全屏时出现缩放问题
    _resetZoom();

    // 通知父组件全屏状态已改变
    widget.onFullScreenChanged?.call(_isFullScreen);
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
