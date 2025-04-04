import 'package:flutter/material.dart';

Future<bool?> showSaveConfirmationDialog(
  BuildContext context, {
  required String character,
  Widget? previewWidget,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SaveConfirmationDialog(
      character: character,
      showPreview: previewWidget != null,
      previewWidget: previewWidget,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
}

class SaveConfirmationDialog extends StatelessWidget {
  final String character;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showPreview;
  final Widget? previewWidget;

  const SaveConfirmationDialog({
    super.key,
    required this.character,
    required this.onConfirm,
    required this.onCancel,
    this.showPreview = false,
    this.previewWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认保存'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确定要保存汉字"$character"吗？'),
          if (showPreview && previewWidget != null) ...[
            const SizedBox(height: 16),
            const Text('预览效果：'),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 200,
              child: previewWidget!,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
