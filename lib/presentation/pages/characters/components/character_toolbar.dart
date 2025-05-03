import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../viewmodels/states/character_management_state.dart';
import '../../../widgets/common/base_navigation_bar.dart';

/// Character management toolbar
class CharacterToolbar extends ConsumerWidget implements PreferredSizeWidget {
  /// Search callback
  final Function(String) onSearch;

  /// Delete callback
  final VoidCallback onDelete;

  /// Whether in batch mode
  final bool isBatchMode;

  /// Toggle batch mode callback
  final VoidCallback onToggleBatchMode;

  /// Selected character count
  final int selectedCount;

  /// Toggle view mode callback
  final VoidCallback onToggleViewMode;

  /// Current view mode
  final ViewMode viewMode;

  /// Constructor
  const CharacterToolbar({
    super.key,
    required this.onSearch,
    required this.onDelete,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    required this.onToggleViewMode,
    required this.viewMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseNavigationBar(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMedium,
        vertical: AppSizes.spacingSmall,
      ),
      useElevation: true,
      title: Row(
        children: [
          // Batch mode toggle
          IconButton(
            onPressed: onToggleBatchMode,
            icon: Icon(
              isBatchMode ? Icons.cancel : Icons.check_box_outlined,
              color: isBatchMode ? theme.colorScheme.primary : null,
            ),
            tooltip: isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          ),

          if (isBatchMode) ...[
            const SizedBox(width: AppSizes.s),

            // Selection count and delete button
            Chip(
              label: Text(l10n.selectedCount(selectedCount)),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: selectedCount > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (selectedCount > 0) ...[
              const SizedBox(width: AppSizes.s),
              ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: Text(l10n.delete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        // View mode toggle
        BaseNavigationBar.createActionButton(
          icon: viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
          tooltip: viewMode == ViewMode.grid ? l10n.listView : l10n.gridView,
          onPressed: onToggleViewMode,
          isPrimary: true,
        ),

        const SizedBox(width: AppSizes.s),

        // Search box
        SizedBox(
          width: 200,
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchCharactersWorksAuthors,
              isDense: true,
              prefixIcon:
                  const Icon(Icons.search, size: AppSizes.searchBarIconSize),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              ),
            ),
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
      ],
    );
  }
}
