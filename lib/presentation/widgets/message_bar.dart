import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';

class MessageBar extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const MessageBar({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: backgroundColor ?? theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor ?? Colors.white,
                size: AppSizes.iconMedium,
              ),
              const SizedBox(width: AppSizes.spacingSmall),
            ],
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: textColor ?? Colors.white,
                  size: AppSizes.iconSmall,
                ),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
