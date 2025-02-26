import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/work_browse_provider.dart';
import '../../../../viewmodels/states/work_browse_state.dart';

class ViewModeToggle extends ConsumerWidget {
  const ViewModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    return Tooltip(
      message: state.viewMode == ViewMode.grid ? '切换到列表视图' : '切换到网格视图',
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            state.viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
            key: ValueKey(state.viewMode),
          ),
        ),
        onPressed: viewModel.toggleViewMode,
      ),
    );
  }
}
