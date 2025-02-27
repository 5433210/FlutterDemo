import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget content;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  const InfoCard({
    super.key,
    required this.title,
    this.icon,
    required this.content,
    this.initiallyExpanded = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding:
            padding ?? const EdgeInsets.all(AppSizes.spacingMedium),
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [content],
      ),
    );
  }
}
