import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_sizes.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../providers/work_browse_provider.dart';
import '../../providers/works_providers.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/common/sidebar_toggle.dart';
import 'components/content/m3_work_grid_view.dart';
import 'components/content/m3_work_list_view.dart';
import 'components/filter/m3_work_filter_panel.dart';
import 'components/m3_work_browse_toolbar.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // 改进刷新监听器
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
        // 刷新完成后重置状态
        if (mounted) {
          ref.read(worksNeedsRefreshProvider.notifier).state = null;
        }
      }
    });

    return Scaffold(
      body: Column(
        children: [
          M3WorkBrowseToolbar(
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
                  }),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildMainContent(),
                ),
                AnimatedContainer(
                  duration: const Duration(
                      milliseconds: AppSizes.animationDurationSlow),
                  width: 4,
                  color: state.isSidebarOpen
                      ? colorScheme.outlineVariant
                      : Colors.transparent,
                ),
                SidebarToggle(
                  isOpen: state.isSidebarOpen,
                  onToggle: () => viewModel.toggleSidebar(),
                ),
                AnimatedContainer(
                  duration: const Duration(
                      milliseconds: AppSizes.animationDurationSlow),
                  width:
                      state.isSidebarOpen ? AppSizes.workFilterPanelWidth : 0,
                  child: state.isSidebarOpen
                      ? M3WorkFilterPanel(
                          filter: state.filter,
                          onFilterChanged: viewModel.updateFilter,
                        )
                      : null,
                ),
              ],
            ),
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
    // 简化生命周期管理，只在应用恢复时刷新
    if (state == AppLifecycleState.resumed) {
      try {
        // 应用恢复时触发刷新标志，而非直接调用
        ref.read(worksNeedsRefreshProvider.notifier).state =
            RefreshInfo.appResume(); // 使用工厂方法替代直接构造
      } catch (e) {
        // 添加错误处理，防止意外异常
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

    // 延迟执行初始加载，确保widget完全初始化
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
    // 在这里监听状态变化
    final state = ref.watch(workBrowseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // 处理错误状态
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

    return Column(
      children: [
        Expanded(
          child: state.isLoading
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
                              color:
                                  colorScheme.onSurfaceVariant.withAlpha(128)),
                          const SizedBox(height: 16),
                          Text(l10n.workBrowseNoWorks,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(l10n.workBrowseNoWorksHint,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant)),
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
                          onItemTap: (workId) =>
                              _handleWorkSelected(context, workId),
                        )
                      : M3WorkListView(
                          works: state.works,
                          batchMode: state.batchMode,
                          selectedWorks: state.selectedWorks,
                          onSelectionChanged: (workId, selected) => ref
                              .read(workBrowseProvider.notifier)
                              .toggleSelection(workId),
                          onItemTap: (workId) =>
                              _handleWorkSelected(context, workId),
                        ),
        ),
      ],
    );
  }

  void _handleWorkSelected(BuildContext context, String workId) async {
    // 导航到详情页并等待结果
    await Navigator.pushNamed(
      context,
      AppRoutes.workDetail,
      arguments: workId,
    );
  }

  // 增强错误处理的加载方法
  Future<void> _loadWorks({bool force = false}) async {
    try {
      if (!mounted) return;

      AppLogger.debug('User manually triggered works loading after error',
          tag: 'WorkBrowsePage', data: {'force': force});

      const refreshInfo = RefreshInfo(
        reason: 'User manual refresh after error',
        force: true,
        priority: 10, // 高优先级
      );

      if (!mounted) return;
      ref.read(worksNeedsRefreshProvider.notifier).state = refreshInfo;
    } catch (e) {
      AppLogger.error('Failed to load works', tag: 'WorkBrowsePage', error: e);

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final l10n = AppLocalizations.of(context);
        // 先移除所有已有的SnackBar
        scaffoldMessenger.clearSnackBars();
        // 显示新的错误提示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.workBrowseError(e.toString()))),
        );
      }
    }
  }

  // 简化为一个统一的导入对话框方法
  Future<void> _showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );

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
