import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import 'toolbar/batch_mode_button.dart';
import 'toolbar/import_button.dart';
import 'toolbar/search_field.dart';
import 'toolbar/view_mode_toggle.dart';
import '../../../viewmodels/states/work_browse_state.dart';

class WorkToolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      child: Row(
        children: [
          // 导入按钮
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('导入作品'),
            onPressed: () => _showImportDialog(context, ref),
          ),
          const SizedBox(width: AppSizes.s),
          BatchModeButton(
            isActive: state.batchMode,
            onChanged: (value) => viewModel.setBatchMode(value),
          ),
          const Spacer(),
          ViewModeToggle(
            viewMode: state.viewMode,
            onChanged: (value) => viewModel.setViewMode(value),
          ),
          const SizedBox(width: AppSizes.s),
          SearchField(
            controller: state.searchController,
            onChanged: (value) => viewModel.setSearchQuery(value),
          ),
          if (state.batchMode) _buildBatchActions(state, viewModel),
        ],
      ),
    );
  }

  Widget _buildBatchActions(WorkBrowseState state, WorkBrowseViewModel viewModel) {
    return Row(
      children: [
        const SizedBox(width: AppSizes.m),
        Text('已选择 ${state.selectedCount} 项'),
        if (state.selectedCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.s),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.delete),
              label: Text('删除${state.selectedCount}项'),
              onPressed: viewModel.deleteSelectedWorks,
            ),
          ),
      ],
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );

    if (result == true) {
      // 刷新作品列表
      await ref.read(workBrowseProvider.notifier).loadWorks();
    }
  }
}
