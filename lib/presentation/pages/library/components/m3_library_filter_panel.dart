import 'package:flutter/material.dart';

import '../../../../domain/entities/library_category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/section_header.dart';

/// 图库过滤面板
class M3LibraryFilterPanel extends StatelessWidget {
  /// 分类列表
  final List<LibraryCategory> categories;

  /// 当前选中的分类ID
  final String? selectedCategoryId;

  /// 分类选择回调
  final void Function(String?) onCategorySelected;

  /// 排序变更回调
  final void Function(String, bool) onSortChanged;

  /// 构造函数
  const M3LibraryFilterPanel({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类列表
          SectionHeader(
            title: l10n.libraryManagementCategories,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryItem(context, category);
              },
            ),
          ),

          const Divider(),

          // 排序选项
          SectionHeader(
            title: l10n.libraryManagementSortBy,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSizes.spacing8),
          _buildSortOption(
            context,
            l10n.libraryManagementSortByName,
            'name',
          ),
          _buildSortOption(
            context,
            l10n.libraryManagementSortByDate,
            'createdAt',
          ),
          _buildSortOption(
            context,
            l10n.libraryManagementSortBySize,
            'size',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, LibraryCategory category) {
    final theme = Theme.of(context);
    final isSelected = category.id == selectedCategoryId;

    return ListTile(
      title: Text(category.name),
      selected: isSelected,
      leading: Icon(
        Icons.folder_outlined,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => onCategorySelected(
        isSelected ? null : category.id,
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String sortBy,
  ) {
    final theme = Theme.of(context);
    final isSelected = sortBy == 'name'; // TODO: 从状态中获取当前排序字段

    return ListTile(
      title: Text(label),
      selected: isSelected,
      trailing: Icon(
        isSelected
            ? (true
                ? Icons.arrow_upward
                : Icons.arrow_downward) // TODO: 从状态中获取排序方向
            : null,
        color: theme.colorScheme.primary,
      ),
      onTap: () => onSortChanged(
        sortBy,
        isSelected ? !true : false, // TODO: 从状态中获取排序方向
      ),
    );
  }
}
