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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用宽度决定显示紧凑版本还是完整版本
          final availableWidth = constraints.maxWidth;

          if (availableWidth < 400) {
            // 紧凑版本：只显示基本导航
            return _buildCompactPagination(context);
          } else if (availableWidth < 600) {
            // 中等版本：显示简化的导航
            return _buildMediumPagination(context);
          } else {
            // 完整版本：显示所有控件
            return _buildFullPagination(context);
          }
        },
      ),
    );
  }

  /// 紧凑版本分页控件（宽度 < 400px）
  Widget _buildCompactPagination(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 页码显示
        Text(
          '$currentPage/$totalPages',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),

        // 基本导航按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactButton(
              context,
              currentPage - 1,
              icon: Icons.chevron_left,
              enabled: currentPage > 1,
            ),
            const SizedBox(width: 8),
            _buildCompactButton(
              context,
              currentPage + 1,
              icon: Icons.chevron_right,
              enabled: currentPage < totalPages,
            ),
          ],
        ),
      ],
    );
  }

  /// 中等版本分页控件（400px <= 宽度 < 600px）
  Widget _buildMediumPagination(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 简化的范围文本
        Text(
          _getCompactDisplayRange(),
          style: theme.textTheme.bodySmall,
        ),

        // 导航控件
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageButton(
              context,
              1,
              icon: Icons.first_page,
              enabled: currentPage > 1,
            ),

            _buildPageButton(
              context,
              currentPage - 1,
              icon: Icons.chevron_left,
              enabled: currentPage > 1,
            ),

            // 页码显示（不显示多个页码按钮）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$currentPage',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            _buildPageButton(
              context,
              currentPage + 1,
              icon: Icons.chevron_right,
              enabled: currentPage < totalPages,
            ),

            _buildPageButton(
              context,
              totalPages,
              icon: Icons.last_page,
              enabled: currentPage < totalPages,
            ),
          ],
        ),
      ],
    );
  }

  /// 完整版本分页控件（宽度 >= 600px）
  Widget _buildFullPagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 显示范围文本
        Text(
          _getDisplayRange(),
          style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  /// 构建紧凑版本的按钮
  Widget _buildCompactButton(BuildContext context, int targetPage,
      {required IconData icon, required bool enabled}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? () => onPageChanged(targetPage) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: enabled
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.disabledColor.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? theme.colorScheme.primary : theme.disabledColor,
        ),
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
    final totalItems = totalPages * itemsPerPage;
    return '共$totalItems个';
  }

  String _getCompactDisplayRange() {
    // 紧凑版本的显示范围
    const itemsPerPage = 16;
    final totalItems = totalPages * itemsPerPage;
    return '共$totalItems个';
  }
}
