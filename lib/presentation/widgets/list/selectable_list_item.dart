import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class SelectableListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showDivider;

  const SelectableListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.actions,
    this.onTap,
    this.selected = false,
    this.onSelected,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onSelected != null ? () => onSelected!(!selected) : onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            color: selected ? theme.colorScheme.primary.withOpacity(0.1) : null,
            child: Row(
              children: [
                if (onSelected != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSizes.spacingMedium,
                    ),
                    child: Checkbox(
                      value: selected,
                      onChanged: (value) => onSelected?.call(value ?? false),
                    ),
                  ),
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSizes.spacingMedium),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: theme.textTheme.titleMedium!,
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSizes.spacingTiny),
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(width: AppSizes.spacingMedium),
                  ...actions!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
