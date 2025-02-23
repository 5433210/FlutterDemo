import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';

class DialogContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final VoidCallback? onClose;

  const DialogContainer({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.padding,
    this.width,
    this.height,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(AppSizes.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            if (onClose != null) const Divider(height: 24),
            Expanded(child: child),
            if (actions != null) ...[
              const SizedBox(height: AppSizes.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
