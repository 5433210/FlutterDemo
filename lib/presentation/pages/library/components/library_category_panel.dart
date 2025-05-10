import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/library/library_management_provider.dart';
import '../../../viewmodels/states/library_management_state.dart'; // 添加这一行
import 'category_dialog.dart';
import 'library_drag_data.dart';

/// 图库分类面板
class LibraryCategoryPanel extends ConsumerStatefulWidget {
  const LibraryCategoryPanel({super.key});

  @override
  ConsumerState<LibraryCategoryPanel> createState() =>
      _LibraryCategoryPanelState();
}

class _LibraryCategoryPanelState extends ConsumerState<LibraryCategoryPanel> {
  String _searchQuery = '';
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);

    // 获取筛选后的分类列表
    final categories = _searchQuery.isEmpty
        ? state.categoryTree
        : notifier.searchCategories(_searchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 分类面板标题栏
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    l10n.categoryManagement,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l10n.addCategory,
                  onPressed: () => _showAddCategoryDialog(context, notifier),
                ),
              ],
            ),
          ),
        ),

        if (_isExpanded) ...[
          // 分类搜索框
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing8,
              vertical: AppSizes.spacing4,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchCategories,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacing8,
                  horizontal: AppSizes.p12,
                ),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 分类列表
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing8,
                      vertical: AppSizes.spacing4,
                    ),
                    children: [
                      // 全部分类选项
                      _buildAllCategoriesItem(context, state, notifier),

                      // 分类树列表
                      ...categories.map((category) => _buildCategoryItem(
                            context,
                            category,
                            state.selectedCategoryId,
                            notifier,
                            notifier.categoryItemCounts,
                            0,
                          )),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildAllCategoriesItem(
    BuildContext context,
    LibraryManagementState state,
    LibraryManagementNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return DragTarget<LibraryItemDragData>(
      onAcceptWithDetails: (data) {
        notifier.updateItemCategories(data.data.itemId, []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removedFromAllCategories),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onWillAcceptWithDetails: (data) => true,
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(l10n.allCategories),
            selected: state.selectedCategoryId == null,
            leading: const Icon(Icons.folder_outlined, size: 20),
            trailing: Text(
              '(${notifier.categoryItemCounts['total'] ?? state.totalCount})',
              style: theme.textTheme.bodySmall,
            ),
            onTap: () => notifier.selectCategory(null),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    LibraryCategory category,
    String? selectedCategoryId,
    LibraryManagementNotifier notifier,
    Map<String, int> itemCounts,
    int indentLevel,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasChildren = category.children.isNotEmpty;
    final count = itemCounts[category.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<LibraryItemDragData>(
          onAcceptWithDetails: (data) {
            notifier.addItemToCategory(data.data.itemId, category.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.addedToCategory} ${category.name}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onWillAcceptWithDetails: (data) => true,
          builder: (context, candidateData, rejectedData) {
            final isHighlighted = candidateData.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: isHighlighted
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(category.name),
                selected: selectedCategoryId == category.id,
                leading: Icon(
                  hasChildren ? Icons.folder : Icons.folder_outlined,
                  size: 20,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '($count)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.edit),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditCategoryDialog(context, notifier, category);
                        } else if (value == 'delete') {
                          _showDeleteCategoryDialog(
                              context, notifier, category);
                        }
                      },
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.only(
                  left: AppSizes.spacing16 + (indentLevel * AppSizes.spacing16),
                ),
                onTap: () => notifier.selectCategory(category.id),
              ),
            );
          },
        ),
        if (hasChildren)
          ...category.children.map((child) => _buildCategoryItem(
                context,
                child,
                selectedCategoryId,
                notifier,
                itemCounts,
                indentLevel + 1,
              )),
      ],
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, LibraryManagementNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: l10n.newCategory,
        onConfirm: (name, parentId) async {
          final category = LibraryCategory.create(
            name: name,
            parentId: parentId,
          );
          await notifier.addCategory(category);
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    LibraryManagementNotifier notifier,
    LibraryCategory category,
  ) {
    final l10n = AppLocalizations.of(context);
    final count = notifier.categoryItemCounts[category.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(
          count > 0
              ? '${l10n.categoryHasItems(count)} ${l10n.confirmDelete}'
              : '${l10n.confirmDeleteCategory} "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.deleteCategory(category.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    LibraryManagementNotifier notifier,
    LibraryCategory category,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: l10n.editCategory,
        initialName: category.name,
        initialParentId: category.parentId,
        onConfirm: (name, parentId) async {
          final updatedCategory = category.copyWith(
            name: name,
            parentId: parentId,
            updatedAt: DateTime.now(),
          );
          await notifier.updateCategory(updatedCategory);
        },
      ),
    );
  }
}
