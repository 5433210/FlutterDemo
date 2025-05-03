import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../domain/enums/work_style.dart';
import '../../../../domain/enums/work_tool.dart';
import '../../../../domain/models/character/character_filter.dart';
import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/character/character_filter_provider.dart';
import '../../../widgets/filter/m3_filter_panel_base.dart';
import '../../../widgets/filter/sections/m3_filter_date_range_section.dart';
import '../../../widgets/filter/sections/m3_filter_favorite_section.dart';
import '../../../widgets/filter/sections/m3_filter_sort_section.dart';
import '../../../widgets/filter/sections/m3_filter_style_section.dart';
import '../../../widgets/filter/sections/m3_filter_tags_section.dart';
import '../../../widgets/filter/sections/m3_filter_tool_section.dart';

/// Material 3 版本的字符筛选面板
class M3CharacterFilterPanel extends ConsumerWidget {
  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3CharacterFilterPanel({
    super.key,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterNotifier = ref.watch(characterFilterProvider.notifier);
    final filter = ref.watch(characterFilterProvider);

    return _M3CharacterFilterPanelImpl(
      filter: filter,
      onFilterChanged: (newFilter) {
        // 使用 provider 更新筛选条件
        if (newFilter.sortOption != filter.sortOption) {
          filterNotifier.setSortField(newFilter.sortOption.field);
          filterNotifier.setSortDirection(newFilter.sortOption.descending);
        }

        if (newFilter.style != filter.style) {
          filterNotifier.updateCalligraphyStyles(newFilter.style);
        }

        if (newFilter.tool != filter.tool) {
          filterNotifier.updateWritingTools(newFilter.tool);
        }

        if (newFilter.isFavorite != filter.isFavorite) {
          filterNotifier.updateFavoriteFilter(newFilter.isFavorite ?? false);
        }

        if (newFilter.creationDatePreset != filter.creationDatePreset ||
            newFilter.creationDateRange != filter.creationDateRange) {
          filterNotifier.updateCreationDatePreset(newFilter.creationDatePreset);
          filterNotifier.updateCreationDateRange(newFilter.creationDateRange);
        }

        if (newFilter.collectionDatePreset != filter.collectionDatePreset ||
            newFilter.collectionDateRange != filter.collectionDateRange) {
          filterNotifier
              .updateCollectionDatePreset(newFilter.collectionDatePreset);
          filterNotifier
              .updateCollectionDateRange(newFilter.collectionDateRange);
        }

        if (newFilter.tags != filter.tags) {
          filterNotifier.updateTags(newFilter.tags);
        }
      },
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
    );
  }
}

/// 字符筛选面板实现
class _M3CharacterFilterPanelImpl extends M3FilterPanelBase<CharacterFilter> {
  const _M3CharacterFilterPanelImpl({
    required super.filter,
    required super.onFilterChanged,
    super.collapsible = true,
    super.isExpanded = true,
    super.onToggleExpand,
  });

  @override
  List<Widget> buildFilterSections(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 获取可用的排序字段
    final sortFields = [
      SortField.title,
      SortField.createTime,
      SortField.updateTime,
      SortField.style,
      SortField.tool,
    ];

    // 获取可用的书法风格
    final styles = WorkStyle.values.toList();

    // 获取可用的书写工具
    final tools = WorkTool.values.toList();

    // 常用标签
    final List<String> commonTags = [];

    return [
      // 排序部分
      buildSectionCard(
        context,
        M3FilterSortSection(
          sortField: filter.sortOption.field,
          descending: filter.sortOption.descending,
          availableSortFields: sortFields,
          onSortFieldChanged: (field) {
            final newFilter = filter.copyWith(
              sortOption: filter.sortOption.copyWith(field: field),
            );
            onFilterChanged(newFilter);
          },
          onSortDirectionChanged: (isDescending) {
            final newFilter = filter.copyWith(
              sortOption: filter.sortOption.copyWith(descending: isDescending),
            );
            onFilterChanged(newFilter);
          },
        ),
      ),

      // 收藏部分
      buildSectionCard(
        context,
        M3FilterFavoriteSection(
          isFavoriteOnly: filter.isFavorite,
          onFavoriteChanged: (value) {
            final newFilter = filter.copyWith(isFavorite: value);
            onFilterChanged(newFilter);
          },
        ),
      ),

      // 书写工具部分
      buildSectionCard(
        context,
        M3FilterToolSection(
          selectedTool: filter.tool,
          availableTools: tools,
          onToolChanged: (tool) {
            final newFilter = filter.copyWith(tool: tool);
            onFilterChanged(newFilter);
          },
        ),
      ),

      // 书法风格部分
      buildSectionCard(
        context,
        M3FilterStyleSection(
          selectedStyle: filter.style,
          availableStyles: styles,
          onStyleChanged: (style) {
            final newFilter = filter.copyWith(style: style);
            onFilterChanged(newFilter);
          },
        ),
      ),

      // 创建日期部分
      buildSectionCard(
        context,
        M3FilterDateRangeSection(
          title: l10n.characterFilterCreationDate,
          filter: DateRangeFilter(
            preset: filter.creationDatePreset,
            start: filter.creationDateRange?.start,
            end: filter.creationDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 重置所有相关字段
              final newFilter = filter.copyWith(
                creationDatePreset: DateRangePreset.all,
                creationDateRange: null,
              );
              onFilterChanged(newFilter);
            } else {
              final newFilter = filter.copyWith(
                creationDatePreset: dateFilter.preset!,
                creationDateRange: dateFilter.effectiveRange,
              );
              onFilterChanged(newFilter);
            }
          },
        ),
      ),

      // 收集日期部分
      buildSectionCard(
        context,
        M3FilterDateRangeSection(
          title: l10n.characterFilterCollectionDate,
          filter: DateRangeFilter(
            preset: filter.collectionDatePreset,
            start: filter.collectionDateRange?.start,
            end: filter.collectionDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 重置所有相关字段
              final newFilter = filter.copyWith(
                collectionDatePreset: DateRangePreset.all,
                collectionDateRange: null,
              );
              onFilterChanged(newFilter);
            } else {
              final newFilter = filter.copyWith(
                collectionDatePreset: dateFilter.preset!,
                collectionDateRange: dateFilter.effectiveRange,
              );
              onFilterChanged(newFilter);
            }
          },
        ),
      ),

      // 标签部分
      buildSectionCard(
        context,
        M3FilterTagsSection(
          selectedTags: filter.tags,
          commonTags: commonTags,
          onTagsChanged: (tags) {
            final newFilter = filter.copyWith(tags: tags);
            onFilterChanged(newFilter);
          },
        ),
      ),
    ];
  }

  @override
  String getFilterTitle(AppLocalizations l10n) {
    return l10n.characterFilterTitle;
  }

  @override
  void resetFilters() {
    onFilterChanged(const CharacterFilter());
  }
}
