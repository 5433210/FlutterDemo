import 'package:demo/domain/enums/work_style.dart';
import 'package:demo/domain/enums/work_tool.dart';
import 'package:demo/presentation/pages/works/components/filter/sort_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../domain/models/character/character_filter.dart';
import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/character/character_filter_provider.dart';
import '../../works/components/filter/date_range_filter_section.dart';

/// 字符筛选面板
class CharacterFilterPanel extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final ValueChanged<bool>? onExpandedChanged;

  const CharacterFilterPanel({
    super.key,
    this.isExpanded = true,
    this.onToggleExpand,
    this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterNotifier = ref.watch(characterFilterProvider.notifier);
    final filter = ref.watch(characterFilterProvider);

    if (!isExpanded) {
      return _buildCollapsedPanel(context, onToggleExpand);
    }

    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, onToggleExpand),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 排序选项
                  _buildSortSection(context, filter, filterNotifier),
                  const Divider(),

                  // 收藏过滤
                  _buildFavoriteSection(context, filter, filterNotifier),
                  const Divider(),

                  // 书写工具过滤
                  _buildWritingToolSection(context, filter, filterNotifier),
                  const Divider(),

                  // 书法风格过滤
                  _buildCalligraphyStyleSection(
                      context, filter, filterNotifier),
                  const Divider(),

                  // 创作时间过滤
                  _buildCreationDateSection(context, filter, filterNotifier),
                  const Divider(),

                  // 收集时间过滤
                  _buildCollectionDateSection(context, filter, filterNotifier),
                  const Divider(),

                  // 标签过滤
                  _buildTagsSection(context, filter, filterNotifier),
                ],
              ),
            ),
          ),

          const Divider(),

          // 重置按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => filterNotifier.resetFilters(),
              child: const Text('重置筛选'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalligraphyStyleSection(BuildContext context,
      CharacterFilter filter, CharacterFilterNotifier notifier) {
    // 这里应该从数据库或配置获取可用的书法风格列表
    final styles = WorkStyle.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '书法风格',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: styles.map((style) {
            final isSelected = filter.style == style;
            return FilterChip(
              label: Text(style.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.updateCalligraphyStyles(style);
                } else {
                  notifier.updateCalligraphyStyles(null);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCollapsedPanel(
      BuildContext context, VoidCallback? onToggleExpand) {
    return GestureDetector(
      onTap: onToggleExpand,
      child: Container(
        width: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '筛选选项',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionDateSection(BuildContext context,
      CharacterFilter filter, CharacterFilterNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '收集时间',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: filter.collectionDatePreset,
            start: filter.collectionDateRange?.start,
            end: filter.collectionDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 如果日期筛选被清除，重置所有相关字段
              notifier.updateCollectionDateRange(null);
              notifier.updateCollectionDatePreset(DateRangePreset.all);
            } else {
              notifier.updateCollectionDatePreset(
                  dateFilter.preset ?? DateRangePreset.all);
              notifier.updateCollectionDateRange(dateFilter.effectiveRange);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCreationDateSection(BuildContext context, CharacterFilter filter,
      CharacterFilterNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '作品创作时间',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: filter.creationDatePreset,
            start: filter.creationDateRange?.start,
            end: filter.creationDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 如果日期筛选被清除，重置所有相关字段
              notifier.updateCreationDateRange(null);
              notifier.updateCreationDatePreset(DateRangePreset.all);
            } else {
              notifier.updateCreationDatePreset(
                  dateFilter.preset ?? DateRangePreset.all);
              notifier.updateCreationDateRange(dateFilter.effectiveRange);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteSection(BuildContext context, CharacterFilter filter,
      CharacterFilterNotifier notifier) {
    return Row(
      children: [
        Checkbox(
          value: filter.isFavorite ?? false,
          onChanged: (value) => notifier.updateFavoriteFilter(value ?? false),
        ),
        const SizedBox(width: 8),
        const Text('仅显示收藏'),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, VoidCallback? onToggleExpand) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '筛选选项',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onToggleExpand,
          icon: const Icon(Icons.chevron_left),
          tooltip: '收起筛选面板',
        ),
      ],
    );
  }

  Widget _buildSortItem(SortField field, String label, ThemeData theme,
      CharacterFilter filter, CharacterFilterNotifier notifier) {
    final bool selected = filter.sortOption.field == field;

    return Material(
      color:
          selected ? theme.colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.s),
        onTap: () {
          // 如果点击当前选中的项，重置为默认排序
          if (selected) {
            notifier.updateSortOption(SortSection.defaultSortOption);
          } else {
            // 选择新的排序字段
            notifier.updateSortOption(
              filter.sortOption.copyWith(field: field),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.m,
            vertical: AppSizes.s,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Radio<SortField>(
                  value: field,
                  groupValue: selected ? field : null,
                  onChanged: (_) {
                    // 如果点击当前选中的项，重置为默认排序
                    if (selected) {
                      notifier.updateSortOption(SortSection.defaultSortOption);
                    } else {
                      notifier.updateSortOption(
                        filter.sortOption.copyWith(field: field),
                      );
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection(BuildContext context, CharacterFilter filter,
      CharacterFilterNotifier notifier) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('排序', style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSizes.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.s),
              ),
              child: InkWell(
                onTap: () => (notifier.updateSortOption(filter.sortOption
                    .copyWith(descending: !filter.sortOption.descending))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.sortOption.descending ? '降序' : '升序',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sort,
                      size: 18,
                      textDirection: filter.sortOption.descending
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s),
        ...SortField.values.where((field) => field != SortField.none).map(
            (field) =>
                _buildSortItem(field, field.label, theme, filter, notifier)),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, CharacterFilter filter,
      CharacterFilterNotifier notifier) {
    // 这里应该从数据库获取最常用的标签列表
    // 示例标签列表
    final commonTags = ['经典', '传统', '现代', '名家', '精选', '教学用例'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonTags.map((tag) {
            final isSelected = filter.tags.contains(tag);

            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addTag(tag);
                } else {
                  notifier.removeTag(tag);
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppSizes.spacingMedium),

        // 自定义标签输入
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '添加标签',
            hintText: '输入标签名称后按回车添加',
            suffixIcon: Icon(Icons.add),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              notifier.addTag(value);
            }
          },
        ),

        if (filter.tags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingMedium),

          // 当前选中的标签
          Text(
            '已选标签:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => notifier.removeTag(tag),
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildWritingToolSection(BuildContext context, CharacterFilter filter,
      CharacterFilterNotifier notifier) {
    // 这里应该从数据库或配置获取可用的书写工具列表
    final writingTools = WorkTool.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '书写工具',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: writingTools.map((tool) {
            final isSelected = filter.tool == tool;

            return FilterChip(
              label: Text(tool.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.updateWritingTools(tool);
                } else {
                  notifier.updateWritingTools(null);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
