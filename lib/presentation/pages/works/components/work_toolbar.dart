import 'package:demo/domain/models/work/work_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';

class WorkToolbar extends ConsumerWidget {
  final WorkEntity work;

  const WorkToolbar({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 导出按钮
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: '导出作品',
          onPressed: () => _exportWork(context),
        ),

        // 编辑按钮
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '编辑作品',
          onPressed: () => _editWork(context),
        ),

        // 其他操作按钮
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: '更多操作',
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'extract',
              child: Row(
                children: [
                  Icon(Icons.text_format, size: 20),
                  SizedBox(width: 8),
                  Text('提取字形'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('分享作品'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('删除作品', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '删除作品',
        message: '确定要删除作品《${work.title}》吗？此操作不可撤销。',
        confirmText: '删除',
        cancelText: '取消',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      // 执行删除操作
      try {
        await _deleteWork(context);
      } catch (e) {
        AppLogger.error('删除作品失败',
            tag: 'WorkToolbar', error: e, data: {'workId': work.id});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除作品失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteWork(BuildContext context) async {
    // 这里应该调用实际的删除逻辑
    // await ref.read(workServiceProvider).deleteWork(work.id!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('删除功能尚未实现')),
    );
  }

  Future<void> _editWork(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('编辑功能尚未实现')),
      );
    } catch (e) {
      AppLogger.error('编辑作品失败',
          tag: 'WorkToolbar', error: e, data: {'workId': work.id});
    }
  }

  Future<void> _exportWork(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出功能尚未实现')),
      );
    } catch (e) {
      AppLogger.error('导出作品失败',
          tag: 'WorkToolbar', error: e, data: {'workId': work.id});
    }
  }

  Future<void> _extractCharacters(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提取字形功能尚未实现')),
    );
  }

  Future<void> _handleMenuSelection(BuildContext context, String value) async {
    switch (value) {
      case 'extract':
        _extractCharacters(context);
        break;
      case 'share':
        _shareWork(context);
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  Future<void> _shareWork(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能尚未实现')),
    );
  }
}
