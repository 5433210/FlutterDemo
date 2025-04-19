import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 页面缩略图条
class PageThumbnailStrip extends StatefulWidget {
  final List<Map<String, dynamic>> pages;
  final int currentPageIndex;
  final Function(int) onPageSelected;
  final VoidCallback onAddPage;
  final Function(int) onDeletePage;
  final Function(int, int)? onReorderPages;

  const PageThumbnailStrip({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onDeletePage,
    this.onReorderPages,
  });

  @override
  State<PageThumbnailStrip> createState() => _PageThumbnailStripState();
}

class _PageThumbnailStripState extends State<PageThumbnailStrip> {
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  // 滚动乘数
  final double _scrollMultiplier = 3.0;

  // 滚动动画时长
  final Duration _scrollAnimationDuration = const Duration(milliseconds: 200);

  // 拖动滚动相关变量
  bool _isDraggingStrip = false;
  double _dragStartX = 0.0;
  double _scrollStartOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade200,
      child: Material(
        // Add Material widget
        color: Colors.grey.shade200,
        child: GestureDetector(
          // 添加拖动滚动支持
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: Row(
              children: [
                // 页面缩略图列表
                Expanded(
                  child: widget.onReorderPages != null
                      ? _buildReorderablePageList(context)
                      : _buildSimplePageList(),
                ),

                // 添加页面按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAddPage,
                      child: Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 24, color: Colors.grey),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 构建页面缩略图
  Widget _buildPageThumbnail(Map<String, dynamic> page) {
    // 获取背景颜色 - 处理新旧数据格式
    Color color = Colors.white;

    // 检查是否有新格式的background属性
    if (page.containsKey('background') && page['background'] is Map) {
      final background = page['background'] as Map<String, dynamic>;
      final type = background['type'] as String? ?? 'color';
      final value = background['value'] as String? ?? '#FFFFFF';

      if (type == 'color' && value.isNotEmpty) {
        try {
          color = Color(int.parse(value.replaceAll('#', '0xFF')));
        } catch (e) {
          // 如果解析失败，使用默认白色
          color = Colors.white;
        }
      }
    }
    // 尝试使用旧格式属性
    else {
      final backgroundType = page['backgroundType'] as String? ?? 'color';
      final backgroundColor = page['backgroundColor'] as String? ?? '#FFFFFF';
      final backgroundOpacity =
          (page['backgroundOpacity'] as num?)?.toDouble() ?? 1.0;

      if (backgroundType == 'color' && backgroundColor.isNotEmpty) {
        try {
          final colorValue = int.parse(backgroundColor.replaceAll('#', '0xFF'));
          color = Color.fromRGBO(
            (colorValue >> 16) & 0xFF,
            (colorValue >> 8) & 0xFF,
            colorValue & 0xFF,
            backgroundOpacity,
          );
        } catch (e) {
          // 如果解析失败，使用默认白色
          color = Colors.white;
        }
      }
    }

    // 获取页面元素
    final elements = page['elements'] as List<dynamic>? ?? [];

    return Container(
      color: color,
      child: elements.isNotEmpty
          ? const Center(child: Text('预览', style: TextStyle(fontSize: 10)))
          : const Center(child: Text('空白', style: TextStyle(fontSize: 10))),
    );
  }

  Widget _buildReorderablePageList(BuildContext context) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      scrollController: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      proxyDecorator: (child, index, animation) {
        // Add nice visual effect during drag
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue =
                Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            final double scale = lerpDouble(1, 1.05, animValue)!;

            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black45,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (widget.onReorderPages != null) {
          widget.onReorderPages!(oldIndex, newIndex);
        }
      },
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        final page = widget.pages[index];
        final isSelected = index == widget.currentPageIndex;

        return Padding(
          key: ValueKey('page_${page['id']}'),
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => widget.onPageSelected(index),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Stack(
                children: [
                  // 页面缩略图
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.description, size: 24, color: Colors.grey),
                    ),
                  ),

                  // 删除按钮
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, size: 18),
                      color: Colors.red.shade400,
                      onPressed: () => widget.onDeletePage(index),
                      splashRadius: 18,
                      tooltip: '删除页面',
                    ),
                  ),

                  // 页码指示
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      color: isSelected
                          ? Colors.blue.withAlpha(179) // 0.7 opacity
                          : Colors.grey.withAlpha(153), // 0.6 opacity
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimplePageList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        final page = widget.pages[index];
        final isSelected = index == widget.currentPageIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => widget.onPageSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 缩略图
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withAlpha(77), // 0.3 opacity
                              spreadRadius: 1,
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  child: _buildPageThumbnail(page),
                ),

                const SizedBox(height: 4),

                // 页面名称和删除按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page['name'] as String? ?? 'Page ${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (widget.pages.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => widget.onDeletePage(index),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 处理拖动结束
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDraggingStrip = false;
    });
  }

  /// 处理拖动开始
  void _handleDragStart(DragStartDetails details) {
    if (!_scrollController.hasClients) return;

    setState(() {
      _isDraggingStrip = true;
      _dragStartX = details.globalPosition.dx;
      _scrollStartOffset = _scrollController.offset;
    });
  }

  /// 处理拖动更新
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_scrollController.hasClients || !_isDraggingStrip) return;

    // 计算拖动距离
    final dragDelta = _dragStartX - details.globalPosition.dx;

    // 计算新的滚动位置，并限制在有效范围内
    final newOffset = (_scrollStartOffset + dragDelta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    // 直接跳转到新位置（无动画）
    _scrollController.jumpTo(newOffset);
  }

  /// 处理鼠标滚轮事件
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // 如果滚动控制器未就绪，直接返回
      if (!_scrollController.hasClients) return;

      // 计算滚动增量，将垂直滚动转换为水平滚动
      final delta = event.scrollDelta;
      final adjustedDelta =
          (delta.dx != 0 ? delta.dx : delta.dy) * _scrollMultiplier;

      // 计算新的滚动位置，并限制在有效范围内
      final newOffset = (_scrollController.offset + adjustedDelta)
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      // 使用动画滚动到新位置
      _scrollController.animateTo(
        newOffset,
        duration: _scrollAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }
}
