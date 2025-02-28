import 'package:flutter/material.dart';

/// A standardized button for use in toolbars
class ToolbarActionButton extends StatelessWidget {
  /// The child widget to display (usually an Icon)
  final Widget child;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Tooltip text to show on hover
  final String? tooltip;

  /// Whether the button is enabled
  final bool enabled;

  /// Whether to show a loading indicator instead of the child
  final bool isLoading;

  const ToolbarActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled && !isLoading ? onPressed : null,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : IconTheme(
                      data: IconThemeData(
                        color: enabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.38),
                        size: 20,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
