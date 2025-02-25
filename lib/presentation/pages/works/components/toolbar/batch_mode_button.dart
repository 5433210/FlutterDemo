import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/work_browse_provider.dart';

class BatchModeButton extends ConsumerWidget {
  const BatchModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return TextButton.icon(
      icon: Icon(state.batchMode ? Icons.close : Icons.checklist),
      label: Text(state.batchMode ? '完成' : '批量处理'),
      onPressed: () {
        viewModel.toggleBatchMode();
        // 退出批量模式时清空选择
        if (state.batchMode) {
          viewModel.clearSelection();
        }
      },
    );
  }
}
