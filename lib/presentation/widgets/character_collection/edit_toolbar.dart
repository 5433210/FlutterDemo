import 'package:flutter/material.dart';

class EditToolbar extends StatelessWidget {
  final bool isInverted;
  final bool showOutline;
  final bool isErasing;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<bool> onInvertToggled;
  final ValueChanged<bool> onOutlineToggled;
  final ValueChanged<bool> onEraseToggled;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const EditToolbar({
    Key? key,
    required this.isInverted,
    required this.showOutline,
    required this.isErasing,
    required this.canUndo,
    required this.canRedo,
    required this.onInvertToggled,
    required this.onOutlineToggled,
    required this.onEraseToggled,
    required this.onUndo,
    required this.onRedo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // 反转开关
          _ToolbarToggleButton(
            icon: Icons.invert_colors,
            tooltip: '反转颜色',
            isSelected: isInverted,
            onPressed: () => onInvertToggled(!isInverted),
          ),

          // 轮廓开关
          _ToolbarToggleButton(
            icon: Icons.format_shapes,
            tooltip: '显示轮廓',
            isSelected: showOutline,
            onPressed: () => onOutlineToggled(!showOutline),
          ),

          // 擦除开关
          _ToolbarToggleButton(
            icon: Icons.auto_fix_high,
            tooltip: '擦除工具',
            isSelected: isErasing,
            onPressed: () => onEraseToggled(!isErasing),
          ),

          const Spacer(),

          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed: canUndo ? onUndo : null,
          ),

          // 重做按钮
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            onPressed: canRedo ? onRedo : null,
          ),
        ],
      ),
    );
  }
}

class _ToolbarToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolbarToggleButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
