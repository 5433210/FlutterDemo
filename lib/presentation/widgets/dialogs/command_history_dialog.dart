import 'package:flutter/material.dart';

import '../../../application/commands/work_edit_commands.dart';
import '../../../theme/app_sizes.dart';

/// 用于显示编辑命令历史的对话框
class CommandHistoryDialog extends StatelessWidget {
  final List<WorkEditCommand> commands;
  final int currentIndex;

  const CommandHistoryDialog({
    super.key,
    required this.commands,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('编辑历史'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前位置: ${currentIndex + 1}/${commands.length}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            const Text('可撤销和重做的操作:'),
            const SizedBox(height: AppSizes.spacingSmall),
            Expanded(
              child: ListView.builder(
                itemCount: commands.length,
                itemBuilder: (context, index) {
                  final command = commands[index];
                  // 判断是否是当前位置
                  final isCurrent = index == currentIndex;

                  return ListTile(
                    dense: true,
                    title: Text(command.description),
                    leading: isCurrent
                        ? const Icon(Icons.arrow_right)
                        : const SizedBox(width: 24),
                    tileColor: isCurrent
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                    textColor: index <= currentIndex
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    subtitle: index <= currentIndex
                        ? const Text('已执行')
                        : const Text('可重做'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
