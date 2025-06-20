import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../dialogs/work_import/m3_work_import_dialog.dart';
import '../../providers/work_browse_provider.dart';
import '../../providers/works_providers.dart';
import '../../utils/cross_navigation_helper.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/content/m3_work_grid_view.dart';
import 'components/content/m3_work_list_view.dart';
import 'components/dialogs/m3_work_tag_edit_dialog.dart';
import 'components/filter/m3_work_filter_panel.dart';
import 'components/m3_work_browse_navigation_bar.dart';

class M3WorkBrowsePage extends ConsumerStatefulWidget {
  const M3WorkBrowsePage({super.key});

  @override
  ConsumerState<M3WorkBrowsePage> createState() => _M3WorkBrowsePageState();
}

class _M3WorkBrowsePageState extends ConsumerState<M3WorkBrowsePage>
    with WidgetsBindingObserver {
  // Store provider reference during initialization to avoid accessing it during lifecycle changes
  StateController<RefreshInfo?>? _refreshNotifier;

  // 🚀 优化的刷新管理器
  // OptimizedRefreshManager? _refreshManager;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    final l10n = AppLocalizations.of(context);

    // Use a local variable to store whether a refresh is in progress
    bool isRefreshing = false;

    ref.listen(worksNeedsRefreshProvider, (previous, current) async {
      if (current == null || isRefreshing || !mounted) return;

      // Set flag to prevent multiple concurrent refreshes
      isRefreshing = true;

      try {
        // Check mounted state again before proceeding
        if (!mounted) return;

        AppLogger.debug(
          '收到刷新请求',
          tag: 'WorkBrowsePage',
          data: {
            'reason': current.reason,
            'priority': current.priority,
            'force': current.force,
          },
        );

        // Capture the force value before the async gap
        final shouldForceRefresh = current.force;

        // Check mounted before starting async operation
        if (!mounted) return;

        await viewModel.loadWorks(forceRefresh: shouldForceRefresh);
      } catch (e) {
        AppLogger.error('刷新失败', tag: 'WorkBrowsePage', error: e);
      } finally {
        isRefreshing = false;

        // Using a local variable to store the notifier before checking mounted
        // This prevents accessing the provider after widget deactivation
        if (mounted) {
          final notifier = ref.read(worksNeedsRefreshProvider.notifier);
          notifier.state = null;
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
        onDeleteSelected: () {
          // Use a method instead of an inline callback to handle deletion
          _handleDeleteSelected(context);
        },
        onBackPressed: () {
          CrossNavigationHelper.handleBackNavigation(context, ref);
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Filter Panel
                if (state.isSidebarOpen)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive panel width
                      final screenWidth = MediaQuery.of(context).size.width;
                      final maxPanelWidth =
                          (screenWidth * 0.4).clamp(250.0, 400.0);
                      final minPanelWidth =
                          (screenWidth * 0.25).clamp(200.0, 280.0);
                      final initialPanelWidth =
                          (screenWidth * 0.3).clamp(250.0, 300.0);

                      return PersistentResizablePanel(
                        panelId: 'work_browse_filter_panel',
                        initialWidth: initialPanelWidth,
                        minWidth: minPanelWidth,
                        maxWidth: maxPanelWidth,
                        isLeftPanel: true,
                        child: M3WorkFilterPanel(
                          filter: state.filter,
                          onFilterChanged: viewModel.updateFilter,
                          onToggleExpand: () => viewModel.toggleSidebar(),
                          searchController: state.searchController,
                          initialSearchValue: state.searchQuery,
                          onRefresh: () => viewModel.refresh(),
                        ),
                      );
                    },
                  ),
                PersistentSidebarToggle(
                  sidebarId: 'work_browse_filter_sidebar',
                  defaultIsOpen: state.isSidebarOpen,
                  onToggle: (isOpen) => viewModel.toggleSidebar(),
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
              label: Text(l10n.reload),
            )
          : null,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 🚀 使用性能监控记录应用生命周期变化
    final performanceMonitor = ref.read(performanceMonitorProvider);

    if (state == AppLifecycleState.resumed) {
      performanceMonitor.recordOperation('app_resumed', Duration.zero);

      AppLogger.info(
        '应用恢复前台，延迟刷新作品列表',
        tag: 'WorkBrowsePage',
        data: {
          'optimization': 'delayed_refresh',
          'delay': '1000ms',
        },
      );

      // 🚀 延迟刷新，避免应用恢复时的性能冲击
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _refreshWithOptimization();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      performanceMonitor.recordOperation('app_paused', Duration.zero);
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

    // Initialize the refresh notifier reference
    if (mounted) {
      _refreshNotifier = ref.read(worksNeedsRefreshProvider.notifier);
    }

    Future.microtask(() {
      if (!mounted) return;

      // Use the stored notifier if available
      if (_refreshNotifier != null) {
        _refreshNotifier!.state = const RefreshInfo(
          reason: 'App initialization',
          force: true,
          priority: 10,
        );
      }
    });

    // 🚀 启动性能监控
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final performanceMonitor = ref.read(performanceMonitorProvider);
      performanceMonitor.recordOperation(
          'work_browse_page_init', Duration.zero);
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
            Text(l10n.error(state.error!),
                style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadWorks(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.reload),
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
                  l10n.loading,
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
                    Text(l10n.noWorks,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.noWorksHint,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showImportDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.import),
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
                    onTagsEdited: (workId) => _handleTagEdited(context, workId),
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
                    onTagsEdited: (workId) => _handleTagEdited(context, workId),
                  );
  }

  /// Safely handle deletion of selected works
  void _handleDeleteSelected(BuildContext context) {
    // Verify the widget is still mounted before proceeding
    if (!mounted) return;

    try {
      // Store references to providers locally before any async operations
      final viewModelNotifier = ref.read(workBrowseProvider.notifier);
      final refreshNotifier = ref.read(worksNeedsRefreshProvider.notifier);

      // Execute deletion
      viewModelNotifier.deleteSelected();

      // Schedule refresh
      if (mounted) {
        refreshNotifier.state = RefreshInfo.importCompleted();
      }
    } catch (e) {
      AppLogger.error('Failed to delete selected works',
          tag: 'WorkBrowsePage', error: e);

      // Show error to user if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')));
      }
    }
  }

  /// Handle tag editing for a work
  Future<void> _handleTagEdited(BuildContext context, String workId) async {
    final l10n = AppLocalizations.of(context);

    try {
      final work =
          ref.read(workBrowseProvider).works.firstWhere((w) => w.id == workId);

      // Get all existing tags for suggestions
      final allTags = ref
          .read(workBrowseProvider)
          .works
          .expand((work) => work.tags)
          .toSet()
          .toList();
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => M3WorkTagEditDialog(
          tags: work.tags,
          suggestedTags: allTags,
          onSaved: (newTags) {
            Navigator.of(context).pop(newTags);
          },
        ),
        barrierDismissible: false,
      );

      if (result != null) {
        AppLogger.debug('更新作品标签', tag: 'WorkBrowsePage', data: {
          'workId': workId,
          'oldTags': work.tags,
          'newTags': result,
        });

        // Update the tags
        await ref.read(workBrowseProvider.notifier).updateTags(workId, result);
      }
    } catch (e) {
      AppLogger.error('编辑标签失败', tag: 'WorkBrowsePage', error: e);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
          SnackBar(content: Text(l10n.error(e.toString()))),
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
        reason: 'Import completed',
        force: true,
        priority: 10,
      );
    }
  }

  /// 🚀 优化的刷新方法
  Future<void> _refreshWithOptimization() async {
    final startTime = DateTime.now();
    final performanceMonitor = ref.read(performanceMonitorProvider);

    try {
      performanceMonitor.recordOperation('work_refresh_start', Duration.zero);

      AppLogger.info(
        '开始优化刷新作品列表',
        tag: 'WorkBrowsePage',
        data: {
          'optimization': 'optimized_refresh_start',
        },
      );

      // 使用低优先级刷新，避免阻塞UI
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        ref.invalidate(worksProvider);

        final duration = DateTime.now().difference(startTime);
        performanceMonitor.recordOperation('work_refresh_complete', duration);

        AppLogger.info(
          '作品列表刷新完成',
          tag: 'WorkBrowsePage',
          data: {
            'duration': duration.inMilliseconds,
            'optimization': 'optimized_refresh_complete',
          },
        );
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      performanceMonitor.recordOperation('work_refresh_error', duration,
          isSuccess: false);

      AppLogger.error(
        '作品列表刷新失败',
        tag: 'WorkBrowsePage',
        error: e,
        data: {
          'duration': duration.inMilliseconds,
          'optimization': 'refresh_error',
        },
      );
    }
  }
}
