import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3WorkImportNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback? onCancel;
  final bool isProcessing;
  final int totalPages;
  final int currentPage;

  const M3WorkImportNavigationBar({
    super.key,
    required this.onClose,
    required this.onStart,
    this.onCancel,
    required this.isProcessing,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return M3PageNavigationBar(
      title: l10n.import,
      titleActions: isProcessing
          ? [
              const SizedBox(width: AppSizes.m),
              Text(
                'Processing ($currentPage/$totalPages)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ]
          : null,
      showBackButton: false,
      actions: [
        // 右侧操作按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProcessing && onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: Text(l10n.cancel),
              )
            else
              FilledButton(
                onPressed: onStart,
                child: Text(l10n.import),
              ),
            const SizedBox(width: AppSizes.m),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              tooltip: l10n.cancel,
            ),
          ],
        ),
      ],
    );
  }
}
