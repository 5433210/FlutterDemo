import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../providers/practice_list_provider.dart';
import '../../viewmodels/states/practice_list_state.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/m3_practice_filter_panel.dart';
import 'components/m3_practice_grid_view.dart';
import 'components/m3_practice_list_navigation_bar.dart';
import 'components/m3_practice_list_view.dart';

/// Material 3 practice list page
class M3PracticeListPage extends ConsumerStatefulWidget {
  const M3PracticeListPage({super.key});

  @override
  ConsumerState<M3PracticeListPage> createState() => _M3PracticeListPageState();
}

class _M3PracticeListPageState extends ConsumerState<M3PracticeListPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceListProvider);
    final viewModel = ref.read(practiceListProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Show error snackbar if needed
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final errorMsg = '${l10n.practiceListFilterTitle}: ${state.error}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
          viewModel.updateFilter(state.filter.copyWith()); // Clear error
        }
      });
    }

    return PageLayout(
      toolbar: M3PracticeListNavigationBar(
        isGridView: state.viewMode == PracticeViewMode.grid,
        onToggleViewMode: () => viewModel.toggleViewMode(),
        isBatchMode: state.batchMode,
        onToggleBatchMode: () => viewModel.toggleBatchMode(),
        selectedCount: state.selectedPractices.length,
        onDeleteSelected:
            state.selectedPractices.isNotEmpty ? _confirmDeleteSelected : null,
        onNewPractice: () => _navigateToEditPage(),
        sortField: state.filter.sortField,
        sortOrder: state.filter.sortOrder,
        onSearch: (_) {},
        onSortFieldChanged: (_) {},
        onSortOrderChanged: () {},
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 左侧过滤面板
                if (state.isFilterPanelExpanded)
                  ResizablePanel(
                    initialWidth: 300,
                    minWidth: 280,
                    maxWidth: 400,
                    isLeftPanel: true,
                    child: M3PracticeFilterPanel(
                      filter: state.filter,
                      onFilterChanged: viewModel.updateFilter,
                      onSearch: _searchPractices,
                      onToggleExpand: () => viewModel.toggleFilterPanel(),
                      initialSearchValue: state.searchQuery,
                      searchController: state.searchController,
                    ),
                  ),

                // 过滤面板切换按钮
                SidebarToggle(
                  isOpen: state.isFilterPanelExpanded,
                  onToggle: () => viewModel.toggleFilterPanel(),
                  alignRight: false,
                ),

                // 主内容区域
                Expanded(
                  child: state.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : (state.viewMode == PracticeViewMode.grid
                          ? M3PracticeGridView(
                              practices: state.practices,
                              isBatchMode: state.batchMode,
                              selectedPractices: state.selectedPractices,
                              onPracticeTap: _handlePracticeTap,
                              onPracticeLongPress: _handlePracticeLongPress,
                              onToggleFavorite: (id) =>
                                  viewModel.handleToggleFavorite(id),
                              onTagsEdited: (id, tags) =>
                                  viewModel.handleTagEdited(id, tags),
                              isLoading: false,
                              errorMessage: null,
                            )
                          : M3PracticeListView(
                              practices: state.practices,
                              isBatchMode: state.batchMode,
                              selectedPractices: state.selectedPractices,
                              onPracticeTap: _handlePracticeTap,
                              onPracticeLongPress: _handlePracticeLongPress,
                              onToggleFavorite: (id) =>
                                  viewModel.handleToggleFavorite(id),
                              onTagsEdited: (id, tags) =>
                                  viewModel.handleTagEdited(id, tags),
                              isLoading: false,
                              errorMessage: null,
                            )),
                ),
              ],
            ),
          ),

          // 分页控件
          if (!state.isLoading)
            M3PaginationControls(
              currentPage: state.page,
              pageSize: state.pageSize,
              totalItems: state.totalItems,
              onPageChanged: (page) => viewModel.setPage(page),
              onPageSizeChanged: (size) => viewModel.setPageSize(size),
              availablePageSizes: const [10, 20, 50, 100],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _confirmDeleteSelected() {
    final l10n = AppLocalizations.of(context);
    final viewModel = ref.read(practiceListProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.practiceListDeleteConfirm),
        content: Text(l10n.practiceListDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.deleteSelectedPractices();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _handlePracticeLongPress(String practiceId) {
    final viewModel = ref.read(practiceListProvider.notifier);
    final state = ref.read(practiceListProvider);

    if (!state.batchMode) {
      viewModel.toggleBatchMode();
      viewModel.togglePracticeSelection(practiceId);
    }
  }

  void _handlePracticeTap(String practiceId) {
    final state = ref.read(practiceListProvider);

    if (state.batchMode) {
      ref
          .read(practiceListProvider.notifier)
          .togglePracticeSelection(practiceId);
    } else {
      _navigateToPracticeDetail(context, practiceId);
    }
  }

  void _navigateToEditPage([String? practiceId]) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.practiceEdit,
      arguments: practiceId,
    );

    // Refresh practices when returning
    ref.read(practiceListProvider.notifier).loadPractices();
  }

  void _navigateToPracticeDetail(BuildContext context, String practiceId) {
    _navigateToEditPage(practiceId);
  }

  void _searchPractices(String query) {
    // This is now handled within the provider
    ref.read(practiceListProvider.notifier).setSearchQuery(query);
  }
}
