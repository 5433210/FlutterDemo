import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import '../../../viewmodels/states/work_browse_state.dart';

class WorkToolbar extends StatefulWidget {  // 改为 StatefulWidget
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
  State<WorkToolbar> createState() => _WorkToolbarState();
}

class _WorkToolbarState extends State<WorkToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧按钮组
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('导入作品'),
            onPressed: widget.onImport,
          ),
          const SizedBox(width: AppSizes.s),
          OutlinedButton.icon(
            icon: Icon(widget.batchMode ? Icons.close : Icons.checklist),
            label: Text(widget.batchMode ? '完成' : '批量处理'),
            onPressed: () => widget.onBatchModeChanged(!widget.batchMode),
          ),

          // 批量操作状态 - 移到中间
          if (widget.batchMode) ...[
            const SizedBox(width: AppSizes.m),
            Text(
              '已选择 ${widget.selectedCount} 项',
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: AppSizes.s),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete),
                  label: Text('删除${widget.selectedCount}项'),
                  onPressed: widget.onDeleteSelected,
                ),
              ),
          ],

          const Spacer(),

          // 右侧控制组
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchController,  // 使用控制器
              onChanged: widget.onSearch,
              decoration: InputDecoration(
                hintText: '搜索作品...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,  // 监听控制器
                  builder: (context, value, child) {
                    return AnimatedOpacity(
                      opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        onPressed: () {
                          _searchController.clear();  // 清除文本
                          widget.onSearch('');  // 触发搜索
                        },
                      ),
                    );
                  },
                ),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s,
                  vertical: AppSizes.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.m),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.m),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                hoverColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.m),
          
          // 视图切换按钮
          IconButton(
            icon: Icon(
              widget.viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.s),
              ),
            ),
            onPressed: () => widget.onViewModeChanged(
              widget.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid
            ),
            tooltip: widget.viewMode == ViewMode.grid ? '列表视图' : '网格视图',
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${widget.selectedCount} 个作品吗？此操作不可恢复。'),
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
      widget.onDeleteSelected();
    }
  }
}
