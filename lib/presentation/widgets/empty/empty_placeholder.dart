import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final List<Widget>? actions;

  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Text(
            message,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (subMessage != null) ...[
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              subMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
