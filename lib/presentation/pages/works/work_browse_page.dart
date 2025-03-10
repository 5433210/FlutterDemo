import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../routes/app_routes.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../providers/work_browse_provider.dart';
import '../../providers/works_providers.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/common/sidebar_toggle.dart';
import 'components/content/work_grid_view.dart';
import 'components/content/work_list_view.dart';
import 'components/filter/work_filter_panel.dart';
import 'components/work_browse_toolbar.dart';
// 添加这个导入

class WorkBrowsePage extends ConsumerStatefulWidget {
  const WorkBrowsePage({super.key});

  @override
  ConsumerState<WorkBrowsePage> createState() => _WorkBrowsePageState();
}

class _WorkBrowsePageState extends ConsumerState<WorkBrowsePage>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    debugPrint('WorkBrowsePage rebuild - filter: ${state.filter}');

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
          WorkBrowseToolbar(
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
                SidebarToggle(
                  isOpen: state.isSidebarOpen,
                  onToggle: () => viewModel.toggleSidebar(),
                ),
                if (state.isSidebarOpen)
                  SizedBox(
                    width: 300,
                    child: WorkFilterPanel(
                      filter: state.filter,
                      onFilterChanged: viewModel.updateFilter,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: state.isLoading && state.works.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                _loadWorks(force: true);
              },
              tooltip: '重新加载',
              child: const Icon(Icons.refresh),
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
        AppLogger.error('设置刷新标志失败', tag: 'WorkBrowsePage', error: e);
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
        reason: '应用启动初始化',
        force: true,
        priority: 10,
      );
    });
  }

  Widget _buildMainContent() {
    // 在这里监听状态变化
    final state = ref.watch(workBrowseProvider);
    debugPrint(
        '_buildMainContent rebuild - works count: ${state.works.length}');

    // 添加详细日志，追踪状态变化
    AppLogger.debug('构建浏览页主体内容', tag: 'WorkBrowsePage', data: {
      'isLoading': state.isLoading,
      'hasError': state.error != null,
      'worksCount': state.works.length
    });

    // 处理错误状态
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('发生错误: ${state.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadWorks(force: true),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.works.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('没有找到作品', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text('尝试导入新作品或修改筛选条件',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _showImportDialog(context),
                            child: const Text('导入作品'),
                          ),
                        ],
                      ),
                    )
                  : state.viewMode == ViewMode.grid
                      ? WorkGridView(
                          works: state.works,
                          batchMode: state.batchMode,
                          selectedWorks: state.selectedWorks,
                          onSelectionChanged: (workId, selected) => ref
                              .read(workBrowseProvider.notifier)
                              .toggleSelection(workId),
                          onItemTap: (workId) =>
                              _handleWorkSelected(context, workId),
                        )
                      : WorkListView(
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

      AppLogger.debug('出错后用户手动触发作品加载',
          tag: 'WorkBrowsePage', data: {'force': force});

      const refreshInfo = RefreshInfo(
        reason: '出错后用户手动刷新',
        force: true,
        priority: 10, // 高优先级
      );

      if (!mounted) return;
      ref.read(worksNeedsRefreshProvider.notifier).state = refreshInfo;
    } catch (e) {
      AppLogger.error('加载作品失败', tag: 'WorkBrowsePage', error: e);

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        // 先移除所有已有的SnackBar
        scaffoldMessenger.clearSnackBars();
        // 显示新的错误提示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
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
      AppLogger.debug('导入完成，准备刷新列表', tag: 'WorkBrowsePage');
      if (!mounted) return;

      ref.read(worksNeedsRefreshProvider.notifier).state = const RefreshInfo(
        reason: '导入完成后刷新',
        force: true,
        priority: 9,
      );
    }
  }
}
