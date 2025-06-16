import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import 'm3_practice_list_item.dart';

/// Material 3 practice list view
class M3PracticeListView extends StatelessWidget {
  /// List of practices
  final List<Map<String, dynamic>> practices;

  /// Whether in batch mode
  final bool isBatchMode;

  /// Set of selected practice IDs
  final Set<String> selectedPractices;

  /// Callback when a practice is tapped
  final Function(String) onPracticeTap;

  /// Callback when a practice is long pressed
  final Function(String)? onPracticeLongPress;

  /// Callback when favorite is toggled
  final Function(String)? onToggleFavorite;

  /// Callback when tags are edited
  final Function(String, List<String>)? onTagsEdited;

  /// Whether the view is loading
  final bool isLoading;

  /// Error message to display
  final String? errorMessage;

  const M3PracticeListView({
    super.key,
    required this.practices,
    required this.isBatchMode,
    required this.selectedPractices,
    required this.onPracticeTap,
    this.onPracticeLongPress,
    this.onToggleFavorite,
    this.onTagsEdited,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (practices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noResults,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      itemCount: practices.length,
      itemBuilder: (context, index) {
        final practice = practices[index];
        final id = practice['id'] as String;

        return M3PracticeListItem(
          practice: practice,
          isSelected: selectedPractices.contains(id),
          isSelectionMode: isBatchMode,
          onTap: () => onPracticeTap(id),
          onLongPress: onPracticeLongPress != null
              ? () => onPracticeLongPress!(id)
              : null,
          onToggleFavorite:
              onToggleFavorite != null ? () => onToggleFavorite!(id) : null,
          onTagsEdited: (practiceId, newTags) {
            if (onTagsEdited != null) {
              onTagsEdited!(id, newTags);
            }
          },
        );
      },
    );
  }
}
