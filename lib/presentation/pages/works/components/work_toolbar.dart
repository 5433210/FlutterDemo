import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/work_browse_provider.dart';
import '../../../theme/app_sizes.dart';
import 'toolbar/batch_mode_button.dart';
import 'toolbar/import_button.dart';
import 'toolbar/search_field.dart';
import 'toolbar/view_mode_toggle.dart';

class WorkToolbar extends ConsumerWidget {
  const WorkToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const ImportButton(),
          const SizedBox(width: AppSizes.s),
          const BatchModeButton(),
          const Spacer(),
          const SearchField(),
          const SizedBox(width: AppSizes.m),
          const ViewModeToggle(),
          if (state.batchMode) ...[
            const SizedBox(width: AppSizes.m),
            if (state.selectedWorks.isNotEmpty) ...[
              Text('已选择 ${state.selectedWorks.length} 项'),
              const SizedBox(width: AppSizes.s),
              FilledButton.tonalIcon(
                onPressed: viewModel.deleteSelected,
                icon: const Icon(Icons.delete),
                label: Text('删除${state.selectedWorks.length}项'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
