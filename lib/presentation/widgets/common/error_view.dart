import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// 通用错误视图
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showBackground;
  final Color? backgroundColor;
  final IconData? icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.showBackground = false,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSizes.m),
        Text(
          message,
          style: TextStyle(color: theme.colorScheme.error),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSizes.m),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ],
    );

    if (showBackground) {
      content = Container(
        color: bgColor,
        padding: const EdgeInsets.all(AppSizes.m),
        child: content,
      );
    }

    return Center(child: content);
  }
}
