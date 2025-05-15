import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../viewmodels/states/work_browse_state.dart';
import '../../../widgets/common/base_navigation_bar.dart';

class M3WorkBrowseToolbar extends StatefulWidget
    implements PreferredSizeWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onImport;
  final ValueChanged<String> onSearch;
  final bool batchMode;
  final ValueChanged<bool> onBatchModeChanged;
  final int selectedCount;
  final VoidCallback onDeleteSelected;

  const M3WorkBrowseToolbar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onImport,
    required this.onSearch,
    required this.batchMode,
    required this.onBatchModeChanged,
    required this.selectedCount,
    required this.onDeleteSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  State<M3WorkBrowseToolbar> createState() => _M3WorkBrowseToolbarState();
}

class _M3WorkBrowseToolbarState extends State<M3WorkBrowseToolbar> {
  late final TextEditingController _searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return BaseNavigationBar(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      title: Row(
        children: [
          // 左侧按钮组
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.workBrowseImport),
            onPressed: widget.onImport,
          ),
          const SizedBox(width: AppSizes.s),
          OutlinedButton.icon(
            icon: Icon(widget.batchMode ? Icons.close : Icons.checklist),
            label: Text(widget.batchMode
                ? l10n.workBrowseBatchDone
                : l10n.workBrowseBatchMode),
            onPressed: () => widget.onBatchModeChanged(!widget.batchMode),
          ),

          // 批量操作状态 - 统一样式
          if (widget.batchMode) ...[
            const SizedBox(width: AppSizes.m),
            Text(
              l10n.workBrowseSelectedCount(widget.selectedCount),
              style: theme.textTheme.bodyMedium,
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.s),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.delete),
                label: Text(l10n.workBrowseDeleteConfirmTitle),
                onPressed:
                    widget.selectedCount > 0 ? _showDeleteConfirmation : null,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // 右侧控制组
        SizedBox(
          child: SearchBar(
            controller: _searchController,
            onChanged: widget.onSearch,
            hintText: l10n.workBrowseSearch,
            leading: const Icon(Icons.search, size: AppSizes.searchBarIconSize),
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(
                        milliseconds: AppSizes.animationDurationMedium),
                    child: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: AppSizes.searchBarClearIconSize,
                      ),
                      onPressed: () {
                        _searchController.clear();
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
        BaseNavigationBar.createActionButton(
          icon: widget.viewMode == ViewMode.grid
              ? Icons.view_list
              : Icons.grid_view,
          tooltip: widget.viewMode == ViewMode.grid
              ? l10n.workBrowseListView
              : l10n.workBrowseGridView,
          onPressed: () => widget.onViewModeChanged(
              widget.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid),
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  void _showDeleteConfirmation() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workBrowseDeleteConfirmTitle),
        content:
            Text(l10n.workBrowseDeleteConfirmMessage(widget.selectedCount)),
        actions: [
          TextButton(
            child: Text(l10n.workBrowseCancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: Text(l10n.workBrowseDelete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDeleteSelected();
    }
  }
}
