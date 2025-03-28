import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/tool_mode_provider.dart';

/// 预览工具栏
class PreviewToolbar extends ConsumerWidget {
  const PreviewToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolMode = ref.watch(toolModeProvider);

    return Material(
      color: Colors.white,
      elevation: 4,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              '工具：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            _ToolButton(
              icon: Icons.edit,
              tooltip: '选择工具',
              isSelected: toolMode == Tool.select,
              onPressed: () =>
                  ref.read(toolModeProvider.notifier).setMode(Tool.select),
            ),
            _ToolButton(
              icon: Icons.pan_tool,
              tooltip: '平移工具',
              isSelected: toolMode == Tool.pan,
              onPressed: () =>
                  ref.read(toolModeProvider.notifier).setMode(Tool.pan),
            ),
            _ToolButton(
              icon: Icons.delete,
              tooltip: '擦除工具',
              isSelected: toolMode == Tool.erase,
              onPressed: () =>
                  ref.read(toolModeProvider.notifier).setMode(Tool.erase),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工具按钮
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.black54,
        ),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}
