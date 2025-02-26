import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

class PageBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final double? toolbarHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PageBar({
    super.key,
    this.title,
    this.actions,
    this.toolbarHeight,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight ?? AppSizes.pageToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.primaryColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (title != null)
            DefaultTextStyle(
              style: theme.textTheme.titleLarge!.copyWith(
                color: foregroundColor ?? Colors.white,
              ),
              child: title!,
            ),
          const Spacer(),
          if (actions != null) Row(children: actions!),
        ],
      ),
    );
  }
}
