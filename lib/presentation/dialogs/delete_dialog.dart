import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';

class DeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final String deleteButtonLabel;
  final String cancelButtonLabel;
  final bool isLoading;

  const DeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.deleteButtonLabel = '删除',
    this.cancelButtonLabel = '取消',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (isLoading) ...[
            const SizedBox(height: AppSizes.m),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(deleteButtonLabel),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String deleteButtonLabel = '删除',
    String cancelButtonLabel = '取消',
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => DeleteDialog(
        title: title,
        message: message,
        deleteButtonLabel: deleteButtonLabel,
        cancelButtonLabel: cancelButtonLabel,
        isLoading: isLoading,
      ),
    );
  }
}
