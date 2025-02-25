import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';
import '../work_toolbar.dart';
import '../work_content.dart';
import '../sidebar/work_sidebar.dart';

class WorkLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    return Column(
      children: [
        // 工具栏
        WorkToolbar(
          viewMode: state.viewMode,
          onViewModeToggle: viewModel.toggleViewMode,
          onImport: () => _showImportDialog(context),
        ),
        // 主内容区
        Expanded(
          child: Row(
            children: [
              // 侧边栏过滤面板
              if (state.isSidebarOpen) ...[
                SizedBox(
                  width: AppSizes.sidebarWidth,
                  child: WorkFilterPanel(
                    filter: state.filter,
                    onFilterChanged: viewModel.updateFilter,
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              // 作品内容区
              Expanded(
                child: WorkContent(state: state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    // ...dialog show logic...
  }
}
