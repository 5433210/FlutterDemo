import 'package:flutter/material.dart';

/// 确认覆盖对话框
class ConfirmOverwriteDialog extends StatelessWidget {
  final String title;

  const ConfirmOverwriteDialog({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('标题已存在'),
      content: Text('已经存在名为"$title"的字帖，是否覆盖？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('覆盖'),
        ),
      ],
    );
  }

  /// 显示确认覆盖对话框
  static Future<bool> show(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmOverwriteDialog(title: title),
    );
    return result ?? false;
  }
}
