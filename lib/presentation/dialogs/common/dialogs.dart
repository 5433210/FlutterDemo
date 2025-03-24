import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? '取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText ?? '确定'),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText ?? '确定'),
        ),
      ],
    ),
  );
}
