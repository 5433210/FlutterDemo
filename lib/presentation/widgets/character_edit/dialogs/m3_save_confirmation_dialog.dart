import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

Future<bool?> showM3SaveConfirmationDialog(
  BuildContext context, {
  required String character,
  Widget? previewWidget,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    useRootNavigator: false, // Use nearest navigator for better performance
    builder: (context) => M3SaveConfirmationDialog(
      character: character,
      showPreview: previewWidget != null,
      previewWidget: previewWidget,
      onConfirm: () async {
        // Close dialog immediately
        Navigator.of(context).pop(true);
      },
      onCancel: () {
        Navigator.of(context).pop(false);
      },
    ),
  );
}

class M3SaveConfirmationDialog extends StatefulWidget {
  final String character;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showPreview;
  final Widget? previewWidget;

  const M3SaveConfirmationDialog({
    super.key,
    required this.character,
    required this.onConfirm,
    required this.onCancel,
    this.showPreview = false,
    this.previewWidget,
  });

  @override
  State<M3SaveConfirmationDialog> createState() =>
      _M3SaveConfirmationDialogState();
}

class _M3SaveConfirmationDialogState extends State<M3SaveConfirmationDialog> {
  // Create a dedicated FocusNode
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return KeyboardListener(
      focusNode: _dialogFocusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onConfirm();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onCancel();
          }
        }
      },
      child: AlertDialog(
        title: Text(l10n.save),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.characterEditSaveConfirmMessage(widget.character)),
            const SizedBox(height: 8),
            Text(
              l10n.confirmShortcuts,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (widget.showPreview && widget.previewWidget != null) ...[
              const SizedBox(height: 16),
              Text(l10n.savePreview),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                height: 200,
                child: widget.previewWidget!,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel,
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: widget.onConfirm,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Release resources
    _dialogFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Force focus to dialog after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }
}
