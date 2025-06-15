import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);
    final categories = state.categories;
    return AlertDialog(
      title: Text(l10n.setCategoryForItems(widget.selectedItemIds.length)),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Text(l10n.selectCategoryToApply),
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
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _applyCategories(notifier);
          },
          child: Text(l10n.apply),
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
