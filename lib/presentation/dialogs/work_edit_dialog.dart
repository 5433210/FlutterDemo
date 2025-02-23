import 'package:flutter/material.dart';
import '../widgets/dialog_container.dart';
import '../../theme/app_sizes.dart';

class WorkEditDialog extends StatelessWidget {
  final String? workId;

  const WorkEditDialog({
    super.key,
    this.workId,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = workId != null;

    return DialogContainer(
      title: isEditing ? '编辑作品' : '添加作品',
      width: 500,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        const SizedBox(width: AppSizes.spacingMedium),
        FilledButton(
          onPressed: () {},
          child: Text(isEditing ? '保存' : '创建'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '作品名称',
            ),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '作者',
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '朝代',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
