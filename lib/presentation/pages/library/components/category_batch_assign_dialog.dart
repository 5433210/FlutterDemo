import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/library/library_management_provider.dart';

/// 批量分类对话框
class CategoryBatchAssignDialog extends ConsumerStatefulWidget {
  final List<String> selectedItemIds;

  const CategoryBatchAssignDialog({
    super.key,
    required this.selectedItemIds,
  });

  @override
  ConsumerState<CategoryBatchAssignDialog> createState() =>
      _CategoryBatchAssignDialogState();
}

class _CategoryBatchAssignDialogState
    extends ConsumerState<CategoryBatchAssignDialog> {
  final Set<String> _selectedCategoryIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);
    final categories = state.categories;

    return AlertDialog(
      title: Text('设置分类 (${widget.selectedItemIds.length}个项目)'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            const Text('请选择要应用的分类:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CheckboxListTile(
                    title: Text(category.name),
                    subtitle: Text(
                        '(${notifier.categoryItemCounts[category.id] ?? 0})'),
                    value: _selectedCategoryIds.contains(category.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCategoryIds.add(category.id);
                        } else {
                          _selectedCategoryIds.remove(category.id);
                        }
                      });
                    },
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
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _applyCategories(notifier);
          },
          child: const Text('应用'),
        ),
      ],
    );
  }

  /// 应用所选分类到选中的项目
  Future<void> _applyCategories(LibraryManagementNotifier notifier) async {
    if (_selectedCategoryIds.isNotEmpty) {
      for (final categoryId in _selectedCategoryIds) {
        await notifier.addCategoryToItems(categoryId, widget.selectedItemIds);
      }
    }
  }
}
