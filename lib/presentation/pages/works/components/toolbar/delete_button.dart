import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/work_browse_provider.dart';

class DeleteButton extends ConsumerWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    if (!state.batchMode || state.selectedWorks.isEmpty) {
      return const SizedBox.shrink();
    }

    return FilledButton.tonalIcon(
      icon: const Icon(Icons.delete),
      label: Text('删除${state.selectedWorks.length}项'),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除选中的 ${state.selectedWorks.length} 个作品吗？'),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context, false),
              ),
              FilledButton(
                child: const Text('删除'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await viewModel.deleteSelected();
        }
      },
    );
  }
}
