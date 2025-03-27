import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';

class PreviewToolbar extends ConsumerWidget {
  const PreviewToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolMode = ref.watch(toolModeProvider);
    final collectionState = ref.watch(characterCollectionProvider);
    final canUndo = collectionState.undoStack.isNotEmpty;
    final canRedo = collectionState.redoStack.isNotEmpty;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 拖拽工具
          _ToolbarButton(
            icon: Icons.pan_tool_alt,
            tooltip: '平移工具',
            isSelected: toolMode == Tool.pan,
            onPressed: () =>
                ref.read(toolModeProvider.notifier).setMode(Tool.pan),
          ),

          // 框选工具
          _ToolbarButton(
            icon: Icons.crop_free,
            tooltip: '框选工具',
            isSelected: toolMode == Tool.selection,
            onPressed: () =>
                ref.read(toolModeProvider.notifier).setMode(Tool.selection),
          ),

          // 多选工具
          _ToolbarButton(
            icon: Icons.select_all,
            tooltip: '多选工具',
            isSelected: toolMode == Tool.multiSelect,
            onPressed: () =>
                ref.read(toolModeProvider.notifier).setMode(Tool.multiSelect),
          ),

          // 分隔线
          const SizedBox(width: 8),
          const VerticalDivider(),
          const SizedBox(width: 8),

          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除选中',
            onPressed: collectionState.selectedIds.isEmpty
                ? null
                : () => _showDeleteConfirmation(context, ref),
          ),

          const Spacer(),

          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed: canUndo
                ? () => ref.read(characterCollectionProvider.notifier).undo()
                : null,
          ),

          // 重做按钮
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            onPressed: canRedo
                ? () => ref.read(characterCollectionProvider.notifier).redo()
                : null,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.read(characterCollectionProvider).selectedIds;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除${selectedIds.length}个选中的字符区域吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(characterCollectionProvider.notifier)
                  .deleteBatchRegions(selectedIds.toList());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolbarButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
