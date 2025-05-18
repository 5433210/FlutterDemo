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
  /// 是否使用固定高度
  final bool useFixedHeight;

  const LibraryCategoryPanel({
    super.key,
    this.useFixedHeight = false,
  });

  @override
  ConsumerState<LibraryCategoryPanel> createState() =>
      _LibraryCategoryPanelState();
}

class _LibraryCategoryPanelState extends ConsumerState<LibraryCategoryPanel> {
  String _searchQuery = '';
  bool _isExpanded = true;

  // Map to track expanded/collapsed state of each category
  final Map<String, bool> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);

    // 获取筛选后的分类列表
    final categories = _searchQuery.isEmpty
        ? state.categoryTree
        : notifier.searchCategories(
            _searchQuery); // Calculate the total height needed for categories
    const double categoryHeight = 48.0; // Approximate height of a category item
    const double headerHeight = 48.0; // Height of the header
    const double searchBarHeight = 64.0; // Height of the search bar
    int totalVisibleCategories = 0;

    // Count all visible categories
    if (_isExpanded) {
      totalVisibleCategories = 1; // Add 1 for "All Categories" item

      // Count visible categories based on expanded state
      for (final category in categories) {
        totalVisibleCategories++; // Add the main category

        // Count children if this category is expanded
        if (_expandedCategories[category.id] == true &&
            category.children.isNotEmpty) {
          totalVisibleCategories += _countVisibleChildren(category);
        }
      }
    } // Calculate panel height = header + search bar + categories
    final double totalHeight = _isExpanded
        ? headerHeight +
            searchBarHeight +
            (totalVisibleCategories * categoryHeight)
        : headerHeight; // Just the header when collapsed

    Widget content = Column(
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

          // 分类列表 - changed from Expanded to non-scrollable column for auto-height
          Column(
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
        ],
      ],
    );

    // 如果使用固定高度，则使用SizedBox包装内容
    return widget.useFixedHeight
        ? SizedBox(height: totalHeight, child: content)
        : content;
  }

  // 构建"全部分类"选项
  Widget _buildAllCategoriesItem(
    BuildContext context,
    LibraryManagementState state,
    LibraryManagementNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = notifier.categoryItemCounts['all'] ?? 0;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(l10n.allCategories),
      selected: state.selectedCategoryId == null,
      leading: const Icon(
        Icons.photo_library,
        size: 20,
      ),
      trailing: Text(
        '($count)',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => notifier.selectCategory(null),
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

    // Initialize expanded state if not set yet
    if (!_expandedCategories.containsKey(category.id)) {
      _expandedCategories[category.id] = false; // Default to collapsed
    }
    final isExpanded = _expandedCategories[category.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<LibraryItemDragData>(
          onAcceptWithDetails: (data) {
            // 检查是否有批量选择的项目
            final state = ref.read(libraryManagementProvider);
            if (state.isBatchMode && state.selectedItems.isNotEmpty) {
              // 批量处理选中的项目
              for (final itemId in state.selectedItems) {
                notifier.addItemToCategory(itemId, category.id);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '已将${state.selectedItems.length}个项目添加到"${category.name}"分类'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              // 处理单个拖拽项目
              notifier.addItemToCategory(data.data.itemId, category.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.addedToCategory} ${category.name}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
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
                leading: InkWell(
                  // Make folder icon clickable to expand/collapse
                  onTap: hasChildren
                      ? () {
                          setState(() {
                            _expandedCategories[category.id] = !isExpanded;
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Icon(
                    hasChildren
                        ? (isExpanded ? Icons.folder_open : Icons.folder)
                        : Icons.folder_outlined,
                    size: 20,
                  ), // Better tap target
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
        // Only display children if this category is expanded
        if (hasChildren && isExpanded)
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

  // Helper method to count visible children recursively
  int _countVisibleChildren(LibraryCategory category) {
    int count = 0;
    for (final child in category.children) {
      count++; // Count the child itself
      // If child is expanded and has children, recursively count them
      if (_expandedCategories[child.id] == true && child.children.isNotEmpty) {
        count += _countVisibleChildren(child);
      }
    }
    return count;
  }

  // 显示添加分类对话框
  void _showAddCategoryDialog(
      BuildContext context, LibraryManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: AppLocalizations.of(context).addCategory,
        onConfirm: (name, parentId) async {
          // 创建新分类
          final newCategory = LibraryCategory.create(
            name: name,
            parentId: parentId,
          );
          await notifier.addCategory(newCategory);
        },
      ),
    );
  }

  // 显示删除分类对话框
  void _showDeleteCategoryDialog(BuildContext context,
      LibraryManagementNotifier notifier, LibraryCategory category) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text('${l10n.confirmDeleteCategory} "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.deleteCategory(category.id);
            },
            child: Text(l10n.deleteCategoryOnly),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.deleteCategoryWithFiles(category.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteCategoryWithFiles),
          ),
        ],
      ),
    );
  }

  // 显示编辑分类对话框
  void _showEditCategoryDialog(BuildContext context,
      LibraryManagementNotifier notifier, LibraryCategory category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: AppLocalizations.of(context).edit,
        initialName: category.name,
        initialParentId: category.parentId,
        editingCategoryId: category.id, // Add this line
        onConfirm: (name, parentId) async {
          // 更新分类
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
