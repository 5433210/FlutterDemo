import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';

class BatchModeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return TextButton.icon(
      icon: Icon(state.batchMode ? Icons.close : Icons.checklist),
      label: Text(state.batchMode ? '完成' : '批量处理'),
      onPressed: () => viewModel.toggleBatchMode(),
    );
  }
}
