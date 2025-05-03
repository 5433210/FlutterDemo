import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';

class SelectionToolbar extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool enabled;

  const SelectionToolbar({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
    required this.onDelete,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s, vertical: AppSizes.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: '${l10n.confirm} (Enter)',
              child: IconButton(
                icon: const Icon(Icons.check),
                onPressed: onConfirm,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
            Tooltip(
              message: '${l10n.delete} (Delete)',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
            Tooltip(
              message: '${l10n.cancel} (Esc)',
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
