import 'package:flutter/material.dart';

import 'practice_edit_controller.dart';

/// 编辑工具栏
class EditToolbar extends StatelessWidget {
  final PracticeEditController controller;
  final bool gridVisible;
  final bool snapEnabled;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnap;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onGroupElements;
  final VoidCallback onUngroupElements;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  const EditToolbar({
    Key? key,
    required this.controller,
    required this.gridVisible,
    required this.snapEnabled,
    required this.onToggleGrid,
    required this.onToggleSnap,
    required this.onCopy,
    required this.onPaste,
    required this.onGroupElements,
    required this.onUngroupElements,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSelection = controller.state.selectedElementIds.isNotEmpty;
    final isMultiSelected = controller.state.selectedElementIds.length > 1;
    final hasSelectedGroup =
        hasSelection && !isMultiSelected && _isSelectedElementGroup();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑操作组
            _buildToolbarGroup(
              title: '编辑操作',
              children: [
                _buildToolbarButton(
                  icon: Icons.copy,
                  tooltip: '复制 (Ctrl+Shift+C)',
                  onPressed: hasSelection ? onCopy : null,
                ),
                _buildToolbarButton(
                  icon: Icons.paste,
                  tooltip: '粘贴 (Ctrl+Shift+V)',
                  onPressed: onPaste,
                ),
                _buildToolbarButton(
                  icon: Icons.delete,
                  tooltip: '删除 (Ctrl+D)',
                  onPressed: hasSelection ? onDelete : null,
                ),
                _buildToolbarButton(
                  icon: Icons.group,
                  tooltip: '组合 (Ctrl+J)',
                  onPressed: isMultiSelected ? onGroupElements : null,
                ),
                _buildToolbarButton(
                  icon: Icons.format_shapes,
                  tooltip: '取消组合 (Ctrl+U)',
                  onPressed: hasSelectedGroup ? onUngroupElements : null,
                ),
              ],
            ),

            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

            // 层级操作组
            _buildToolbarGroup(
              title: '层级操作',
              children: [
                _buildToolbarButton(
                  icon: Icons.vertical_align_top,
                  tooltip: '置于顶层 (Ctrl+T)',
                  onPressed: hasSelection ? onBringToFront : null,
                ),
                _buildToolbarButton(
                  icon: Icons.vertical_align_bottom,
                  tooltip: '置于底层 (Ctrl+B)',
                  onPressed: hasSelection ? onSendToBack : null,
                ),
                _buildToolbarButton(
                  icon: Icons.arrow_upward,
                  tooltip: '上移一层 (Ctrl+Shift+T)',
                  onPressed: hasSelection ? onMoveUp : null,
                ),
                _buildToolbarButton(
                  icon: Icons.arrow_downward,
                  tooltip: '下移一层 (Ctrl+Shift+B)',
                  onPressed: hasSelection ? onMoveDown : null,
                ),
              ],
            ),

            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

            // 辅助功能组
            _buildToolbarGroup(
              title: '辅助功能',
              children: [
                _buildToolbarButton(
                  icon: gridVisible ? Icons.grid_on : Icons.grid_off,
                  tooltip: gridVisible ? '隐藏网格 (Ctrl+G)' : '显示网格 (Ctrl+G)',
                  onPressed: onToggleGrid,
                  isActive: gridVisible,
                ),
                _buildToolbarButton(
                  icon: Icons
                      .format_line_spacing, // Alternative icon for snapping/alignment
                  tooltip: snapEnabled ? '禁用吸附 (Ctrl+R)' : '启用吸附 (Ctrl+R)',
                  onPressed: onToggleSnap,
                  isActive: snapEnabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.blue : null,
          size: 20,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }

  /// 构建工具栏分组
  Widget _buildToolbarGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 工具组标题
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        // 工具按钮组
        ...children,
      ],
    );
  }

  /// 检查选中的元素是否为组合元素
  bool _isSelectedElementGroup() {
    if (controller.state.selectedElementIds.isEmpty) return false;

    final id = controller.state.selectedElementIds.first;
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'type': ''},
    );

    return element['type'] == 'group';
  }
}
