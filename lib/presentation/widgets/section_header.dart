import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppSizes.spacingMedium),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actions != null) ...[
            const Spacer(),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
