import 'package:flutter/material.dart';

class DialogButtonGroup extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String cancelText;
  final String confirmText;
  final bool isProcessing;
  final bool isConfirmEnabled;

  const DialogButtonGroup({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = '取消',
    this.confirmText = '确定',
    this.isProcessing = false,
    this.isConfirmEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isProcessing)
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        TextButton(
          onPressed: isProcessing ? null : onCancel,
          child: Text(cancelText),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: (isProcessing || !isConfirmEnabled) ? null : onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
