import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';

class PageToolbar extends StatelessWidget {
  final List<Widget>? leading;
  final List<Widget>? trailing;
  final double? height;

  const PageToolbar({
    super.key,
    this.leading,
    this.trailing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height ?? AppSizes.pageToolbarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMedium,
        vertical: AppSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            ...leading!,
            const Spacer(),
          ],
          if (trailing != null) ...trailing!,
        ],
      ),
    );
  }
}
