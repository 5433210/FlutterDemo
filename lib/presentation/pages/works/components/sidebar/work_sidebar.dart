import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';
import '../filter/work_filter_panel.dart';
import 'sidebar_toggle_button.dart';

class WorkSidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return Row(
      children: [
        if (state.isSidebarOpen) ...[
          Container(
            width: AppSizes.sidebarWidth,
            child: WorkFilterPanel(),
          ),
          const VerticalDivider(width: 1),
        ],
        SidebarToggleButton(
          isExpanded: state.isSidebarOpen,
          onToggle: () => viewModel.toggleSidebar(),
        ),
      ],
    );
  }
}
