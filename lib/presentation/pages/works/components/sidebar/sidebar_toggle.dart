import 'package:flutter/material.dart';

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
      height: 48,
      width: 48,
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
