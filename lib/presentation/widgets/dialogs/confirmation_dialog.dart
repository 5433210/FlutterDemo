import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback? onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.isDestructive = false,
    this.onConfirm,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (onConfirm != null) onConfirm!();
            Navigator.of(context).pop(true);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop(false);
          }
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              if (onConfirm != null) onConfirm!();
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              foregroundColor: isDestructive
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onPrimary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
