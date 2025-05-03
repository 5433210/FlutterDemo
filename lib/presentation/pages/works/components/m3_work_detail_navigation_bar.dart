import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3WorkDetailNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool isEditing;
  final bool hasChanges;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onExtract;
  final bool showExtractButton;

  const M3WorkDetailNavigationBar({
    super.key,
    required this.title,
    required this.isEditing,
    required this.hasChanges,
    required this.onBack,
    this.onEdit,
    this.onSave,
    this.onCancel,
    this.onExtract,
    this.showExtractButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return M3PageNavigationBar(
      title: l10n.workDetailTitle,
      titleActions: title.isNotEmpty
          ? [
              const SizedBox(width: AppSizes.s),
              Flexible(
                child: Text(
                  '- $title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          : null,
      onBackPressed: onBack,
      actions: [
        // 右侧操作按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑模式的操作按钮
            if (isEditing) ...[
              // 取消按钮
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: Text(l10n.workDetailCancel),
                onPressed: onCancel,
              ),
              const SizedBox(width: AppSizes.m),
              // 保存按钮
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.workDetailSave),
                onPressed: hasChanges ? onSave : null,
              ),
            ]
            // 查看模式的操作按钮
            else ...[
              // 提取字符按钮组
              if (showExtractButton) ...[
                // 使用垂直分隔线分组相关按钮
                const VerticalDivider(indent: 8, endIndent: 8),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.text_fields),
                      label: Text(l10n.workDetailExtract),
                      onPressed: onExtract,
                    ),
                  ],
                ),

                const VerticalDivider(indent: 8, endIndent: 8),
              ],

              // 编辑按钮
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(l10n.workDetailEdit),
                onPressed: onEdit,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
