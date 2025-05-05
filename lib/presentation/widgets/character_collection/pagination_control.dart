import 'package:flutter/material.dart';

class PaginationControl extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationControl({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 显示范围文本
          Text(
            _getDisplayRange(),
            style: theme.textTheme.bodyMedium,
          ),

          // 分页控件
          Row(
            children: [
              // 首页按钮
              _buildPageButton(
                context,
                1,
                icon: Icons.first_page,
                enabled: currentPage > 1,
              ),

              // 上一页按钮
              _buildPageButton(
                context,
                currentPage - 1,
                icon: Icons.chevron_left,
                enabled: currentPage > 1,
              ),

              // 页码按钮
              ..._buildPageNumberButtons(context),

              // 下一页按钮
              _buildPageButton(
                context,
                currentPage + 1,
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages,
              ),

              // 末页按钮
              _buildPageButton(
                context,
                totalPages,
                icon: Icons.last_page,
                enabled: currentPage < totalPages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(BuildContext context, int targetPage,
      {required IconData icon, required bool enabled}) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? () => onPageChanged(targetPage) : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: enabled ? theme.dividerColor : theme.disabledColor,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumberButtons(BuildContext context) {
    final List<Widget> buttons = [];
    final theme = Theme.of(context);

    // 决定显示哪些页码按钮
    int startPage, endPage;
    if (totalPages <= 5) {
      // 少于5页全部显示
      startPage = 1;
      endPage = totalPages;
    } else if (currentPage <= 3) {
      // 当前页靠近开始
      startPage = 1;
      endPage = 5;
    } else if (currentPage >= totalPages - 2) {
      // 当前页靠近结束
      startPage = totalPages - 4;
      endPage = totalPages;
    } else {
      // 当前页在中间
      startPage = currentPage - 2;
      endPage = currentPage + 2;
    }

    // 创建页码按钮
    for (int i = startPage; i <= endPage; i++) {
      final isCurrentPage = i == currentPage;

      buttons.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: isCurrentPage ? null : () => onPageChanged(i),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentPage ? theme.colorScheme.primary : null,
                borderRadius: BorderRadius.circular(4),
                border: isCurrentPage
                    ? null
                    : Border.all(color: theme.dividerColor),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: isCurrentPage
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight:
                      isCurrentPage ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  String _getDisplayRange() {
    // 这里应该根据实际每页显示的数量计算
    // 假设每页16个项目
    const itemsPerPage = 16;
    final start = (currentPage - 1) * itemsPerPage + 1;
    final end = currentPage * itemsPerPage;
    return '$start-$end / ${totalPages * itemsPerPage}';
  }
}
