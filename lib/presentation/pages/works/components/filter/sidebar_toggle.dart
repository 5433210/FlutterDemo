import 'package:flutter/material.dart';

import '../../../../../theme/app_sizes.dart'; // 添加这个导入

class SidebarToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const SidebarToggle({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // 使用match_parent高度以填充父容器高度
      height: double.infinity,
      width: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        // 根据打开/关闭状态控制边框样式
        border: Border(
          // 仅在打开状态时显示左边框
          left: isOpen
              ? BorderSide(
                  color: theme.dividerColor, width: AppSizes.dividerThickness)
              : BorderSide.none,
          // 无论开关状态都显示右边框
          right: BorderSide(
              color: theme.dividerColor, width: AppSizes.dividerThickness),
        ),
      ),
      alignment: Alignment.center,
      child: IconButton(
        icon: Icon(
          isOpen ? Icons.chevron_left : Icons.chevron_right,
          color: theme.colorScheme.onSurface,
        ),
        tooltip: isOpen ? '收起侧边栏' : '展开侧边栏',
        onPressed: onToggle,
      ),
    );
  }
}
