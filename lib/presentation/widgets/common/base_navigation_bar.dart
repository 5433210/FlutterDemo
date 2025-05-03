import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';

/// A base navigation bar component that provides consistent styling across the application.
/// This component serves as the foundation for all navigation bars and ensures visual consistency.
class BaseNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the navigation bar
  final Widget? title;

  /// Leading widget (usually a back button)
  final Widget? leading;

  /// Action widgets to display on the right side
  final List<Widget>? actions;

  /// Whether to center the title
  final bool centerTitle;

  /// Background color (defaults to theme.colorScheme.surface)
  final Color? backgroundColor;

  /// Whether to use shadow elevation (if false, will use bottom border instead)
  final bool useElevation;

  /// Bottom widget, usually a TabBar
  final PreferredSizeWidget? bottom;

  /// Optional padding for the navigation bar content
  final EdgeInsetsGeometry? padding;

  const BaseNavigationBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.useElevation = false,
    this.bottom,
    this.padding,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        bottom == null
            ? (useElevation
                ? AppSizes.appBarHeight
                : AppSizes.appBarHeight + 1.0) // Add 1.0 for divider height
            : AppSizes.appBarHeight + bottom!.preferredSize.height,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If padding is provided, we need to use a custom title widget that wraps the original title
    Widget? titleWidget = title;
    if (padding != null && title != null) {
      titleWidget = Padding(
        padding: padding!,
        child: DefaultTextStyle(
          style: theme.textTheme.titleLarge ?? const TextStyle(),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          child: title!,
        ),
      );
    }

    return Material(
      color: backgroundColor ?? colorScheme.surface,
      elevation: useElevation ? 2.0 : 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppSizes.appBarHeight,
            child: NavigationToolbar(
              leading: leading != null
                  ? ConstrainedBox(
                      constraints: BoxConstraints.tightFor(
                        width: padding?.horizontal != null
                            ? kToolbarHeight + padding!.horizontal
                            : kToolbarHeight,
                      ),
                      child: leading,
                    )
                  : null,
              middle: titleWidget,
              trailing: actions != null && actions!.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                  : null,
              centerMiddle: centerTitle,
              middleSpacing:
                  padding != null ? 0.0 : NavigationToolbar.kMiddleSpacing,
            ),
          ),
          // 只有在没有底部组件且不使用阴影时才添加分割线
          if (!useElevation && bottom == null)
            Container(
              height: 1.0,
              color: colorScheme.outlineVariant,
            ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }

  /// Helper method to create a consistent action button
  static Widget createActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = true,
    bool isPrimary = false,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: !isActive
                ? colorScheme.onSurface
                    .withAlpha(97) // ~38% opacity (0.38 * 255 ≈ 97)
                : (isPrimary
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }

  /// Helper method to create a standard back button with safety checks
  static Widget createBackButton(BuildContext context,
      {VoidCallback? onPressed}) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: l10n.back,
      onPressed: onPressed ??
          () {
            // Default back behavior with safety checks
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
    );
  }

  /// Helper method to create a standard toolbar section divider
  static Widget createDivider() {
    return const SizedBox(width: AppSizes.m);
  }

  /// Helper method to create a consistent toolbar section
  static Widget createToolbarSection(List<Widget> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
