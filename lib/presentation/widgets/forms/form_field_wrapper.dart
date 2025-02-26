import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  final String? tooltip;

  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            if (required)
              Text(
                ' *',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (tooltip != null) ...[
              const SizedBox(width: AppSizes.xs),
              Tooltip(
                message: tooltip!,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.formFieldSpacing),
        child,
      ],
    );
  }
}
