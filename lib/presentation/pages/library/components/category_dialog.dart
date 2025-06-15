import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/library/library_management_provider.dart';

/// 分类对话框
class CategoryDialog extends ConsumerStatefulWidget {
  final String title;
  final String? initialName;
  final String? initialParentId;
  final String? editingCategoryId; // Added to track the category being edited
  final Function(String name, String? parentId) onConfirm;

  const CategoryDialog({
    super.key,
    required this.title,
    this.initialName,
    this.initialParentId,
    this.editingCategoryId,
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
    final allCategories = state.categories;

    // Find the category ID if we're editing an existing category
    String? editingCategoryId;
    if (widget.initialName != null) {
      // Find the category being edited
      for (var category in allCategories) {
        if (category.name == widget.initialName &&
            ((widget.initialParentId == null && category.parentId == null) ||
                (category.parentId == widget.initialParentId))) {
          editingCategoryId = category.id;
          break;
        }
      }
    }

    // Filter categories to prevent circular references
    final availableParentCategories = allCategories.where((category) {
      // Skip if this is the category we're editing
      if (editingCategoryId != null && category.id == editingCategoryId) {
        return false;
      }

      // Skip if this would create a circular reference
      if (editingCategoryId != null && category.parentId != null) {
        // Check if this category is a child of the one we're editing
        String? currentParentId = category.parentId;
        while (currentParentId != null) {
          if (currentParentId == editingCategoryId) {
            return false; // This would create a cycle
          } // Move up to the parent's parent
          final parentCategory = allCategories.firstWhere(
            (cat) => cat.id == currentParentId,
            orElse: () => LibraryCategory(
              id: '',
              name: '',
              parentId: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          currentParentId = parentCategory.parentId;
        }
      }

      return true;
    }).toList();

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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryName,
                hintText: AppLocalizations.of(context).enterCategoryName,
              ),
              autofocus: true,
            ),

            const SizedBox(height: 16), // 父分类选择
            DropdownButtonFormField<String?>(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).parentCategory,
                hintText: AppLocalizations.of(context).selectParentCategory,
              ),
              value: _selectedParentId,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(AppLocalizations.of(context).noTopLevelCategory),
                ),
                ...availableParentCategories
                    .map((category) => DropdownMenuItem<String>(
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
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)
                        .categoryNameCannotBeEmpty)),
              );
              return;
            }

            // 调用回调函数
            widget.onConfirm(name, _selectedParentId);
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).confirm),
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
