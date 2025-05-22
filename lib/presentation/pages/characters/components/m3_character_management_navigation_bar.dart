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
  final VoidCallback? onCopySelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final bool isGridView;
  final VoidCallback onToggleViewMode;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final VoidCallback? onBackPressed;

  const M3CharacterManagementNavigationBar({
    super.key,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    this.onDeleteSelected,
    this.onCopySelected,
    this.onSelectAll,
    this.onClearSelection,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.searchController,
    this.onBackPressed,
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
      onBackPressed: widget.onBackPressed,
      titleActions: widget.isBatchMode
          ? [
              const SizedBox(width: AppSizes.m),
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
              // if (widget.selectedCount > 0) ...[
              //   Padding(
              //     padding: const EdgeInsets.only(left: AppSizes.s),
              //     child: FilledButton.tonalIcon(
              //       icon: const Icon(Icons.delete),
              //       label: Text(l10n.characterManagementDeleteSelected),
              //       onPressed: widget.onDeleteSelected,
              //     ),
              //   ),
              //   Padding(
              //     padding: const EdgeInsets.only(left: AppSizes.s),
              //     child: FilledButton.tonalIcon(
              //       icon: const Icon(Icons.copy),
              //       label: Text(l10n.practiceEditCopy),
              //       onPressed: widget.onCopySelected,
              //     ),
              //   ),
              // ],
            ]
          : null,
      actions: [
        // 右侧按钮组
        // 批量删除按钮
        if (widget.isBatchMode && widget.selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.characterManagementDeleteSelected,
            onPressed: widget.onDeleteSelected,
          ), // 复制按钮
        if (widget.isBatchMode && widget.selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.practiceEditCopy,
            onPressed: widget.onCopySelected,
          ), // 全选按钮
        if (widget.isBatchMode && widget.onSelectAll != null)
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: l10n.filterSelectAll,
            onPressed: widget.onSelectAll,
          ),

        // 取消选择按钮
        if (widget.isBatchMode &&
            widget.selectedCount > 0 &&
            widget.onClearSelection != null)
          IconButton(
            icon: const Icon(Icons.deselect),
            tooltip: l10n.filterDeselectAll,
            onPressed: widget.onClearSelection,
          ),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip:
              widget.isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          onPressed: widget.onToggleBatchMode,
        ),
        // const SizedBox(width: AppSizes.s),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView ? l10n.listView : l10n.gridView,
          onPressed: widget.onToggleViewMode,
        ),
      ],
    );
  }
}
