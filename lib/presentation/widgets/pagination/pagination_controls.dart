import 'package:flutter/material.dart';

/// 分页控件
class PaginationControls extends StatelessWidget {
  /// 当前页码
  final int currentPage;
  
  /// 每页数量
  final int pageSize;
  
  /// 总记录数
  final int totalItems;
  
  /// 页码变化回调
  final Function(int) onPageChanged;
  
  /// 显示的页码数量
  final int visiblePageCount;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    this.visiblePageCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / pageSize).ceil();
    
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          
          // 页码按钮
          ...buildPageButtons(context, totalPages),
          
          // 下一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
          
          // 页码信息
          const SizedBox(width: 16),
          Text(
            '$currentPage / $totalPages 页 (共$totalItems条)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  /// 构建页码按钮
  List<Widget> buildPageButtons(BuildContext context, int totalPages) {
    final List<Widget> buttons = [];
    
    // 计算显示的页码范围
    int startPage = currentPage - (visiblePageCount ~/ 2);
    int endPage = currentPage + (visiblePageCount ~/ 2);
    
    // 调整范围，确保不超出总页数
    if (startPage < 1) {
      startPage = 1;
      endPage = Math.min(totalPages, visiblePageCount);
    }
    
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = Math.max(1, totalPages - visiblePageCount + 1);
    }
    
    // 添加第一页按钮
    if (startPage > 1) {
      buttons.add(buildPageButton(context, 1));
      
      // 添加省略号
      if (startPage > 2) {
        buttons.add(const Text('...'));
      }
    }
    
    // 添加中间页码按钮
    for (int i = startPage; i <= endPage; i++) {
      buttons.add(buildPageButton(context, i));
    }
    
    // 添加最后一页按钮
    if (endPage < totalPages) {
      // 添加省略号
      if (endPage < totalPages - 1) {
        buttons.add(const Text('...'));
      }
      
      buttons.add(buildPageButton(context, totalPages));
    }
    
    return buttons;
  }
  
  /// 构建单个页码按钮
  Widget buildPageButton(BuildContext context, int page) {
    final isCurrentPage = page == currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPage
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isCurrentPage
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          minimumSize: const Size(40, 36),
        ),
        onPressed: isCurrentPage ? null : () => onPageChanged(page),
        child: Text('$page'),
      ),
    );
  }
}

/// 数学工具类
class Math {
  /// 返回两个数中的较小值
  static int min(int a, int b) => a < b ? a : b;
  
  /// 返回两个数中的较大值
  static int max(int a, int b) => a > b ? a : b;
}
