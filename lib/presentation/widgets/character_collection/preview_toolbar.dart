import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';

/// 预览工具栏
class PreviewToolbar extends ConsumerWidget {
  const PreviewToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolMode = ref.watch(toolModeProvider);
    final hasSelection = ref
        .watch(characterCollectionProvider)
        .regions
        .map((e) => e.isSelected)
        .toList()
        .isNotEmpty;

    return Material(
      color: Colors.white,
      elevation: 4,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // 工具按钮组
            _ToolButton(
              icon: Icons.pan_tool,
              tooltip: '拖拽工具 (V)',
              isSelected: toolMode == Tool.pan,
              onPressed: () =>
                  ref.read(toolModeProvider.notifier).setMode(Tool.pan),
            ),
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.crop_square,
              tooltip: '框选工具 (S)',
              isSelected: toolMode == Tool.select,
              onPressed: () =>
                  ref.read(toolModeProvider.notifier).setMode(Tool.select),
            ),
            const SizedBox(width: 16),

            // 分隔线
            const VerticalDivider(),
            const SizedBox(width: 8),

            // 删除按钮
            _ToolButton(
              icon: Icons.delete,
              tooltip: '删除选中区域（D或Del）',
              isEnabled: hasSelection,
              onPressed: hasSelection
                  ? () {
                      final selectedIds = ref
                          .read(characterCollectionProvider)
                          .regions
                          .where((e) => e.isSelected)
                          .map((e) => e.id)
                          .toList();
                      ref
                          .read(characterCollectionProvider.notifier)
                          .deleteBatchRegions(selectedIds);
                    }
                  : null,
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
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isSelected = false,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: isEnabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor:
              isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
          foregroundColor: isSelected
              ? theme.colorScheme.primary
              : isEnabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.38),
        ),
      ),
    );
  }
}
