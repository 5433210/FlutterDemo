import 'package:flutter/material.dart';

/// 编辑工具栏组件
class EditToolbar extends StatelessWidget {
  final bool gridVisible;
  final bool snapEnabled;
  final bool hasSelection;
  final bool isGroupSelection;
  final bool hasMultiSelection;
  final Function(String) onToolSelected;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onDelete;
  final VoidCallback? onGroup;
  final VoidCallback? onUngroup;
  final VoidCallback onToggleGrid;
  final Function(double) onSetGridSize;
  final Function(bool) onToggleSnap;

  const EditToolbar({
    super.key,
    required this.gridVisible,
    required this.snapEnabled,
    required this.hasSelection,
    required this.isGroupSelection,
    required this.hasMultiSelection,
    required this.onToolSelected,
    this.onCopy,
    this.onPaste,
    this.onDelete,
    this.onGroup,
    this.onUngroup,
    required this.onToggleGrid,
    required this.onSetGridSize,
    required this.onToggleSnap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 编辑操作组
          IconButton(
            icon: const Icon(Icons.pan_tool),
            tooltip: '页面平移',
            onPressed: () => onToolSelected('pan'),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: '复制',
            onPressed: hasSelection ? onCopy : null,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: '粘贴',
            onPressed: onPaste,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除',
            onPressed: hasSelection ? onDelete : null,
          ),

          const VerticalDivider(),

          // 组合操作
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: '组合',
            onPressed: hasMultiSelection ? onGroup : null,
          ),
          IconButton(
            icon: const Icon(Icons.group_work_outlined),
            tooltip: '取消组合',
            onPressed: isGroupSelection ? onUngroup : null,
          ),

          const VerticalDivider(),

          // 辅助功能组
          Row(
            children: [
              const Text('网格: ', style: TextStyle(fontSize: 14)),
              IconButton(
                icon: Icon(gridVisible ? Icons.grid_on : Icons.grid_off),
                tooltip: '显示网格',
                onPressed: onToggleGrid,
              ),
              const SizedBox(width: 8),
              DropdownButton<double>(
                value: 20.0, // 假设网格默认大小是20
                items: const [
                  DropdownMenuItem(value: 10.0, child: Text('10px')),
                  DropdownMenuItem(value: 20.0, child: Text('20px')),
                  DropdownMenuItem(value: 50.0, child: Text('50px')),
                ],
                onChanged:
                    gridVisible ? (value) => onSetGridSize(value!) : null,
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 吸附开关
          Row(
            children: [
              const Text('吸附: ', style: TextStyle(fontSize: 14)),
              Switch(
                value: snapEnabled,
                onChanged: onToggleSnap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
