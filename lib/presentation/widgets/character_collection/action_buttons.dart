import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ActionButtons({
    Key? key,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 取消按钮
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('取消'),
        ),

        const SizedBox(width: 16),

        // 保存按钮
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
