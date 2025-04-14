import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 删除确认对话框
/// 用于在删除区域前确认用户意图
class DeleteConfirmationDialog extends StatelessWidget {
  final int count;
  final bool isBatch;

  const DeleteConfirmationDialog({
    Key? key,
    required this.count,
    this.isBatch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = isBatch ? '确认删除$count个已保存的选区？' : '确认删除已保存的选区？';

    final content =
        isBatch ? '即将删除$count个已保存的选区，此操作不可撤销。' : '即将删除当前选中的已保存选区，此操作不可撤销。';

    // 添加键盘快捷键支持
    return KeyboardListener(
      // 使用KeyboardListener捕获按键事件
      autofocus: true, // 确保对话框获得焦点
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            // Enter键确认删除
            Navigator.of(context).pop(true);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            // Esc键取消
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
            // 添加快捷键提示
            const Text(
              '快捷键: Enter确认删除, Esc取消',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示确认对话框并返回用户选择
  /// 返回true表示用户确认删除，false表示取消
  static Future<bool> show(BuildContext context,
      {int count = 1, bool isBatch = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        count: count,
        isBatch: isBatch,
      ),
    );

    return result ?? false;
  }
}
