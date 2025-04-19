import 'package:flutter/material.dart';

/// 文件操作工具类
class FileOperations {
  /// 导出字帖
  static Future<void> exportPractice(
    BuildContext context,
    List<Map<String, dynamic>> pages,
  ) async {
    final formats = ['PDF', 'PNG', 'JPG'];

    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出字帖'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择导出格式:'),
            const SizedBox(height: 16),
            ...formats.map(
              (format) => ListTile(
                title: Text(format),
                onTap: () => Navigator.pop(context, format),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (format == null) return;

    // 这里应该实现实际的导出逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出为$format格式 (功能待实现)')),
    );
  }

  /// 打印字帖
  static Future<void> printPractice(
    BuildContext context,
    List<Map<String, dynamic>> pages,
  ) async {
    // 这里应该实现实际的打印逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打印功能待实现')),
    );
  }

  /// 另存为
  static Future<void> saveAs(
    BuildContext context,
    List<Map<String, dynamic>> pages,
    List<Map<String, dynamic>> layers,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('另存为'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '字帖标题',
            hintText: '请输入字帖标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // Get the TextField directly from the content
              final textField = context
                  .findAncestorWidgetOfExactType<AlertDialog>()!
                  .content as TextField;
              Navigator.pop(context, textField.controller!.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    // 这里应该实现实际的保存逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('字帖 "$title" 已保存 (功能待实现)')),
    );
  }

  /// 保存字帖
  static Future<void> savePractice(
    BuildContext context,
    List<Map<String, dynamic>> pages,
    List<Map<String, dynamic>> layers,
    String? practiceId,
  ) async {
    if (practiceId == null) {
      // 如果没有ID，调用另存为
      await saveAs(context, pages, layers);
      return;
    }

    // 这里应该实现实际的保存逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('字帖已保存 (功能待实现)')),
    );
  }
}
