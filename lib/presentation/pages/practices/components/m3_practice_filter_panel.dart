import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/filter/m3_filter_panel_base.dart';

/// 字帖过滤面板
class M3PracticeFilterPanel extends StatelessWidget {
  /// 当前过滤条件
  final PracticeFilter filter;

  /// 过滤条件变化时的回调
  final ValueChanged<PracticeFilter> onFilterChanged;

  /// 搜索回调
  final ValueChanged<String> onSearch;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3PracticeFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearch,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return _M3PracticeFilterPanelImpl(
      filter: filter,
      onFilterChanged: onFilterChanged,
      onSearch: onSearch,
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
    );
  }
}

/// 字帖过滤面板实现
class _M3PracticeFilterPanelImpl extends M3FilterPanelBase<PracticeFilter> {
  /// 搜索回调
  final ValueChanged<String> onSearch;

  const _M3PracticeFilterPanelImpl({
    required super.filter,
    required super.onFilterChanged,
    required this.onSearch,
    super.collapsible = true,
    super.isExpanded = true,
    super.onToggleExpand,
  });

  @override
  List<Widget> buildFilterSections(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 定义可用的排序字段
    final sortFieldOptions = [
      {'value': 'updateTime', 'label': l10n.practiceListSortByUpdateTime},
      {'value': 'title', 'label': l10n.practiceListSortByTitle},
      {'value': 'createTime', 'label': l10n.practiceListSortByCreateTime},
    ];

    return [
      // 搜索部分
      buildSectionCard(
        context,
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.practiceListSearch,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: onSearch,
        ),
      ),

      // 排序部分
      buildSectionCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filterSortSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // 排序字段选择
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: filter.sortField,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: sortFieldOptions.map((field) {
                  return DropdownMenuItem<String>(
                    value: field['value'],
                    child: Text(
                      field['label']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final newFilter = filter.copyWith(sortField: value);
                    onFilterChanged(newFilter);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // 排序方向
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 升序
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: filter.sortOrder == 'desc',
                      onChanged: (value) {
                        if (value != null) {
                          final newFilter = filter.copyWith(
                            sortOrder: value ? 'desc' : 'asc',
                          );
                          onFilterChanged(newFilter);
                        }
                      },
                    ),
                    Flexible(
                      child: Text(
                        l10n.filterSortAscending,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // 降序
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: filter.sortOrder == 'desc',
                      onChanged: (value) {
                        if (value != null) {
                          final newFilter = filter.copyWith(
                            sortOrder: value ? 'desc' : 'asc',
                          );
                          onFilterChanged(newFilter);
                        }
                      },
                    ),
                    Flexible(
                      child: Text(
                        l10n.filterSortDescending,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // 收藏过滤部分
      buildSectionCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceListFilterFavorites,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // 收藏过滤选项
            Row(
              children: [
                Checkbox(
                  value: filter.isFavorite,
                  onChanged: (value) {
                    final newFilter =
                        filter.copyWith(isFavorite: value ?? false);
                    onFilterChanged(newFilter);
                  },
                ),
                Expanded(
                  child: Text(l10n.filterFavoritesOnly),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  @override
  String getFilterTitle(AppLocalizations l10n) {
    return l10n.practiceListFilterTitle;
  }

  @override
  void resetFilters() {
    onFilterChanged(const PracticeFilter());
    onSearch('');
  }

  Widget _buildStatusFilterChip(
      BuildContext context, String? status, String label) {
    final isSelected = filter.status == status;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        final newFilter = filter.copyWith(status: status);
        onFilterChanged(newFilter);
      },
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
    );
  }
}
