import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../providers/library/library_management_provider.dart';
import 'category_dialog.dart';
import 'library_drag_data.dart';

/// 图库分类面板
class LibraryCategoryPanel extends ConsumerWidget {
  const LibraryCategoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);
    final categoryTree = state.categoryTree;

    // 获取选中的分类ID列表（当前仅支持单选，后续可扩展为多选）
    final selectedCategoryId = state.selectedCategoryId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题和添加分类按钮
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '分类管理',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '添加分类',
                onPressed: () => _showAddCategoryDialog(context, notifier),
              ),
            ],
          ),
        ),

        // 分类搜索框（简单实现，不支持过滤）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '搜索分类...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            ),
            onChanged: (value) {
              // 简单实现，实际应用可添加过滤逻辑
            },
          ),
        ),

        const SizedBox(height: 8),

        // 展开/折叠所有按钮（简化版不实现）

        // 分类列表
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  children: [
                    // 全部分类的选项
                    DragTarget<LibraryItemDragData>(
                      onAcceptWithDetails: (data) {
                        // 从所有分类中移除图片
                        final itemId = data.data.itemId;
                        notifier.updateItemCategories(itemId, []);

                        // 显示成功反馈
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已从所有分类中移除图片'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      onWillAcceptWithDetails: (data) => data != null,
                      builder: (context, candidateData, rejectedData) {
                        // 当有候选数据时显示高亮效果
                        final isHighlighted = candidateData.isNotEmpty;

                        return Container(
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: ListTile(
                            title: const Text('全部'),
                            selected: selectedCategoryId == null,
                            leading: const Icon(Icons.folder),
                            trailing: Text(
                                '(${notifier.categoryItemCounts['total'] ?? state.totalCount})'),
                            onTap: () => notifier.selectCategory(null),
                          ),
                        );
                      },
                    ),

                    // 分类树列表
                    ...categoryTree.map((category) => _buildCategoryItem(
                          context,
                          category,
                          selectedCategoryId,
                          notifier,
                          notifier.categoryItemCounts,
                          0, // 初始缩进级别
                        )),
                  ],
                ),
        ),
      ],
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem(
    BuildContext context,
    LibraryCategory category,
    String? selectedCategoryId,
    LibraryManagementNotifier notifier,
    Map<String, int> itemCounts,
    int indentLevel,
  ) {
    // 子分类的数量
    final hasChildren = category.children.isNotEmpty;

    // 当前分类的计数
    final count = itemCounts[category.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前分类项
        DragTarget<LibraryItemDragData>(
          onAcceptWithDetails: (data) {
            // 当图片被拖放到此分类时触发
            print(
                'Item ${data.data.itemId} dropped onto category ${category.id}');
            notifier.addItemToCategory(data.data.itemId, category.id);

            // 显示成功反馈
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已将图片添加到分类: ${category.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onWillAcceptWithDetails: (data) => data != null,
          builder: (context, candidateData, rejectedData) {
            // 当有候选数据时显示高亮效果
            final isHighlighted = candidateData.isNotEmpty;

            return Container(
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: ListTile(
                title: Text(category.name),
                selected: selectedCategoryId == category.id,
                leading:
                    Icon(hasChildren ? Icons.folder : Icons.folder_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 显示项目数量
                    Text('($count)'),
                    const SizedBox(width: 8),
                    // 操作按钮
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('编辑'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除'),
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
                contentPadding:
                    EdgeInsets.only(left: 16.0 + (indentLevel * 16.0)),
                onTap: () => notifier.selectCategory(category.id),
              ),
            );
          },
        ),

        // 递归构建子分类
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

  /// 显示添加分类对话框
  void _showAddCategoryDialog(
      BuildContext context, LibraryManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: '新建分类',
        onConfirm: (name, parentId) async {
          // 创建新分类
          final category = LibraryCategory.create(
            name: name,
            parentId: parentId,
          );

          // 添加分类并重新加载
          await notifier.addCategory(category);
        },
      ),
    );
  }

  /// 显示删除分类确认对话框
  void _showDeleteCategoryDialog(
    BuildContext context,
    LibraryManagementNotifier notifier,
    LibraryCategory category,
  ) {
    final count = notifier.categoryItemCounts[category.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(
          count > 0
              ? '该分类下有 $count 个项目，删除分类后，这些项目将不再属于此分类。确定要删除吗？'
              : '确定要删除"${category.name}"分类吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.deleteCategory(category.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑分类对话框
  void _showEditCategoryDialog(
    BuildContext context,
    LibraryManagementNotifier notifier,
    LibraryCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: '编辑分类',
        initialName: category.name,
        initialParentId: category.parentId,
        onConfirm: (name, parentId) async {
          // 更新分类
          final updatedCategory = category.copyWith(
            name: name,
            parentId: parentId,
            updatedAt: DateTime.now(),
          );

          // 保存并重新加载
          await notifier.updateCategory(updatedCategory);
        },
      ),
    );
  }
}
