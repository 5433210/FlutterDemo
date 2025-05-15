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
            if (widget.isBatchMode && widget.selectedCount > 0)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: l10n.practiceListDeleteSelected,
                onPressed: widget.onDeleteSelected,
              )
            else if (!widget.isBatchMode)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.practiceListNewPractice),
                onPressed: widget.onNewPractice,
              ),
          ],
        ),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip: widget.isBatchMode
              ? l10n.practiceListBatchDone
              : l10n.practiceListBatchMode,
          onPressed: widget.onToggleBatchMode,
        ),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView
              ? l10n.practiceListListView
              : l10n.practiceListGridView,
          onPressed: widget.onToggleViewMode,
        ),
      ],
    );
  }
}
