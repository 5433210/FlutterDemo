import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../theme/app_sizes.dart';

/// 缩略图条组件
/// T 可以是 File 或 WorkImage
class ThumbnailStrip<T> extends StatefulWidget {
  final List<T> images;
  final int selectedIndex;
  final Function(int) onTap;
  final bool isEditable;
  final Function(int, int)? onReorder;
  final bool useOriginalImage;
  final String Function(T image) pathResolver;
  final String Function(T image) keyResolver;
  final Function(int)? onRemove;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onTap,
    required this.pathResolver,
    required this.keyResolver,
    this.isEditable = false,
    this.onReorder,
    this.onRemove,
    this.useOriginalImage = false,
  });

  @override
  State<ThumbnailStrip<T>> createState() => _ThumbnailStripState<T>();
}

class _FileStatus {
  final bool exists;
  final DateTime lastModified;
  int checkAttempts = 0;

  _FileStatus({required this.exists, DateTime? lastModified})
      : lastModified = lastModified ?? DateTime.now();
}

class _ThumbnailStripState<T> extends State<ThumbnailStrip<T>> {
  static const double _thumbWidth = 100.0;
  static const double _thumbHeight = 100.0;
  static const double _thumbSpacing = 8.0;
  static const int _maxRetryAttempts = 3;
  final ScrollController _scrollController = ScrollController();
  final Map<String, _FileStatus> _fileStatus = {};
  bool _isDragging = false;
  Timer? _retryTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isEditable) {
      // 非编辑模式：普通的滚动列表
      return Listener(
        onPointerSignal: _handlePointerSignal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.images.length,
            itemBuilder: (context, index) =>
                _buildThumbnail(context, index, theme),
          ),
        ),
      );
    }

    // 编辑模式：可重排序的列表
    return ReorderableListView.builder(
      scrollController: _scrollController,
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      onReorderStart: (index) {
        setState(() => _isDragging = true);
        HapticFeedback.selectionClick();
      },
      onReorderEnd: (_) {
        setState(() => _isDragging = false);
        HapticFeedback.lightImpact();
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex--;
        widget.onReorder?.call(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevationValue = animation.value * 8.0;
            final scaleValue = 1.0 + math.min(0.2, animation.value * 0.1);
            final rotateValue = (1.0 - animation.value) * 0.1;

            return Transform(
              transform: Matrix4.identity()
                ..scale(scaleValue, scaleValue)
                ..rotateZ(rotateValue),
              alignment: Alignment.center,
              child: Material(
                elevation: elevationValue,
                color: Colors.transparent,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(4),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final thumbnail = _buildThumbnail(context, index, theme);
        return ReorderableDragStartListener(
          key: ValueKey(widget.keyResolver(widget.images[index])),
          index: index,
          enabled: !_isDragging,
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: thumbnail,
          ),
        );
      },
      itemCount: widget.images.length,
    );
  }

  @override
  void didUpdateWidget(ThumbnailStrip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache when images change to force re-checking
    if (widget.images.length != oldWidget.images.length ||
        !_listsEqual(widget.images, oldWidget.images, widget.keyResolver)) {
      _fileStatus.clear();
      _checkImageFiles();
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkImageFiles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  Widget _buildThumbnail(BuildContext context, int index, ThemeData theme) {
    final image = widget.images[index];
    final isSelected = index == widget.selectedIndex;
    final path = widget.pathResolver(image);
    final status = _fileStatus[path];
    final fileExists = status?.exists ?? false;
    final attemptCount = status?.checkAttempts ?? 0;

    // Display different messages based on retry attempts
    String errorMessage = '图片文件不存在';
    if (attemptCount > 0 && attemptCount < _maxRetryAttempts) {
      errorMessage = '正在重试加载图片 ($attemptCount/$_maxRetryAttempts)';
    } else if (attemptCount >= _maxRetryAttempts) {
      errorMessage = '图片加载失败，请检查文件路径';
    }

    final heroTag = fileExists
        ? '${path}_${status?.lastModified.millisecondsSinceEpoch}'
        : path;

    return GestureDetector(
      onTap: () {
        if (!_isDragging) {
          HapticFeedback.selectionClick();
          widget.onTap(index);
        }
      },
      child: Container(
        width: _thumbWidth,
        height: _thumbHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              if (fileExists)
                Hero(
                  tag: heroTag,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: frame != null
                            ? child
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(Icons.broken_image,
                          size: 32, color: theme.colorScheme.error),
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(Icons.image_not_supported,
                      size: 32,
                      color: theme.colorScheme.surfaceContainerHighest),
                ),

              // Index label
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Remove button
              if (isSelected && widget.onRemove != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: IconButton.filled(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onRemove!(index);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(24, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.xxs),
                      ),
                    ),
                  ),
                ),

              // Drag handle
              if (widget.isEditable && !_isDragging)
                Positioned(
                  right: 4,
                  bottom: isSelected && widget.onRemove != null ? 32 : 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Error indicator
              if (!fileExists)
                Center(
                  child: Tooltip(
                    message: errorMessage,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 24,
                          color: theme.colorScheme.error,
                        ),
                        if (attemptCount > 0 &&
                            attemptCount < _maxRetryAttempts)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkImageFiles() async {
    // Cancel any pending retries
    _retryTimer?.cancel();

    bool hasFailures = false;

    for (final image in widget.images) {
      try {
        final path = widget.pathResolver(image);

        // Try to open the file for reading - this is a stronger test than just exists()
        // as it verifies the file is fully accessible
        try {
          final file = File(path);
          if (await file.exists()) {
            // Try to read a small part of the file to ensure it's accessible
            final randomAccessFile = await file.open(mode: FileMode.read);
            try {
              // Read just a few bytes to verify file is accessible
              await randomAccessFile.read(4);
              _fileStatus[path] = _FileStatus(
                exists: true,
                lastModified: await file.lastModified(),
              );
            } finally {
              await randomAccessFile.close();
            }
          } else {
            final status = _fileStatus[path];
            final attempts = status?.checkAttempts ?? 0;

            _fileStatus[path] = _FileStatus(exists: false)
              ..checkAttempts = attempts + 1;

            if (attempts < _maxRetryAttempts) {
              hasFailures = true;
            }
          }
        } catch (e) {
          // The file exists but couldn't be accessed - treat as not ready yet
          AppLogger.debug(
            'File exists but not accessible yet',
            tag: 'ThumbnailStrip',
            data: {'path': path, 'error': e.toString()},
          );

          final status = _fileStatus[path];
          final attempts = status?.checkAttempts ?? 0;

          _fileStatus[path] = _FileStatus(exists: false)
            ..checkAttempts = attempts + 1;

          if (attempts < _maxRetryAttempts) {
            hasFailures = true;
          }
        }
      } catch (e) {
        _fileStatus[widget.pathResolver(image)] = _FileStatus(exists: false);
        hasFailures = true;
      }
    }

    if (mounted) setState(() {});

    // Schedule a retry if any files failed to load
    if (hasFailures) {
      _retryTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _checkImageFiles();
      });
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // 滚轮事件处理：垂直滚动转换为水平滚动
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          (_scrollController.offset + event.scrollDelta.dy)
              .clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    }
  }

  // Check if two lists of images are equal by comparing their keys
  bool _listsEqual(List<T> a, List<T> b, String Function(T) keyResolver) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (keyResolver(a[i]) != keyResolver(b[i])) return false;
    }
    return true;
  }

  void _scrollToSelected() {
    if (!mounted || !_scrollController.hasClients) return;

    final itemWidth = _thumbWidth + _thumbSpacing * 2;
    final viewportWidth = MediaQuery.of(context).size.width;
    final targetOffset = widget.selectedIndex * itemWidth;

    // 计算目标偏移，使选中项居中
    final offset = (targetOffset - (viewportWidth - itemWidth) / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}
