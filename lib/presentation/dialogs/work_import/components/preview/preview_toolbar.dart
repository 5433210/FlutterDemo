import 'package:flutter/material.dart';
import '../../../../theme/app_sizes.dart';

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
      height: 48,
      padding: const EdgeInsets.all(AppSizes.m),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加图片'),
          ),
          const SizedBox(width: AppSizes.l),
          IconButton(
            onPressed: hasSelection ? onRotateLeft : null,
            icon: const Icon(Icons.rotate_left),
            tooltip: '向左旋转',
          ),
          IconButton(
            onPressed: hasSelection ? onRotateRight : null,
            icon: const Icon(Icons.rotate_right),
            tooltip: '向右旋转',
          ),
          IconButton(
            onPressed: hasSelection ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
          ),
          const Spacer(),
          if (hasImages)
            Text(
              '提示：点击图片可以预览，拖动可以调整顺序',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}