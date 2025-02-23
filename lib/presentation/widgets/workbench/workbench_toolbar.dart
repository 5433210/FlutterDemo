import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class WorkbenchToolbar extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final List<Widget>? tools;
  final EdgeInsetsGeometry? padding;

  const WorkbenchToolbar({
    super.key,
    this.title,
    this.actions,
    this.tools,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.spacingMedium),
      child: Row(
        children: [
          if (title != null)
            Text(title!, style: theme.textTheme.titleMedium),
          if (tools != null) ...[
            const SizedBox(width: AppSizes.spacingMedium),
            ...tools!,
          ],
          const Spacer(),
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}
