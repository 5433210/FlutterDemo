import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Material 3 Delete confirmation dialog
/// Used to confirm user intent before deleting regions
class M3DeleteConfirmationDialog extends StatelessWidget {
  final int count;
  final bool isBatch;

  const M3DeleteConfirmationDialog({
    super.key,
    required this.count,
    this.isBatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    final title = isBatch 
        ? l10n.characterCollectionDeleteBatchConfirm(count)
        : l10n.characterCollectionDeleteConfirm;

    final content = isBatch 
        ? l10n.characterCollectionDeleteBatchMessage(count)
        : l10n.characterCollectionDeleteMessage;

    // Add keyboard shortcut support
    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            // Enter key confirms deletion
            Navigator.of(context).pop(true);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            // Esc key cancels
            Navigator.of(context).pop(false);
          }
        }
      },
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 12),
            // Keyboard shortcut hint
            Text(
              l10n.characterCollectionDeleteShortcuts,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog and return user choice
  /// Returns true if user confirms deletion, false if canceled
  static Future<bool> show(BuildContext context,
      {int count = 1, bool isBatch = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => M3DeleteConfirmationDialog(
        count: count,
        isBatch: isBatch,
      ),
    );

    return result ?? false;
  }
}
