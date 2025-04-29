import 'package:flutter/material.dart';

class SidebarToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final bool alignRight; // 新增参数，控制箭头方向和对齐方式

  const SidebarToggle({
    super.key,
    required this.isOpen,
    required this.onToggle,
    this.alignRight = false, // 默认左对齐（用于浏览页）
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      // 根据alignRight参数调整圆角位置

      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: SizedBox(
          width: 10,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(
                // 修复图标方向逻辑
                alignRight
                    // 右侧面板（详情页）
                    ? (isOpen ? Icons.chevron_right : Icons.chevron_left)
                    // 右侧面板（浏览页）- 这里是反的，需要修复
                    : (isOpen ? Icons.chevron_left : Icons.chevron_right),
                size: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
