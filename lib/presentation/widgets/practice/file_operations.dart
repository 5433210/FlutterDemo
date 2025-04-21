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
      // 确保将当前的页面内容传递给保存方法
      final result =
          await controller.savePractice(title: controller.practiceTitle);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('字帖 "${controller.practiceTitle}" 已保存')),
        );
      } else {
        // 如果保存失败，可能是因为检查到同名字帖，询问是否覆盖
        final shouldOverwrite =
            await _confirmOverwrite(context, controller.practiceTitle!);
        if (shouldOverwrite) {
          final overwriteResult =
              await controller.saveOverwriteExisting(controller.practiceTitle!);
          if (overwriteResult) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('字帖 "${controller.practiceTitle}" 已覆盖保存')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('保存失败')),
            );
          }
        }
      }
      return;
    }

    // 如果没有标题，显示保存对话框让用户输入标题
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PracticeSaveDialog(
        initialTitle: '',
        isSaveAs: false,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (title == null || title.isEmpty) return;

    // 调用控制器的savePractice方法（会自动处理新字帖）
    final result = await controller.savePractice(title: title);

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('字帖 "$title" 已保存')),
      );
    } else {
      // 如果保存失败，可能是因为检查到同名字帖，询问是否覆盖
      final shouldOverwrite = await _confirmOverwrite(context, title);
      if (shouldOverwrite) {
        final overwriteResult = await controller.saveOverwriteExisting(title);
        if (overwriteResult) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('字帖 "$title" 已覆盖保存')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败')),
          );
        }
      }
    }
  }

  /// 确认是否覆盖现有字帖
  static Future<bool> _confirmOverwrite(
      BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认覆盖'),
        content: Text('已存在名为"$title"的字帖，是否覆盖？'),
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

    return result ?? false;
  }
}
