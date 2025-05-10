import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/library/library_management_provider.dart';

/// 分类对话框
class CategoryDialog extends ConsumerStatefulWidget {
  final String title;
  final String? initialName;
  final String? initialParentId;
  final Function(String name, String? parentId) onConfirm;

  const CategoryDialog({
    super.key,
    required this.title,
    this.initialName,
    this.initialParentId,
    required this.onConfirm,
  });

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late TextEditingController _nameController;
  String? _selectedParentId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryManagementProvider);
    final categories = state.categories;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 分类名称输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
              ),
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // 父分类选择
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: '父分类（可选）',
                hintText: '选择父分类',
              ),
              value: _selectedParentId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('无（顶级分类）'),
                ),
                ...categories.map((category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParentId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分类名称不能为空')),
              );
              return;
            }

            // 调用回调函数
            widget.onConfirm(name, _selectedParentId);
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedParentId = widget.initialParentId;
  }
}
