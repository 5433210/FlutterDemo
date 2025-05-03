import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import 'base_navigation_bar.dart';

/// A consistent navigation bar implementation for all pages
/// that includes back button and navigation title
class M3PageNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The title text to display
  final String title;

  /// Optional additional title widgets to show after the title
  final List<Widget>? titleActions;

  /// Whether to show the back button
  final bool showBackButton;

  /// Custom back button handler
  final VoidCallback? onBackPressed;

  /// Optional action buttons to display on the right
  final List<Widget>? actions;

  /// Whether to use shadow elevation
  final bool useElevation;

  /// Optional padding for the toolbar content
  final EdgeInsetsGeometry? padding;

  const M3PageNavigationBar({
    super.key,
    required this.title,
    this.titleActions,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.useElevation = false,
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseNavigationBar(
      leading: showBackButton
          ? BaseNavigationBar.createBackButton(
              context,
              onPressed: onBackPressed != null
                  ? () {
                      // Use the custom back handler if provided
                      onBackPressed!();
                    }
                  : () {
                      // Default back behavior with safety checks
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
            )
          : null,
      title: DefaultTextStyle(
        style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ) ??
            const TextStyle(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (titleActions != null) ...[
              const SizedBox(width: AppSizes.s),
              ...titleActions!,
            ],
          ],
        ),
      ),
      actions:
          actions != null ? _wrapActionsWithConsistentSpacing(actions!) : null,
      backgroundColor: theme.colorScheme.surface,
      useElevation: useElevation,
      padding: padding,
    );
  }

  /// Wraps action buttons with consistent spacing
  List<Widget> _wrapActionsWithConsistentSpacing(List<Widget> actionButtons) {
    // If there are no actions, return an empty list
    if (actionButtons.isEmpty) return [];

    // Create a new list with proper spacing
    final List<Widget> wrappedActions = [];

    // Add each action with proper spacing
    for (int i = 0; i < actionButtons.length; i++) {
      // Add the action
      wrappedActions.add(actionButtons[i]);

      // Add spacing after each action except the last one
      if (i < actionButtons.length - 1) {
        // Check if the current widget is already a SizedBox
        if (actionButtons[i] is! SizedBox) {
          wrappedActions.add(const SizedBox(width: AppSizes.m));
        }
      }
    }

    return wrappedActions;
  }
}
