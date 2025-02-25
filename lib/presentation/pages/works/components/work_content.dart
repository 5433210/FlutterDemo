import 'package:flutter/material.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../theme/app_sizes.dart';

class WorkContent extends ConsumerWidget {
  final WorkBrowseState state;

  const WorkContent({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (state.isSidebarOpen) ...[
          SizedBox(
            width: AppSizes.sidebarWidth,
            child: WorkFilterPanel(
              filter: state.filter,
              onFilterChanged: (filter) => 
                  ref.read(workBrowseProvider.notifier).updateFilter(filter),
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        
        Expanded(
          child: state.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : state.viewMode == ViewMode.grid
                  ? WorkGridView(...)  // 传递必要的参数
                  : WorkListView(...), // 传递必要的参数
        ),
      ],
    );
  }
}
