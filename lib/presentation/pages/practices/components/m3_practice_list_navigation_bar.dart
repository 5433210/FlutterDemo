import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
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
  final ValueChanged<String> onSearch;
  final String sortField;
  final String sortOrder;
  final ValueChanged<String> onSortFieldChanged;
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
  final TextEditingController _searchController = TextEditingController();

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
        // 居中的搜索框
        // const Spacer(),
        // 排序按钮
        PopupMenuButton<String>(
          tooltip: l10n.filterSortSection,
          icon: const Icon(Icons.sort),
          itemBuilder: (context) => [
            _buildSortMenuItem(
                l10n.practiceListSortByUpdateTime, 'updateTime', theme),
            _buildSortMenuItem(
                l10n.practiceListSortByCreateTime, 'createTime', theme),
            _buildSortMenuItem(l10n.practiceListSortByTitle, 'title', theme),
          ],
          onSelected: widget.onSortFieldChanged,
        ),
        // const SizedBox(width: AppSizes.s),

        SizedBox(
          width: 240,
          child: SearchBar(
            controller: _searchController,
            hintText: l10n.practiceListSearch,
            leading: const Icon(Icons.search, size: AppSizes.searchBarIconSize),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSizes.m),
            ),
            onChanged: widget.onSearch,
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(
                        milliseconds: AppSizes.animationDurationMedium),
                    child: IconButton(
                      icon: const Icon(Icons.clear,
                          size: AppSizes.searchBarClearIconSize),
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
        // const Spacer(),

        // 右侧按钮组
        // 新建字帖或删除按钮

        // const SizedBox(width: AppSizes.s),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip: widget.isBatchMode
              ? l10n.practiceListBatchDone
              : l10n.practiceListBatchMode,
          onPressed: widget.onToggleBatchMode,
        ),
        // const SizedBox(width: AppSizes.s),

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PopupMenuItem<String> _buildSortMenuItem(
      String title, String value, ThemeData theme) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            widget.sortOrder == 'desc'
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            size: 18,
            color: widget.sortField == value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(title),
          if (widget.sortField == value)
            Icon(
              Icons.check,
              size: 18,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
