import 'package:flutter/material.dart';

/// 页面缩略图条组件
class PageThumbnailStrip extends StatelessWidget {
  final List<Map<String, dynamic>> pages;
  final int currentPageIndex;
  final Function(int) onPageSelected;
  final VoidCallback onAddPage;
  final VoidCallback onDeletePage;

  const PageThumbnailStrip({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onDeletePage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 页面操作按钮
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '添加页面',
                  onPressed: onAddPage,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除页面',
                  onPressed: currentPageIndex < pages.length
                      ? onDeletePage
                      : null,
                ),
                const Spacer(),
                Text(
                  '第 ${currentPageIndex + 1} 页 / 共 ${pages.length} 页',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // 页面缩略图列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: pages.length + 1, // +1 用于添加按钮
              itemBuilder: (context, index) {
                if (index == pages.length) {
                  // 最后一个是添加页面按钮
                  return _buildAddPageButton();
                } else {
                  return _buildPageThumbnail(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建添加页面按钮
  Widget _buildAddPageButton() {
    return GestureDetector(
      onTap: onAddPage,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  /// 构建页面缩略图
  Widget _buildPageThumbnail(int index) {
    final isSelected = index == currentPageIndex;

    return GestureDetector(
      onTap: () => onPageSelected(index),
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)]
              : null,
        ),
        child: Stack(
          children: [
            // 页面预览
            Center(
              child: Text('第 ${index + 1} 页'),
            ),

            // 页码指示
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
