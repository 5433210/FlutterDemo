import 'package:flutter/material.dart';

class WorkDeleteDialog extends StatelessWidget {
  final int count;
  
  const WorkDeleteDialog({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定要删除选中的 $count 个作品吗？'),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FilledButton(
          child: const Text('删除'),
          onPressed: () => Navigator.of(context).pop(true), 
        ),
      ],
    );
  }
}
