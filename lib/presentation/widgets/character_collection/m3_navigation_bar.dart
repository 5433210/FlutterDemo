import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_collection_provider.dart';
import '../common/m3_page_navigation_bar.dart';

class M3NavigationBar extends ConsumerWidget implements PreferredSizeWidget {
  final String workId;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const M3NavigationBar({
    super.key,
    required this.workId,
    required this.onBack,
    this.onHelp,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final collectionState = ref.watch(characterCollectionProvider);

    // Calculate status text
    String statusText = '';
    if (collectionState.processing) {
      statusText = l10n.processing;
    } else if (collectionState.error != null) {
      statusText = l10n.error(collectionState.error!);
    }

    return M3PageNavigationBar(
      title: l10n.characterCollectionTitle,
      onBackPressed: onBack,
      titleActions: statusText.isNotEmpty
          ? [
              const SizedBox(width: AppSizes.m),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: collectionState.error != null
                      ? colorScheme.error.withValues(alpha: 0.1)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.m),
                ),
                child: Text(
                  statusText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: collectionState.error != null
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ),
            ]
          : null,
      actions: const [
        // 帮助按钮已屏蔽
      ],
    );
  }

  // 帮助相关方法已移除，因为帮助按钮已屏蔽
}
