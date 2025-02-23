import 'package:flutter/material.dart';
import '../../../../../theme/app_sizes.dart';

class PreviewToolbar extends StatelessWidget {
  final bool hasImages;
  final bool hasSelection;
  final VoidCallback onAddImages;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onDelete;

  const PreviewToolbar({
    super.key,
    required this.hasImages,
    required this.hasSelection,
    required this.onAddImages,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 48, // 固定高度
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加图片'),
          ),
          if (hasImages) ...[
            const SizedBox(width: AppSizes.l),
            Container(
              padding: const EdgeInsets.all(AppSizes.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.xs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToolbarIconButton(
                    icon: Icons.rotate_left,
                    tooltip: '向左旋转',
                    onPressed: hasSelection ? onRotateLeft : null,
                  ),
                  _ToolbarIconButton(
                    icon: Icons.rotate_right,
                    tooltip: '向右旋转',
                    onPressed: hasSelection ? onRotateRight : null,
                  ),
                  _ToolbarIconButton(
                    icon: Icons.delete_outline,
                    tooltip: '删除',
                    onPressed: hasSelection ? onDelete : null,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 重新设计提示信息
            MouseRegion(
              cursor: SystemMouseCursors.help,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '拖动排序',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: isDestructive 
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}