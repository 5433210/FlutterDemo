import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_routes.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../providers/work_browse_provider.dart';
import '../../viewmodels/states/work_browse_state.dart';
import 'components/content/work_grid_view.dart';
import 'components/content/work_list_view.dart';
import 'components/filter/sidebar_toggle.dart';
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
                if (state.isSidebarOpen)
                  SizedBox(
                    width: 300,
                    child: WorkFilterPanel(
                      filter: state.filter,
                      onFilterChanged: viewModel.updateFilter,
                    ),
                  ),
                SidebarToggle(
                  isOpen: state.isSidebarOpen,
                  onToggle: () => viewModel.toggleSidebar(),
                ),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
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
    _loadWorks();
  }

  Widget _buildMainContent() {
    // 在这里监听状态变化
    final state = ref.watch(workBrowseProvider);
    debugPrint(
        '_buildMainContent rebuild - works count: ${state.works.length}');

    return Column(
      children: [
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.works.isEmpty
                  ? const Center(child: Text('没有作品'))
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
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.workDetail,
      arguments: workId,
    );

    // 如果返回值为true（表示作品已删除），则刷新列表
    if (result == true && mounted) {
      ref.read(workBrowseProvider.notifier).loadWorks(forceRefresh: true);
    }
  }

  Future<void> _loadWorks() async {
    await ref.read(workBrowseProvider.notifier).loadWorks();
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
