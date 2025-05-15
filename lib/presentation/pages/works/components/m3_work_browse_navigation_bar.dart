import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../viewmodels/states/work_browse_state.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3WorkBrowseNavigationBar extends StatefulWidget
    implements PreferredSizeWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onImport;
  final ValueChanged<String> onSearch;
  final bool batchMode;
  final ValueChanged<bool> onBatchModeChanged;
  final int selectedCount;
  final VoidCallback onDeleteSelected;
  final VoidCallback? onBackPressed;

  const M3WorkBrowseNavigationBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onImport,
    required this.onSearch,
    required this.batchMode,
    required this.onBatchModeChanged,
    required this.selectedCount,
    required this.onDeleteSelected,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  State<M3WorkBrowseNavigationBar> createState() =>
      _M3WorkBrowseNavigationBarState();
}

class _M3WorkBrowseNavigationBarState extends State<M3WorkBrowseNavigationBar> {
  late final TextEditingController _searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return M3PageNavigationBar(
      title: l10n.workBrowseTitle,
      showBackButton: true, // 所有导航栏都应该有返回按钮
      onBackPressed: widget.onBackPressed,
      titleActions: [
        const SizedBox(width: AppSizes.s),
        if (widget.batchMode)
          Text(
            l10n.workBrowseSelectedCount(widget.selectedCount),
            style: theme.textTheme.bodyMedium,
          ),
      ],
      actions: [
        if (widget.batchMode && widget.selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.workBrowseDeleteSelected(widget.selectedCount),
            onPressed: _showDeleteConfirmation,
          )
        else if (!widget.batchMode)
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.workBrowseImport),
            onPressed: widget.onImport,
          ),

        // 右侧按钮组：从右向左排序
        // 导入或删除按钮

        // const SizedBox(width: AppSizes.s),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.batchMode ? Icons.close : Icons.checklist),
          tooltip: widget.batchMode
              ? l10n.workBrowseBatchDone
              : l10n.workBrowseBatchMode,
          onPressed: () => widget.onBatchModeChanged(!widget.batchMode),
        ),
        // const SizedBox(width: AppSizes.s),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.viewMode == ViewMode.grid
              ? Icons.view_list
              : Icons.grid_view),
          tooltip: widget.viewMode == ViewMode.grid
              ? l10n.workBrowseListView
              : l10n.workBrowseGridView,
          onPressed: () => widget.onViewModeChanged(
              widget.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid),
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
