import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_sizes.dart';
import '../../../viewmodels/states/character_management_state.dart';

/// Character management toolbar
class CharacterToolbar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: AppSizes.appBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMedium,
        vertical: AppSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Batch mode toggle
          IconButton(
            onPressed: onToggleBatchMode,
            icon: Icon(
              isBatchMode ? Icons.cancel : Icons.check_box_outlined,
              color: isBatchMode ? theme.colorScheme.primary : null,
            ),
            tooltip: isBatchMode ? '退出批量模式' : '批量操作',
          ),

          if (isBatchMode) ...[
            const SizedBox(width: 8),

            // Selection count and delete button
            Chip(
              label: Text('已选择: $selectedCount'),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: selectedCount > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (selectedCount > 0) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('删除'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],

          const Spacer(),

          // View mode toggle
          IconButton(
            onPressed: onToggleViewMode,
            icon: Icon(
                viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view),
            tooltip: viewMode == ViewMode.grid ? '列表视图' : '网格视图',
          ),

          const SizedBox(width: AppSizes.spacingSmall),

          // Search box
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索字符、作品或作者',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
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
      ),
    );
  }
}
