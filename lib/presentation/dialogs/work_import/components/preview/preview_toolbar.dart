import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../theme/app_sizes.dart';

class PreviewToolbar extends StatelessWidget {
  final bool hasImages;
  final bool hasSelection;
  final VoidCallback? onAddImages; // 添加
  final VoidCallback? onRotateLeft;
  final VoidCallback? onRotateRight;
  final VoidCallback? onDelete;
  final VoidCallback? onDeleteAll;

  const PreviewToolbar({
    super.key,
    this.hasImages = false,
    this.hasSelection = false,
    this.onAddImages, // 添加
    this.onRotateLeft,
    this.onRotateRight,
    this.onDelete,
    this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // 固定工具栏高度
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.m,
          vertical: AppSizes.s,
        ),
        child: Row(
          children: [
            // 添加图片
            _ToolbarIconButton(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: AppLocalizations.of(context).addImages,
              onPressed: onAddImages,
            ),
            const SizedBox(width: AppSizes.m),
            // 向左旋转
            _ToolbarIconButton(
              icon: Icons.rotate_left,
              tooltip: AppLocalizations.of(context).rotateLeft,
              onPressed: hasSelection ? onRotateLeft : null,
            ),
            // 向右旋转
            _ToolbarIconButton(
              icon: Icons.rotate_right,
              tooltip: AppLocalizations.of(context).rotateRight,
              onPressed: hasSelection ? onRotateRight : null,
            ),
            const Spacer(),
            // 删除选中
            _ToolbarIconButton(
              icon: Icons.delete_outline,
              tooltip: AppLocalizations.of(context).deleteSelected,
              onPressed: hasSelection ? onDelete : null,
              isDestructive: true,
            ),
            // 全部删除
            _ToolbarIconButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: AppLocalizations.of(context).deleteAll,
              onPressed: hasImages ? onDeleteAll : null,
              isDestructive: true,
            ),
          ],
        ),
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
    final bool isEnabled = onPressed != null;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: isEnabled
            ? (isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant)
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        hoverColor: (isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.08),
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor:
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
      ),
    );
  }
}
