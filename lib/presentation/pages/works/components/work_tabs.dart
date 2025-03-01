import 'package:flutter/material.dart';

/// 作品详情页的标签页组件
class WorkTabs extends StatelessWidget {
  /// 当前选中的标签页索引
  final int selectedIndex;

  /// 标签页切换回调
  final Function(int) onTabSelected;

  const WorkTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: selectedIndex,
      child: TabBar(
        onTap: onTabSelected,
        tabs: const [
          Tab(text: '基本信息'),
          Tab(text: '标签管理'), // 原为"图片管理"
          Tab(text: '集字信息'), // 原为"字形标注"
        ],
      ),
    );
  }

  /// 构建单个标签页按钮
  Widget _buildTab(
      BuildContext context, int index, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
