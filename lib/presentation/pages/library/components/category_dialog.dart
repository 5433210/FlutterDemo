import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_category.dart';
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

  // Helper method to filter categories to prevent circular references
  List<LibraryCategory> _getAvailableParentCategories(
      List<LibraryCategory> allCategories) {
    if (widget.editingCategoryId == null) {
      // For new categories, we can choose any existing category as parent
      return allCategories;
    }

    // For existing categories, we need to filter out the category itself and its descendants
    return allCategories.where((category) {
      // Skip self
      if (category.id == widget.editingCategoryId) return false;

      // Skip descendants to prevent circular references
      return !_isCategoryDescendant(
          widget.editingCategoryId!, category.id, allCategories);
    }).toList();
  }

  // Helper method to check if a category is a descendant of another category
  bool _isCategoryDescendant(String categoryId, String potentialParentId,
      List<LibraryCategory> allCategories) {
    // If they're the same, it's a circular reference
    if (categoryId == potentialParentId)
      return true; // Get the potential parent category
    final parentCategory = allCategories.firstWhere(
      (cat) => cat.id == potentialParentId,
      orElse: () => LibraryCategory(
        id: '',
        name: '',
        parentId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Check if the parent's parent is the category (would create a cycle)
    if (parentCategory.parentId == categoryId) return true;

    // Recursively check the parent's parent
    return parentCategory.parentId == null
        ? false
        : _isCategoryDescendant(
            categoryId, parentCategory.parentId!, allCategories);
  }
}
