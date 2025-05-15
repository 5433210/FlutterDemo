import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../dialogs/work_import/m3_work_import_dialog.dart';
import '../../providers/work_browse_provider.dart';
import '../../providers/works_providers.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/content/m3_work_grid_view.dart';
import 'components/content/m3_work_list_view.dart';
import 'components/filter/m3_work_filter_panel.dart';
import 'components/m3_work_browse_navigation_bar.dart';

class M3WorkBrowsePage extends ConsumerStatefulWidget {
  const M3WorkBrowsePage({super.key});

  @override
  ConsumerState<M3WorkBrowsePage> createState() => _M3WorkBrowsePageState();
}

class _M3WorkBrowsePageState extends ConsumerState<M3WorkBrowsePage>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    final l10n = AppLocalizations.of(context);

    ref.listen(worksNeedsRefreshProvider, (previous, current) async {
      if (current == null) return;

      try {
        AppLogger.debug(
          '收到刷新请求',
          tag: 'WorkBrowsePage',
          data: {
            'reason': current.reason,
            'priority': current.priority,
            'force': current.force,
          },
        );

        await viewModel.loadWorks(forceRefresh: current.force);
      } catch (e) {
        AppLogger.error('刷新失败', tag: 'WorkBrowsePage', error: e);
      } finally {
        if (mounted) {
          ref.read(worksNeedsRefreshProvider.notifier).state = null;
        }
      }
    });

    return PageLayout(
      toolbar: M3WorkBrowseNavigationBar(
        viewMode: state.viewMode,
        onViewModeChanged: (mode) => viewModel.setViewMode(mode),
        onImport: () => _showImportDialog(context),
        onSearch: viewModel.setSearchQuery,
        batchMode: state.batchMode,
        onBatchModeChanged: (_) => viewModel.toggleBatchMode(),
        selectedCount: state.selectedWorks.length,
        onDeleteSelected: () => {
          ref.read(workBrowseProvider.notifier).deleteSelected(),
          ref.read(worksNeedsRefreshProvider.notifier).state =
              RefreshInfo.importCompleted()
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Filter Panel
                if (state.isSidebarOpen)
                  ResizablePanel(
                    initialWidth: 300,
                    minWidth: 280,
                    maxWidth: 400,
                    isLeftPanel: true,
                    child: M3WorkFilterPanel(
                      filter: state.filter,
                      onFilterChanged: viewModel.updateFilter,
                      onToggleExpand: () => viewModel.toggleSidebar(),
                    ),
                  ),
                SidebarToggle(
                  isOpen: state.isSidebarOpen,
                  onToggle: () => viewModel.toggleSidebar(),
                  alignRight: false,
                ),
                // 移除了可能导致深色阴影的分隔线
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
          if (!state.isLoading && state.works.isNotEmpty)
            M3PaginationControls(
              currentPage: state.page,
              pageSize: state.pageSize,
              totalItems: state.totalItems,
              onPageChanged: (page) {
                ref.read(workBrowseProvider.notifier).setPage(page);
              },
              onPageSizeChanged: (size) {
                ref.read(workBrowseProvider.notifier).setPageSize(size);
              },
              availablePageSizes: const [10, 20, 50, 100],
            ),
        ],
      ),
      floatingActionButton: state.isLoading && state.works.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                _loadWorks(force: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.workBrowseReload),
            )
          : null,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        ref.read(worksNeedsRefreshProvider.notifier).state =
            RefreshInfo.appResume();
      } catch (e) {
        AppLogger.error('Failed to set refresh flag',
            tag: 'WorkBrowsePage', error: e);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(worksNeedsRefreshProvider.notifier).state = const RefreshInfo(
        reason: 'App initialization',
        force: true,
        priority: 10,
      );
    });
  }

  Widget _buildMainContent() {
    final state = ref.watch(workBrowseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.workBrowseError(state.error!),
                style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadWorks(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.workBrowseReload),
            ),
          ],
        ),
      );
    }

    return state.isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  l10n.workBrowseLoading,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        : state.works.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withAlpha(128)),
                    const SizedBox(height: 16),
                    Text(l10n.workBrowseNoWorks,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.workBrowseNoWorksHint,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showImportDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.workBrowseImport),
                    ),
                  ],
                ),
              )
            : state.viewMode == ViewMode.grid
                ? M3WorkGridView(
                    works: state.works,
                    batchMode: state.batchMode,
                    selectedWorks: state.selectedWorks,
                    onSelectionChanged: (workId, selected) => ref
                        .read(workBrowseProvider.notifier)
                        .toggleSelection(workId),
                    onItemTap: (workId) => _handleWorkSelected(context, workId),
                    onToggleFavorite: (workId) => ref
                        .read(workBrowseProvider.notifier)
                        .toggleFavorite(workId),
                  )
                : M3WorkListView(
                    works: state.works,
                    batchMode: state.batchMode,
                    selectedWorks: state.selectedWorks,
                    onSelectionChanged: (workId, selected) => ref
                        .read(workBrowseProvider.notifier)
                        .toggleSelection(workId),
                    onItemTap: (workId) => _handleWorkSelected(context, workId),
                    onToggleFavorite: (workId) => ref
                        .read(workBrowseProvider.notifier)
                        .toggleFavorite(workId),
                  );
  }

  void _handleWorkSelected(BuildContext context, String workId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.workDetail,
      arguments: workId,
    );
  }

  Future<void> _loadWorks({bool force = false}) async {
    try {
      if (!mounted) return;

      AppLogger.debug('User manually triggered works loading after error',
          tag: 'WorkBrowsePage', data: {'force': force});

      const refreshInfo = RefreshInfo(
        reason: 'User manual refresh after error',
        force: true,
        priority: 10,
      );

      if (!mounted) return;
      ref.read(worksNeedsRefreshProvider.notifier).state = refreshInfo;
    } catch (e) {
      AppLogger.error('Failed to load works', tag: 'WorkBrowsePage', error: e);

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final l10n = AppLocalizations.of(context);
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.workBrowseError(e.toString()))),
        );
      }
    }
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final result = await M3WorkImportDialog.show(context);

    if (result == true) {
      AppLogger.debug('Import completed, preparing to refresh list',
          tag: 'WorkBrowsePage');
      if (!mounted) return;

      ref.read(worksNeedsRefreshProvider.notifier).state = const RefreshInfo(
        reason: 'Refresh after import completed',
        force: true,
        priority: 9,
      );
    }
  }
}
