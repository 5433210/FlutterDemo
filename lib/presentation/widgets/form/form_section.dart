import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class FormSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const FormSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.spacingMedium,
              right: AppSizes.spacingMedium,
              top: AppSizes.spacingMedium,
            ),
            child: Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
        ],
        Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
