import 'package:flutter/material.dart';

import '../../../application/commands/work_edit_commands.dart';
import '../../../theme/app_sizes.dart';

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

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '命令历史',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '当前位置: ${currentIndex + 1}/${commands.length}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              const Text('可撤销和重做的操作:'),
              const SizedBox(height: AppSizes.spacingSmall),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: commands.length,
                  itemBuilder: (context, index) {
                    final command = commands[index];
                    // 高亮当前位置
                    final isCurrentStep = index <= currentIndex;

                    return ListTile(
                      title: Text(command.description,
                          style: TextStyle(
                            fontWeight: isCurrentStep
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                          )),
                      leading: isCurrentStep
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : const Icon(Icons.radio_button_unchecked),
                    );
                  },
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text('关闭'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
