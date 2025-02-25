import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/work_browse_provider.dart';

class BatchModeSection extends ConsumerWidget {
  const BatchModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);
    
    return Row(
      children: [
        TextButton.icon(
          icon: Icon(state.batchMode ? Icons.close : Icons.checklist),
          label: Text(state.batchMode ? '完成' : '批量处理'),
          onPressed: () => viewModel.toggleBatchMode(),
        ),
        if (state.batchMode && state.selectedWorks.isNotEmpty) ...[
          Text('已选择 ${state.selectedWorks.length} 项'),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.delete),
            label: Text('删除${state.selectedWorks.length}项'),
            onPressed: () => viewModel.deleteSelected(),
          ),
        ],
      ],
    );
  }
}
