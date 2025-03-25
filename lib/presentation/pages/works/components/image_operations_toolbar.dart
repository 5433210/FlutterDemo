import 'package:flutter/material.dart';

class ImageOperationsToolbar extends StatelessWidget {
  final VoidCallback? onAddImages;
  final VoidCallback? onDeleteImage;

  const ImageOperationsToolbar({
    super.key,
    this.onAddImages,
    this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 添加图片按钮
          FilledButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add_photo_alternate, size: 16),
            label: const Text('添加图片'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 24,
              child: VerticalDivider(
                width: 1,
                color: theme.dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          // 删除图片按钮
          OutlinedButton.icon(
            onPressed: onDeleteImage,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('删除图片'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withOpacity(
                  onDeleteImage == null ? 0.38 : 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
