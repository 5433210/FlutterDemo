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
import '../../viewmodels/work_browse_view_model.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_persistent_pagination_controls.dart';
import 'components/content/m3_work_content_area.dart';
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
  // 🚀 优化的刷新管理器
  // OptimizedRefreshManager? _refreshManager;

  @override
  void initState() {
    super.initState();
    AppLogger.info('M3WorkBrowsePage initState', tag: 'WorkBrowse');

    // 添加帧回调，确认首帧渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('M3WorkBrowsePage 首帧渲染完成', tag: 'WorkBrowse');
    });
  }

  @override
  void dispose() {
    AppLogger.info('M3WorkBrowsePage dispose', tag: 'WorkBrowse');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLogger.info('M3WorkBrowsePage didChangeDependencies', tag: 'WorkBrowse');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('M3WorkBrowsePage build开始', tag: 'WorkBrowse');

    try {
      final l10n = AppLocalizations.of(context);
      AppLogger.debug('获取本地化资源成功', tag: 'WorkBrowse');

      final state = ref.watch(workBrowseProvider);
      final viewModel = ref.read(workBrowseProvider.notifier);

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
          selectedWorkIds: state.selectedWorks, // 传递实际选中的作品ID
          onDeleteSelected: () {
            // Use a method instead of an inline callback to handle deletion
            _handleDeleteSelected(context);
          },
          onBackPressed: () {
            CrossNavigationHelper.handleBackNavigation(context, ref);
          },
          onAddWork: () => _showWorkImportDialog(context),
          allWorkIds: state.works.map((w) => w.id).toList(),
          onSelectAll: () => _handleSelectAll(),
          onClearSelection: () => _handleClearSelection(),
        ),
        body: _buildResponsiveLayout(state, viewModel, l10n),
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
    } catch (e, stack) {
      AppLogger.error('M3WorkBrowsePage build过程中发生错误',
          error: e, stackTrace: stack, tag: 'WorkBrowse');
      return Scaffold(
        appBar: AppBar(
          title: const Text('作品浏览'),
        ),
        body: Center(
          child: Text('加载错误: $e'),
        ),
      );
    }
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

    AppLogger.debug('编辑标签按钮被点击 - workId: $workId', tag: 'WorkBrowsePage');

    try {
      final work =
          ref.read(workBrowseProvider).works.firstWhere((w) => w.id == workId);

      AppLogger.debug('找到作品 - ${work.title}, 当前标签: ${work.tags}',
          tag: 'WorkBrowsePage');

      // Get all existing tags for suggestions
      final allTags = ref
          .read(workBrowseProvider)
          .works
          .expand((work) => work.tags)
          .toSet()
          .toList();

      AppLogger.debug('准备显示对话框 - 建议标签: $allTags', tag: 'WorkBrowsePage');

      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) {
          AppLogger.debug('正在构建对话框', tag: 'WorkBrowsePage');
          return M3WorkTagEditDialog(
            tags: work.tags,
            suggestedTags: allTags,
            onSaved: (newTags) {
              AppLogger.debug('标签保存 - $newTags', tag: 'WorkBrowsePage');
              Navigator.of(context).pop(newTags);
            },
          );
        },
        barrierDismissible: false,
      );

      AppLogger.debug('对话框返回结果 - $result', tag: 'WorkBrowsePage');

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
      AppLogger.error('编辑标签时发生错误', tag: 'WorkBrowsePage', error: e);
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

  Future<void> _showWorkImportDialog(BuildContext context) async {
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

  void _handleSelectAll() {
    final viewModel = ref.read(workBrowseProvider.notifier);
    viewModel.selectAll();

    AppLogger.debug('用户触发全选操作',
        tag: 'WorkBrowsePage',
        data: {'totalWorks': ref.read(workBrowseProvider).works.length});
  }

  void _handleClearSelection() {
    final viewModel = ref.read(workBrowseProvider.notifier);
    viewModel.clearSelection();

    AppLogger.debug('用户触发取消选择操作', tag: 'WorkBrowsePage', data: {
      'previousSelectedCount': ref.read(workBrowseProvider).selectedWorks.length
    });
  }

  /// 根据屏幕宽度切换侧边栏
  void _toggleSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 1200;
    final provider = ref.read(workBrowseProvider.notifier);

    if (isNarrowScreen) {
      provider.toggleSidebarExclusive();
    } else {
      provider.toggleSidebar();
    }
  }

  Widget _buildResponsiveLayout(WorkBrowseState state,
      WorkBrowseViewModel viewModel, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        const breakpoint = 1200.0;

        if (screenWidth < breakpoint) {
          // Narrow screen: show only filter panel when sidebar is open
          return _buildNarrowLayout(state, viewModel, l10n);
        } else {
          // Wide screen: show filter panel and content side by side
          return _buildWideLayout(state, viewModel, l10n);
        }
      },
    );
  }

  Widget _buildNarrowLayout(WorkBrowseState state,
      WorkBrowseViewModel viewModel, AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: state.isSidebarOpen
              ? M3WorkFilterPanel(
                  filter: state.filter,
                  onFilterChanged: viewModel.updateFilter,
                  onToggleExpand: () => _toggleSidebar(),
                  searchController: state.searchController,
                  initialSearchValue: state.searchQuery,
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
                                .withValues(alpha: 51), // 0.2 * 255 ≈ 51
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () => _toggleSidebar(),
                            tooltip: l10n.filter,
                          ),
                          const Spacer(),
                          Text(
                            '${state.works.length} works',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // 主内容区域
                    Expanded(
                      child: M3WorkContentArea(
                        works: state.works,
                        viewMode: state.viewMode,
                        batchMode: state.batchMode,
                        selectedWorks: state.selectedWorks,
                        onSelectionChanged: (workId, selected) {
                          viewModel.toggleSelection(workId);
                        },
                        onItemTap: (workId) {
                          Navigator.of(context).pushNamed(
                            AppRoutes.workDetail,
                            arguments: workId,
                          );
                        },
                        onToggleFavorite: (workId) {
                          viewModel.toggleFavorite(workId);
                        },
                        onTagsEdited: (workId) =>
                            _handleTagEdited(context, workId),
                      ),
                    ),
                  ],
                ),
        ),
        if (!state.isLoading && state.works.isNotEmpty && !state.isSidebarOpen)
          M3PersistentPaginationControls(
            pageId: 'work_browse',
            currentPage: state.page,
            totalItems: state.totalItems,
            onPageChanged: (page) {
              ref.read(workBrowseProvider.notifier).setPage(page);
            },
            onPageSizeChanged: (size) {
              ref.read(workBrowseProvider.notifier).setPageSize(size);
            },
            availablePageSizes: const [10, 20, 50, 100],
            defaultPageSize: 20,
          ),
      ],
    );
  }

  Widget _buildWideLayout(WorkBrowseState state, WorkBrowseViewModel viewModel,
      AppLocalizations l10n) {
    return Column(
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
                        onToggleExpand: () => _toggleSidebar(),
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
                onToggle: (isOpen) => _toggleSidebar(),
                alignRight: false,
              ),
              // Content area
              Expanded(
                child: M3WorkContentArea(
                  works: state.works,
                  viewMode: state.viewMode,
                  batchMode: state.batchMode,
                  selectedWorks: state.selectedWorks,
                  onSelectionChanged: (workId, selected) {
                    viewModel.toggleSelection(workId);
                  },
                  onItemTap: (workId) {
                    Navigator.of(context).pushNamed(
                      AppRoutes.workDetail,
                      arguments: workId,
                    );
                  },
                  onToggleFavorite: (workId) {
                    viewModel.toggleFavorite(workId);
                  },
                  onTagsEdited: (workId) => _handleTagEdited(context, workId),
                ),
              ),
            ],
          ),
        ),
        if (!state.isLoading && state.works.isNotEmpty)
          M3PersistentPaginationControls(
            pageId: 'work_browse',
            currentPage: state.page,
            totalItems: state.totalItems,
            onPageChanged: (page) {
              ref.read(workBrowseProvider.notifier).setPage(page);
            },
            onPageSizeChanged: (size) {
              ref.read(workBrowseProvider.notifier).setPageSize(size);
            },
            availablePageSizes: const [10, 20, 50, 100],
            defaultPageSize: 20,
          ),
      ],
    );
  }
}
