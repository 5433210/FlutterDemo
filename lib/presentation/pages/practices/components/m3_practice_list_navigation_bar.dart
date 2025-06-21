import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3PracticeListNavigationBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onNewPractice;
  final VoidCallback onToggleBatchMode;
  final bool isBatchMode;
  final int selectedCount;
  final VoidCallback? onDeleteSelected;
  final bool isGridView;
  final VoidCallback onToggleViewMode;

  /// 保留这些参数以确保兼容性，但它们已移至过滤面板
  final ValueChanged<String> onSearch;
  final String sortField;
  final String sortOrder;
  final ValueChanged<String> onSortFieldChanged;
  final VoidCallback onSortOrderChanged;

  final VoidCallback? onBackPressed;
  
  // 新增：全选和取消选择功能
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final List<String>? allPracticeIds; // 所有字帖ID列表，用于全选

  const M3PracticeListNavigationBar({
    super.key,
    required this.onNewPractice,
    required this.onToggleBatchMode,
    required this.isBatchMode,
    required this.selectedCount,
    this.onDeleteSelected,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.sortField,
    required this.sortOrder,
    required this.onSortFieldChanged,
    required this.onSortOrderChanged,
    this.onBackPressed,
    this.onSelectAll, // 新增参数
    this.onClearSelection, // 新增参数
    this.allPracticeIds, // 新增参数
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<M3PracticeListNavigationBar> createState() =>
      _M3PracticeListNavigationBarState();
}

class _M3PracticeListNavigationBarState
    extends State<M3PracticeListNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return M3PageNavigationBar(
      title: l10n.practiceListTitle,
      showBackButton: true,
      onBackPressed: widget.onBackPressed,
      titleActions: widget.isBatchMode
          ? [
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
            ]
          : null,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isBatchMode) ...[
              // 批量模式下的操作按钮
              if (widget.selectedCount > 0) ...[
                // 删除选中项按钮
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.deleteSelected,
                  onPressed: widget.onDeleteSelected,
                ),
                // 取消选择按钮
                if (widget.onClearSelection != null)
                  IconButton(
                    icon: const Icon(Icons.deselect),
                    tooltip: l10n.deselectAll,
                    onPressed: widget.onClearSelection,
                  ),
              ] else ...[
                // 无选择时显示全选按钮
                if (widget.onSelectAll != null)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: l10n.selectAll,
                    onPressed: widget.onSelectAll,
                  ),
              ],
            ] else ...[
              // 非批量模式下的新建按钮
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.newItem),
                onPressed: widget.onNewPractice,
              ),
            ],
          ],
        ),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip: widget.isBatchMode ? l10n.done : l10n.batchMode,
          onPressed: widget.onToggleBatchMode,
        ),

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
