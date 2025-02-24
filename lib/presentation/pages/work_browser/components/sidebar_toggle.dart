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
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 16,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              left: BorderSide(color: theme.dividerColor),
              right: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Center(
            child: Icon(
              isOpen ? Icons.chevron_left : Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}