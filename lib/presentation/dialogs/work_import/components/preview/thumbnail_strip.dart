import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_sizes.dart';

class ThumbnailStrip extends StatefulWidget {
  final List<File> images;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelect,
    required this.onRemove,
    this.onReorder,
  });

  @override
  State<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailItem extends StatelessWidget {
  final File image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final int index;

  const _ThumbnailItem({
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '图片 $index',
      selected: isSelected,
      onTapHint: '选择图片',
      child: Padding(
        padding: const EdgeInsets.only(right: AppSizes.m),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSizes.xs),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSizes.xs),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: image.path,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.xs),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: frame != null
                              ? child
                              : Container(
                                  color: theme.colorScheme.surface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                        );
                      },
                      errorBuilder: (context, error, _) => Container(
                        padding: const EdgeInsets.all(AppSizes.s),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.errorContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.xs),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              '加载失败',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 序号指示器
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: AppSizes.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppSizes.xxs),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '$index',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
                // 删除按钮
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Tooltip(
                      message: '移除图片',
                      child: IconButton.filled(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onRemove();
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailStripState extends State<ThumbnailStrip> {
  late final ScrollController _scrollController;
  bool _isDragging = false;
  Timer? _scrollTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false, // 使用自定义滚动条
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.m,
              vertical: AppSizes.s,
            ),
            buildDefaultDragHandles: false,
            proxyDecorator: _proxyDecorator,
            onReorderStart: (index) {
              setState(() => _isDragging = true);
              HapticFeedback.selectionClick();
              SystemSound.play(SystemSoundType.click);
            },
            onReorderEnd: (_) {
              setState(() => _isDragging = false);
              _scrollToSelected();
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex--;
              widget.onReorder?.call(oldIndex, newIndex);

              // 添加触觉反馈
              HapticFeedback.mediumImpact();
              SystemSound.play(SystemSoundType.click);

              // 更新滚动位置
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelected();
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return RepaintBoundary(
                key: ValueKey(image.path),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: _ThumbnailItem(
                        image: image,
                        isSelected: index == widget.selectedIndex,
                        onTap: () => widget.onSelect(index),
                        onRemove: () => widget.onRemove(index),
                        index: index + 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 延迟检查滚动状态，确保视图已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeEnableScroll());
  }

  void _maybeEnableScroll() {
    // 确保控制器已经连接到视图
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    try {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        setState(() {}); // 触发重建以更新滚动行为
      }
    } catch (e) {
      // 忽略可能的滚动控制器错误
      debugPrint('ScrollController error: $e');
    }
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 0.9).animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(animation),
        child: Material(
          elevation: animation.value * 8.0,
          color: Colors.transparent,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(AppSizes.xs),
          child: child,
        ),
      ),
    );
  }

  void _scrollToSelected() {
    if (!mounted || !_scrollController.hasClients || widget.selectedIndex < 0) {
      return;
    }

    try {
      final viewportWidth = _scrollController.position.viewportDimension;
      final itemWidth = 100.0 + AppSizes.m; // thumbnail width + padding
      final targetOffset = widget.selectedIndex * itemWidth;

      // 计算目标位置，使选中项尽可能居中
      final offset = (targetOffset - (viewportWidth - itemWidth) / 2)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      // 忽略滚动控制器错误
      debugPrint('ScrollToSelected error: $e');
    }
  }
}
