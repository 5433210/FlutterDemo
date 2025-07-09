import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/image/cached_image.dart';

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
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 100);
  static const double _scrollMultiplier = 2.0;

  final ScrollController _scrollController = ScrollController();
  final Map<String, _FileStatus> _fileStatus = {};
  bool _isDragging = false;
  Timer? _retryTimer;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug(
        'Building ThumbnailStrip with ${widget.images.length} images');
    final theme = Theme.of(context);

    if (!widget.isEditable) {
      return SizedBox(
        height: 120,
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: PointerDeviceKind.values.toSet(),
              physics: const BouncingScrollPhysics(),
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) =>
                  _buildThumbnail(context, index, theme),
            ),
          ),
        ),
      );
    }

    // 编辑模式：可重排序的列表
    return SizedBox(
      height: 120,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: PointerDeviceKind.values.toSet(),
            physics: const BouncingScrollPhysics(),
          ),
          child: ReorderableListView.builder(
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
              // 直接传递原始索引，让上层 Provider 统一处理索引调整逻辑
              AppLogger.debug('ThumbnailStrip onReorder', tag: 'ThumbnailStrip', data: {
                'oldIndex': oldIndex,
                'newIndex': newIndex,
                'totalImages': widget.images.length,
              });
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
              final itemKey =
                  ValueKey(widget.keyResolver(widget.images[index]));

              return ReorderableDragStartListener(
                key: itemKey,
                index: index,
                enabled: !_isDragging,
                child: MouseRegion(
                  cursor: _isDragging
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
                  child: Container(
                    key: itemKey, // Add key to the root widget of each item
                    child: thumbnail,
                  ),
                ),
              );
            },
            itemCount: widget.images.length,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ThumbnailStrip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

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
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
              if (fileExists)
                Hero(
                  tag: heroTag,
                  child: CachedImage(
                    path: path,
                    fit: BoxFit.cover,
                    key: ValueKey(heroTag),
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
                          .withValues(alpha: 0.8),
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
                          Icons.circle_rounded,
                          size: 24,
                          color: theme.colorScheme.surface,
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

        try {
          final file = File(path);
          if (await file.exists()) {
            final randomAccessFile = await file.open(mode: FileMode.read);
            try {
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

    if (hasFailures) {
      _retryTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _checkImageFiles();
      });
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    AppLogger.debug('收到指针信号事件: ${event.runtimeType}');

    if (event is PointerScrollEvent) {
      AppLogger.debug('滚动事件: delta=${event.scrollDelta}, kind=${event.kind}');

      if (!mounted || !_scrollController.hasClients) {
        AppLogger.debug('组件未挂载或滚动控制器未就绪');
        return;
      }

      final delta = event.scrollDelta;
      // 如果是水平滚动则直接使用，如果是垂直滚动则转换为水平方向
      final adjustedDelta =
          (delta.dx != 0 ? delta.dx : -delta.dy) * _scrollMultiplier;

      AppLogger.debug('调整后的滚动增量: $adjustedDelta');

      final newOffset = (_scrollController.offset + adjustedDelta)
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        newOffset,
        duration: _scrollAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _listsEqual(List<T> a, List<T> b, String Function(T) keyResolver) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (keyResolver(a[i]) != keyResolver(b[i])) return false;
    }
    return true;
  }

  void _scrollToSelected() {
    if (!mounted || !_scrollController.hasClients) return;

    const itemWidth = _thumbWidth + _thumbSpacing * 2;
    final viewportWidth = MediaQuery.of(context).size.width;
    final targetOffset = widget.selectedIndex * itemWidth;

    final offset = (targetOffset - (viewportWidth - itemWidth) / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}
