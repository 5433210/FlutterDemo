import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/work_browse_provider.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../viewmodels/states/work_browse_state.dart';
import 'components/content/work_grid_view.dart';
import 'components/content/work_list_view.dart';
import 'components/filter/sidebar_toggle.dart';
import 'components/filter/work_filter_panel.dart';
import 'components/work_toolbar.dart';
// 添加这个导入

class WorkBrowsePage extends ConsumerStatefulWidget {
  const WorkBrowsePage({super.key});

  @override
  ConsumerState<WorkBrowsePage> createState() => _WorkBrowsePageState();
}

class _WorkBrowsePageState extends ConsumerState<WorkBrowsePage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    debugPrint('WorkBrowsePage rebuild - filter: ${state.filter}');

    return Scaffold(
      body: Column(
        children: [
          WorkToolbar(
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
                  WorkFilterPanel(
                    filter: state.filter,
                    onFilterChanged: viewModel.updateFilter,
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

  void _handleWorkSelected(BuildContext context, String workId) {
    Navigator.pushNamed(
      context,
      '/work_detail',
      arguments: workId,
    );
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
