import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';

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
      width: 24,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.m),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSizes.xxs),
            ),
            child: Icon(
              isOpen ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
