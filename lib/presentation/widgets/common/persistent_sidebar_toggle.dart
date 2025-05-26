import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/persistent_panel_provider.dart';

/// A sidebar toggle button with persistent state.
/// The open/close state will be remembered between app sessions.
class PersistentSidebarToggle extends ConsumerWidget {
  /// Unique identifier for this sidebar to persist its state
  final String sidebarId;

  /// Default state when no saved state exists
  final bool defaultIsOpen;

  /// Callback when the toggle state changes
  final ValueChanged<bool>? onToggle;

  /// Whether to align the toggle button to the right side
  final bool alignRight;

  /// Optional override for the current state (if provided, this will be used instead of persistent state)
  final bool? overrideState;

  const PersistentSidebarToggle({
    super.key,
    required this.sidebarId,
    this.defaultIsOpen = false,
    this.onToggle,
    this.alignRight = false,
    this.overrideState,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Get the persistent state
    final persistentIsOpen = ref.watch(sidebarStateProvider((
      sidebarId: sidebarId,
      defaultState: defaultIsOpen,
    )));

    // Use override state if provided, otherwise use persistent state
    final currentIsOpen = overrideState ?? persistentIsOpen;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Toggle the persistent state
          ref.read(persistentPanelProvider.notifier).toggleSidebar(
                sidebarId,
                defaultState: defaultIsOpen,
              );

          // Call the external callback with the new state
          final newState = !currentIsOpen;
          onToggle?.call(newState);
        },
        child: SizedBox(
          width: 10,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(
                // Fix icon direction logic
                alignRight
                    // Right panel (details page)
                    ? (currentIsOpen ? Icons.chevron_right : Icons.chevron_left)
                    // Left panel (browse page)
                    : (currentIsOpen
                        ? Icons.chevron_left
                        : Icons.chevron_right),
                size: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
