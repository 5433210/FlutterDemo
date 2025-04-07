import 'package:flutter/material.dart';

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
    final title = isBatch ? '确认删除${count}个已保存的选区？' : '确认删除已保存的选区？';

    final content =
        isBatch ? '即将删除${count}个已保存的选区，此操作不可撤销。' : '即将删除当前选中的已保存选区，此操作不可撤销。';

    return AlertDialog(
      title: Text(title),
      content: Text(content),
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
