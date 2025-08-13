import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../providers/practice_list_provider.dart';
import '../../utils/cross_navigation_helper.dart';
import '../../viewmodels/states/practice_list_state.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_persistent_pagination_controls.dart';
import 'components/m3_practice_content_area.dart';
import 'components/m3_practice_filter_panel.dart';
import 'components/m3_practice_list_navigation_bar.dart';

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
    final l10n = AppLocalizations.of(context);

    // Show error snackbar if needed
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final errorMsg = '${l10n.filter}: ${state.error}';
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
          CrossNavigationHelper.handleBackNavigation(context, ref);
        },
        onSelectAll: () => _handleSelectAll(),
        onClearSelection: state.selectedPractices.isNotEmpty
            ? () => _handleClearSelection()
            : null,
        allPracticeIds: state.practices.map((p) => p['id'] as String).toList(),
      ),
      body: _buildResponsiveLayout(state, viewModel, l10n),
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
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteMessage(1)),
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
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
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

  void _handleSelectAll() {
    final viewModel = ref.read(practiceListProvider.notifier);
    final state = ref.read(practiceListProvider);

    for (var practice in state.practices) {
      final practiceId = practice['id'] as String;
      if (!state.selectedPractices.contains(practiceId)) {
        viewModel.togglePracticeSelection(practiceId);
      }
    }
  }

  void _handleClearSelection() {
    final viewModel = ref.read(practiceListProvider.notifier);
    final state = ref.read(practiceListProvider);

    for (var practice in state.practices) {
      final practiceId = practice['id'] as String;
      if (state.selectedPractices.contains(practiceId)) {
        viewModel.togglePracticeSelection(practiceId);
      }
    }
  }

  /// 根据屏幕宽度切换筛选面板
  void _toggleFilterPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 1200;
    final provider = ref.read(practiceListProvider.notifier);

    if (isNarrowScreen) {
      provider.toggleFilterPanelExclusive();
    } else {
      provider.toggleFilterPanel();
    }
  }

  Widget _buildResponsiveLayout(
      PracticeListState state, dynamic viewModel, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        const breakpoint = 1200.0;

        if (screenWidth < breakpoint) {
          // Narrow screen: show only filter panel when expanded
          return _buildNarrowLayout(state, viewModel, l10n);
        } else {
          // Wide screen: show filter panel and content side by side
          return _buildWideLayout(state, viewModel, l10n);
        }
      },
    );
  }

  Widget _buildNarrowLayout(
      PracticeListState state, dynamic viewModel, AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: state.isFilterPanelExpanded
              ? M3PracticeFilterPanel(
                  filter: state.filter,
                  onFilterChanged: viewModel.updateFilter,
                  onSearch: _searchPractices,
                  onToggleExpand: () => _toggleFilterPanel(),
                  initialSearchValue: state.searchQuery,
                  searchController: state.searchController,
                  onRefresh: () => viewModel.refresh(),
                )
              : Column(
                  children: [
                    // 工具栏 - 显示筛选按钮
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () => _toggleFilterPanel(),
                            tooltip: l10n.filter,
                          ),
                          const Spacer(),
                          Text(
                            '${state.practices.length} practices',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // 主内容区域
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : M3PracticeContentArea(
                              practices: state.practices,
                              viewMode: state.viewMode,
                              isBatchMode: state.batchMode,
                              selectedPractices: state.selectedPractices,
                              onPracticeTap: _handlePracticeTap,
                              onPracticeLongPress: (practiceId) {
                                if (!state.batchMode) {
                                  ref
                                      .read(practiceListProvider.notifier)
                                      .toggleBatchMode();
                                }
                                ref
                                    .read(practiceListProvider.notifier)
                                    .togglePracticeSelection(practiceId);
                              },
                              onToggleFavorite: (practiceId) {
                                ref
                                    .read(practiceListProvider.notifier)
                                    .handleToggleFavorite(practiceId);
                              },
                              onTagsEdited: (practiceId, tags) {
                                ref
                                    .read(practiceListProvider.notifier)
                                    .handleTagEdited(practiceId, tags);
                              },
                              isLoading: state.isLoading,
                              errorMessage: state.error,
                            ),
                    ),
                  ],
                ),
        ),
        // Show pagination only when not in filter mode and not loading
        if (!state.isLoading && !state.isFilterPanelExpanded)
          M3PersistentPaginationControls(
            pageId: 'practice_list',
            currentPage: state.page,
            totalItems: state.totalItems,
            onPageChanged: (page) => viewModel.setPage(page),
            onPageSizeChanged: (size) => viewModel.setPageSize(size),
            availablePageSizes: const [10, 20, 50, 100],
            defaultPageSize: 20,
          ),
      ],
    );
  }

  Widget _buildWideLayout(
      PracticeListState state, dynamic viewModel, AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // 左侧过滤面板
              if (state.isFilterPanelExpanded)
                PersistentResizablePanel(
                  panelId: 'practice_list_filter_panel',
                  initialWidth: 300,
                  minWidth: 280,
                  maxWidth: 400,
                  isLeftPanel: true,
                  child: M3PracticeFilterPanel(
                    filter: state.filter,
                    onFilterChanged: viewModel.updateFilter,
                    onSearch: _searchPractices,
                    onToggleExpand: () => _toggleFilterPanel(),
                    initialSearchValue: state.searchQuery,
                    searchController: state.searchController,
                    onRefresh: () => viewModel.refresh(),
                  ),
                ),
              // 过滤面板切换按钮
              PersistentSidebarToggle(
                sidebarId: 'practice_list_filter_sidebar',
                defaultIsOpen: state.isFilterPanelExpanded,
                onToggle: (isOpen) => _toggleFilterPanel(),
                alignRight: false,
              ),
              // 主内容区域
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : M3PracticeContentArea(
                        practices: state.practices,
                        viewMode: state.viewMode,
                        isBatchMode: state.batchMode,
                        selectedPractices: state.selectedPractices,
                        onPracticeTap: _handlePracticeTap,
                        onPracticeLongPress: (practiceId) {
                          if (!state.batchMode) {
                            ref
                                .read(practiceListProvider.notifier)
                                .toggleBatchMode();
                          }
                          ref
                              .read(practiceListProvider.notifier)
                              .togglePracticeSelection(practiceId);
                        },
                        onToggleFavorite: (practiceId) {
                          ref
                              .read(practiceListProvider.notifier)
                              .handleToggleFavorite(practiceId);
                        },
                        onTagsEdited: (practiceId, tags) {
                          ref
                              .read(practiceListProvider.notifier)
                              .handleTagEdited(practiceId, tags);
                        },
                        isLoading: state.isLoading,
                        errorMessage: state.error,
                      ),
              ),
            ],
          ),
        ),
        // 分页控件
        if (!state.isLoading)
          M3PersistentPaginationControls(
            pageId: 'practice_list',
            currentPage: state.page,
            totalItems: state.totalItems,
            onPageChanged: (page) => viewModel.setPage(page),
            onPageSizeChanged: (size) => viewModel.setPageSize(size),
            availablePageSizes: const [10, 20, 50, 100],
            defaultPageSize: 20,
          ),
      ],
    );
  }
}
