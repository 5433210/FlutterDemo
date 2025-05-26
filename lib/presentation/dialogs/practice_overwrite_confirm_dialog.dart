import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 字帖覆盖确认对话框
/// 当用户尝试保存的标题已存在时，用于确认是否覆盖
class PracticeOverwriteConfirmDialog extends StatelessWidget {
  /// 要覆盖的字帖标题
  final String title;

  const PracticeOverwriteConfirmDialog({
    super.key,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            Navigator.of(context).pop(true);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop(false);
          }
        }
      },
      child: AlertDialog(
        title: const Text('覆盖确认'),
        content: Text('已存在标题为"$title"的字帖，是否覆盖？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
  }
}
