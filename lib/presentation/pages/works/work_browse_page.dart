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
  // 使用一个简单标记
  bool _initialized = false;
  bool _initialLoadAttempted = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    debugPrint('WorkBrowsePage rebuild - filter: ${state.filter}');

    // 监听刷新标志
    ref.listen(worksNeedsRefreshProvider, (previous, current) {
      if (current == true) {
        // 如果需要刷新，则执行刷新并重置标志
        viewModel.loadWorks(forceRefresh: true);
        ref.read(worksNeedsRefreshProvider.notifier).state = false;
      }
    });

    // 首次构建完成后立即检查加载状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadData();
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
            onDeleteSelected: () =>
                ref.read(workBrowseProvider.notifier).deleteSelected(),
          ),
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
                // 手动触发刷新
                ref
                    .read(workBrowseProvider.notifier)
                    .loadWorks(forceRefresh: true);
              },
              tooltip: '重新加载',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台恢复时，刷新列表以确保数据最新
    if (state == AppLifecycleState.resumed) {
      _loadWorks();
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
    // 统一初始化点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        // 只在这里触发一次初始加载
        ref.read(workBrowseProvider.notifier).loadWorks();
      }
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

  // 检查并加载数据的方法
  void _checkAndLoadData() {
    final currentState = ref.read(workBrowseProvider);

    // 如果当前没有数据且不是正在加载状态，尝试加载
    if (currentState.works.isEmpty &&
        !currentState.isLoading &&
        currentState.error == null) {
      AppLogger.debug('浏览页面需要加载数据', tag: 'WorkBrowsePage');
      //_loadWorks(force: true);
    }
  }

  void _handleWorkSelected(BuildContext context, String workId) async {
    // 导航到详情页并等待结果
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.workDetail,
      arguments: workId,
    );

    // 检查返回值，但现在不仅检查是否为true，还检查refreshProvider
    if (mounted) {
      if (result == true || ref.read(worksNeedsRefreshProvider)) {
        // 如果返回值为true或刷新标志为true，刷新列表
        ref.read(workBrowseProvider.notifier).loadWorks(forceRefresh: true);
        // 重置刷新标志
        if (ref.read(worksNeedsRefreshProvider)) {
          ref.read(worksNeedsRefreshProvider.notifier).state = false;
        }
      }
    }
  }

  // 初始加载方法
  Future<void> _initialLoad() async {
    if (_initialLoadAttempted) return;
    _initialLoadAttempted = true;

    try {
      AppLogger.info('初始加载浏览页数据', tag: 'WorkBrowsePage');
      await ref.read(workBrowseProvider.notifier).loadWorks(forceRefresh: true);
    } catch (e) {
      AppLogger.error('初始加载失败', tag: 'WorkBrowsePage', error: e);

      if (mounted) {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () => _loadWorks(force: true),
            ),
          ),
        );
      }
    }
  }

  // 增强错误处理的加载方法
  Future<void> _loadWorks({bool force = false}) async {
    try {
      AppLogger.debug('触发作品加载', tag: 'WorkBrowsePage', data: {'force': force});

      await ref
          .read(workBrowseProvider.notifier)
          .loadWorks(forceRefresh: force);
    } catch (e) {
      AppLogger.error('加载作品失败', tag: 'WorkBrowsePage', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );

    if (result == true) {
      ref.read(workBrowseProvider.notifier).loadWorks();
    }
  }
}
