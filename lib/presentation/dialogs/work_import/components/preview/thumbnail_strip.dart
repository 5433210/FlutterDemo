import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/models/work/work_image.dart';
import '../../../../../theme/app_sizes.dart';

class ThumbnailStrip extends StatefulWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onTap;
  final bool isEditable;
  final Function(int, int)? onReorder;
  final bool useOriginalImage;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onTap,
    this.isEditable = false,
    this.onReorder,
    this.useOriginalImage = false,
  });

  @override
  State<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<ThumbnailStrip> {
  static const double _thumbWidth = 100.0;
  static const double _thumbHeight = 100.0;
  static const double _thumbSpacing = 8.0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _fileExistsCache = {};
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isEditable) {
      // 非编辑模式：普通的滚动列表
      return ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (context, index) => _buildThumbnail(context, index, theme),
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
        if (widget.onReorder != null) {
          widget.onReorder!(oldIndex, newIndex);
        }
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevationValue = animation.value * 8.0;
            final scaleValue =
                1.0 + math.min(0.2, animation.value * 0.1); // 最大放大 1.1 倍
            final rotateValue = (1.0 - animation.value) * 0.1; // 轻微倾斜，最大 5.7 度

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
        if (!widget.isEditable) return thumbnail;

        return ReorderableDragStartListener(
          key: ValueKey(widget.images[index].id),
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
  void didUpdateWidget(ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      _checkImageFiles();
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkImageFiles();

    // 延迟滚动到选中项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  Widget _buildThumbnail(BuildContext context, int index, ThemeData theme) {
    final image = widget.images[index];
    final isSelected = index == widget.selectedIndex;
    final fileExists = _fileExistsCache[image.id] ?? false;

    // 选择合适的图片路径
    final imagePath = widget.useOriginalImage
        ? (image.originalPath.isNotEmpty ? image.originalPath : image.path)
        : (image.thumbnailPath.isNotEmpty ? image.thumbnailPath : image.path);

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
                  tag: image.id,
                  child: Image.file(
                    File(imagePath),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

              // Drag handle in edit mode
              if (widget.isEditable && !_isDragging)
                Positioned(
                  right: 4,
                  bottom: 4,
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
                    message: '图片文件不存在',
                    child: Icon(
                      Icons.error_outline,
                      size: 24,
                      color: theme.colorScheme.error,
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
    for (final image in widget.images) {
      try {
        final imagePath = widget.useOriginalImage
            ? (image.originalPath.isNotEmpty ? image.originalPath : image.path)
            : (image.thumbnailPath.isNotEmpty
                ? image.thumbnailPath
                : image.path);

        final file = File(imagePath);
        _fileExistsCache[image.id] = await file.exists();
      } catch (e) {
        _fileExistsCache[image.id] = false;
      }
    }
    if (mounted) setState(() {});
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
