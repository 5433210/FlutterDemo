import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import '../../../viewmodels/states/work_browse_state.dart';

class WorkToolbar extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onImport;
  final ValueChanged<String> onSearch;
  final bool batchMode;
  final ValueChanged<bool> onBatchModeChanged;
  final int selectedCount;
  final VoidCallback onDeleteSelected;

  const WorkToolbar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onImport,
    required this.onSearch,
    required this.batchMode,
    required this.onBatchModeChanged,
    required this.selectedCount,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: onImport,
            tooltip: '导入作品',
          ),
          const SizedBox(width: AppSizes.s),
          IconButton(
            icon: Icon(batchMode ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: () => onBatchModeChanged(!batchMode),
            tooltip: batchMode ? '退出批量选择' : '批量选择',
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: AppSizes.m),
          IconButton(
            icon: Icon(viewMode == ViewMode.grid ? Icons.grid_view : Icons.list),
            onPressed: () => onViewModeChanged(
              viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
            ),
            tooltip: viewMode == ViewMode.grid ? '切换到列表视图' : '切换到网格视图',
          ),
          if (batchMode && selectedCount > 0) ...[
            const SizedBox(width: AppSizes.m),
            Text('已选择 $selectedCount 项'),
            const SizedBox(width: AppSizes.s),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.delete),
              label: Text('删除$selectedCount项'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除选中的 $selectedCount 个作品吗？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  onDeleteSelected();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $selectedCount 个作品吗？此操作不可恢复。'),
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
      onDeleteSelected();
    }
  }
}
