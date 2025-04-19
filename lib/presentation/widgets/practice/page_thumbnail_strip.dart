import 'dart:ui';

import 'package:flutter/material.dart';

/// 页面缩略图条
class PageThumbnailStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade200,
      child: Material(
        // Add Material widget
        color: Colors.grey.shade200,
        child: Row(
          children: [
            // 页面缩略图列表
            Expanded(
              child: onReorderPages != null
                  ? _buildReorderablePageList(context)
                  : _buildSimplePageList(),
            ),

            // 添加页面按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddPage,
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
    );
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
          color = Color(int.parse(backgroundColor.replaceAll('#', '0xFF')))
              .withOpacity(backgroundOpacity);
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
        if (onReorderPages != null) {
          onReorderPages!(oldIndex, newIndex);
        }
      },
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        final isSelected = index == currentPageIndex;

        return Padding(
          key: ValueKey('page_${page['id']}'),
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => onPageSelected(index),
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
                      onPressed: () => onDeletePage(index),
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
                          ? Colors.blue.withOpacity(0.7)
                          : Colors.grey.withOpacity(0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        final isSelected = index == currentPageIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => onPageSelected(index),
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
                              color: Colors.blue.withOpacity(0.3),
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
                    if (pages.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onDeletePage(index),
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
}
