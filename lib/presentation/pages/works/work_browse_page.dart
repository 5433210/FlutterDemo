import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../application/providers/work_browse_provider.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../theme/app_sizes.dart';
import '../../viewmodels/states/work_browse_state.dart';
import 'components/content/items/work_grid_item.dart';
import 'components/content/items/work_list_item.dart';
import 'components/filter/work_filter_panel.dart';
import 'components/layout/work_layout.dart';
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
    
    return Scaffold(
      body: Column(
        children: [
          WorkToolbar(  // 添加工具栏
            viewMode: state.viewMode,
            onViewModeChanged: (mode) => viewModel.setViewMode(mode),
            onImport: () => _showImportDialog(context),
            onSearch: viewModel.setSearchQuery,
            batchMode: state.batchMode,
            onBatchModeChanged: (_) => viewModel.toggleBatchMode(),
            selectedCount: state.selectedWorks.length,
            onDeleteSelected: viewModel.deleteSelected,
          ),
          Expanded(
            child: WorkLayout(
              filterPanel: const WorkFilterPanel(),
              child: _buildMainContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(WorkBrowseState state) {
    return Column(
      children: [
        // ...existing toolbar code...
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.works.isEmpty
                  ? const Center(child: Text('没有作品'))
                  : state.viewMode == ViewMode.grid
                      ? _buildGrid(state.works)
                      : _buildList(state.works),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Work> works) {
    final state = ref.watch(workBrowseProvider);
    
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        childAspectRatio: AppSizes.gridItemWidth / AppSizes.gridItemTotalHeight,
      ),
      itemCount: works.length,
      itemBuilder: (context, index) {
        final work = works[index];
        return WorkGridItem(
          work: work,
          onTap: () {
            if (state.batchMode) {
              ref.read(workBrowseProvider.notifier).toggleSelection(work.id!);
            } else {
              _handleWorkSelected(context, work.id!);
            }
          },
        );
      },
    );
  }

  Widget _buildList(List<Work> works) {
    final state = ref.watch(workBrowseProvider);
    
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: works.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final work = works[index];
        return WorkListItem(
          work: work,
          onTap: () {
            if (state.batchMode) {
              ref.read(workBrowseProvider.notifier).toggleSelection(work.id!);
            } else {
              _handleWorkSelected(context, work.id!);
            }
          },
        );
      },
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