import 'package:flutter/material.dart';

import '../../dialogs/practice_save_dialog.dart';
import 'practice_edit_controller.dart';

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
  static Future<void> saveAs(BuildContext context,
      List<Map<String, dynamic>> pages, List<Map<String, dynamic>> layers,
      [PracticeEditController? controller]) async {
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法保存：缺少控制器')),
      );
      return;
    }

    // 使用现有的保存对话框
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PracticeSaveDialog(
        initialTitle: controller.practiceTitle,
        isSaveAs: true,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (title == null || title.isEmpty) return;

    // 调用控制器的saveAsNewPractice方法
    final result = await controller.saveAsNewPractice(title);

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('字帖 "$title" 已保存')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败')),
      );
    }
  }

  /// 保存字帖
  static Future<void> savePractice(
      BuildContext context,
      List<Map<String, dynamic>> pages,
      List<Map<String, dynamic>> layers,
      String? practiceId,
      [PracticeEditController? controller]) async {
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法保存：缺少控制器')),
      );
      return;
    }

    // 如果已经有字帖ID和标题，直接保存
    if (controller.practiceTitle != null) {
      final result = await controller.savePractice();

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('字帖 "${controller.practiceTitle}" 已保存')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
      return;
    }

    // 如果没有标题，调用另存为
    await saveAs(context, pages, layers, controller);
    return;
  }
}
