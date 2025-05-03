import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/enums/sort_field.dart';
import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/enums/work_tool.dart';
import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../widgets/filter/m3_filter_panel_base.dart';
import '../../../../widgets/filter/sections/m3_filter_date_range_section.dart';
import '../../../../widgets/filter/sections/m3_filter_sort_section.dart';
import '../../../../widgets/filter/sections/m3_filter_style_section.dart';
import '../../../../widgets/filter/sections/m3_filter_tags_section.dart';
import '../../../../widgets/filter/sections/m3_filter_tool_section.dart';

/// Material 3 版本的作品筛选面板
class M3WorkFilterPanel extends ConsumerWidget {
  /// 当前筛选条件
  final WorkFilter filter;

  /// 筛选条件变化时的回调
  final ValueChanged<WorkFilter> onFilterChanged;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _M3WorkFilterPanelImpl(
      filter: filter,
      onFilterChanged: onFilterChanged,
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
    );
  }
}

/// 作品筛选面板实现
class _M3WorkFilterPanelImpl extends M3FilterPanelBase<WorkFilter> {
  const _M3WorkFilterPanelImpl({
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
      SortField.author,
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
    final commonTags = <String>[];

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

      // 创建日期部分
      buildSectionCard(
        context,
        M3FilterDateRangeSection(
          title: l10n.filterDateSection,
          filter: DateRangeFilter(
            preset: filter.datePreset,
            start: filter.dateRange?.start,
            end: filter.dateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 重置所有相关字段
              final newFilter = filter.copyWith(
                datePreset: DateRangePreset.all,
                dateRange: null,
              );
              onFilterChanged(newFilter);
            } else {
              final newFilter = filter.copyWith(
                datePreset: dateFilter.preset!,
                dateRange: dateFilter.effectiveRange,
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
    return l10n.filterTitle;
  }

  @override
  void resetFilters() {
    onFilterChanged(const WorkFilter());
  }
}
