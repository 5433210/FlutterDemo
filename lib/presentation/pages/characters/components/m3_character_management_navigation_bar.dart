import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3CharacterManagementNavigationBar extends StatefulWidget
    implements PreferredSizeWidget {
  final bool isBatchMode;
  final VoidCallback onToggleBatchMode;
  final int selectedCount;
  final VoidCallback? onDeleteSelected;
  final bool isGridView;
  final VoidCallback onToggleViewMode;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;

  const M3CharacterManagementNavigationBar({
    super.key,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    this.onDeleteSelected,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.searchController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<M3CharacterManagementNavigationBar> createState() =>
      _M3CharacterManagementNavigationBarState();
}

class _M3CharacterManagementNavigationBarState
    extends State<M3CharacterManagementNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return M3PageNavigationBar(
      title: l10n.characterManagementTitle,
      titleActions: widget.isBatchMode
          ? [
              const SizedBox(width: AppSizes.m),
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.s),
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete),
                    label: Text(l10n.characterManagementDeleteSelected),
                    onPressed: widget.onDeleteSelected,
                  ),
                ),
            ]
          : null,
      actions: [
        // 搜索框
        SizedBox(
          width: 240,
          child: SearchBar(
            controller: widget.searchController,
            hintText: l10n.searchCharactersWorksAuthors,
            leading: const Icon(Icons.search, size: AppSizes.searchBarIconSize),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSizes.m),
            ),
            onChanged: widget.onSearch,
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.searchController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(
                        milliseconds: AppSizes.animationDurationMedium),
                    child: IconButton(
                      icon: const Icon(Icons.clear,
                          size: AppSizes.searchBarClearIconSize),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearch('');
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.m),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView ? l10n.listView : l10n.gridView,
          onPressed: widget.onToggleViewMode,
        ),
        const SizedBox(width: AppSizes.m),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip:
              widget.isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          onPressed: widget.onToggleBatchMode,
        ),
      ],
    );
  }
}
