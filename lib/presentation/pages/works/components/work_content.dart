import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/work_browse_provider.dart';
import '../../../theme/app_sizes.dart';
import '../../../viewmodels/states/work_browse_state.dart';
import 'content/empty_state.dart';
import 'content/items/work_grid_item.dart';
import 'content/items/work_list_item.dart';

class WorkContent extends ConsumerWidget {
  const WorkContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    // 错误状态
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSizes.m),
            Text(state.error!),
            const SizedBox(height: AppSizes.m),
            FilledButton.icon(
              onPressed: () => viewModel.loadWorks(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 加载状态
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 空状态
    if (state.works.isEmpty) {
      return WorkEmptyState(
        onImport: () => _showImportDialog(context, ref),
      );
    }

    // 内容展示
    return state.viewMode == ViewMode.grid 
        ? _buildGrid(state, ref)
        : _buildList(state, ref);
  }

  Widget _buildGrid(WorkBrowseState state, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        childAspectRatio: AppSizes.gridItemWidth / AppSizes.gridItemTotalHeight,
      ),
      itemCount: state.works.length,
      itemBuilder: (context, index) {
        final work = state.works[index];
        return WorkGridItem(
          work: work,
          selectable: state.batchMode,
          selected: state.selectedWorks.contains(work.id),
          onSelected: work.id != null 
              ? (selected) => viewModel.toggleSelection(work.id!)
              : null,
          onTap: work.id != null 
              ? () => _handleWorkTap(context, work.id!)
              : null,
        );
      },
    );
  }

  Widget _buildList(WorkBrowseState state, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: state.works.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.m),
      itemBuilder: (context, index) {
        final work = state.works[index];
        return WorkListItem(
          work: work,
          isSelectionMode: state.batchMode,
          isSelected: state.selectedWorks.contains(work.id),
          onSelectionChanged: work.id != null 
              ? (selected) => viewModel.toggleSelection(work.id!)
              : null,
          onTap: work.id != null 
              ? () => _handleWorkTap(context, work.id!)
              : null,
        );
      },
    );
  }

  void _handleWorkTap(BuildContext context, String workId) {
    Navigator.pushNamed(context, '/work/detail', arguments: workId);
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final success = await viewModel.showImportDialog(context);
    await viewModel.handleImportResult(success);
  }
}
