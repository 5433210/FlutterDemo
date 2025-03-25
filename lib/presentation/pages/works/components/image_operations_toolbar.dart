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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 添加图片按钮
        Tooltip(
          message: '添加图片',
          preferBelow: false,
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: onAddImages,
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              color: theme.colorScheme.onPrimary,
              padding: EdgeInsets.zero,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 删除图片按钮
        Tooltip(
          message: '删除图片',
          preferBelow: false,
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: onDeleteImage == null
                    ? theme.colorScheme.error.withOpacity(0.3)
                    : theme.colorScheme.error.withOpacity(0.8),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: onDeleteImage,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: onDeleteImage == null
                  ? theme.colorScheme.error.withOpacity(0.3)
                  : theme.colorScheme.error,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
