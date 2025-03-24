import 'package:flutter/material.dart';

class DialogButtonGroup extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final String? confirmText;
  final bool isProcessing;

  const DialogButtonGroup({
    super.key,
    required this.onCancel,
    this.onConfirm,
    this.cancelText,
    this.confirmText,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isProcessing ? null : onCancel,
            child: Text(cancelText ?? '取消'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isProcessing || onConfirm == null ? null : onConfirm,
            child: isProcessing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(confirmText ?? '确定'),
          ),
        ],
      ),
    );
  }
}
