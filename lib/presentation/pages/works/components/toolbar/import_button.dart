import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/work_browse_provider.dart';
import '../../../../dialogs/work_import/work_import_dialog.dart';
import '../../../../viewmodels/work_browse_view_model.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);

    return FilledButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('导入作品'),
      onPressed: () => _showImportDialog(context, viewModel),
    );
  }

  Future<void> _showImportDialog(
      BuildContext context, WorkBrowseViewModel viewModel) async {
    try {
      // 显示导入对话框
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WorkImportDialog(),
      );

      if (result == true) {
        // 显示加载指示器
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在刷新作品列表...')),
          );
        }

        // 刷新列表
        await viewModel.loadWorks();

        // 显示成功提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('作品导入成功')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
    }
  }
}
