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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(context, 0, '基本信息', Icons.info_outline),
          _buildTab(context, 1, '图片管理', Icons.image),
          _buildTab(context, 2, '字形标注', Icons.text_fields),
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
