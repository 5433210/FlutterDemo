import 'package:flutter/material.dart';

/// 图片操作工具栏
class ImageOperationsToolbar extends StatelessWidget {
  final VoidCallback? onAddImages;
  final VoidCallback? onDeleteImage;
  final VoidCallback? onSortImages;

  const ImageOperationsToolbar({
    super.key,
    this.onAddImages,
    this.onDeleteImage,
    this.onSortImages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 添加图片按钮 - simplified to a single button
        Tooltip(
          message: '可按住Ctrl多选',
          child: FilledButton.tonalIcon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加图片'),
          ),
        ),
        const SizedBox(width: 8),

        // 删除图片按钮
        OutlinedButton.icon(
          onPressed: onDeleteImage,
          icon: const Icon(Icons.delete_outline),
          label: const Text('删除图片'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withOpacity(
                onDeleteImage == null ? 0.38 : 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 排序图片按钮
        OutlinedButton.icon(
          onPressed: onSortImages,
          icon: const Icon(Icons.sort),
          label: const Text('排序'),
        ),
      ],
    );
  }
}
