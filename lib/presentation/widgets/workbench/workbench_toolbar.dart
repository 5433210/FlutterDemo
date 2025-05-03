import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../common/base_navigation_bar.dart';

class WorkbenchToolbar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseNavigationBar(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSizes.m),
      title: Row(
        children: [
          if (title != null) Text(title!, style: theme.textTheme.titleMedium),
          if (tools != null) ...[
            const SizedBox(width: AppSizes.m),
            ...tools!,
          ],
        ],
      ),
      actions: actions,
    );
  }
}
