import 'package:flutter/material.dart';
import '../../models/work_filter.dart';
import '../../theme/app_sizes.dart';
import 'date_range_filter_section.dart';

class WorkFilterPanel extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  final List<({String label, SortField value})> _sortOptions = [
    (label: '名称', value: SortField.name),
    (label: '作者', value: SortField.author),
    (label: '创作时间', value: SortField.creationDate),
    (label: '导入时间', value: SortField.importDate),
  ];

  WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // 添加滚动支持
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.m),
        child: Column(  // 将 ListView 改为 Column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSortSection(context),
            const Divider(),
            _buildStyleFilter(context),
            const Divider(),
            _buildToolFilter(context),
            const Divider(),
            _buildDateFilter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('排序方式', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.s),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: [
            for (final option in _sortOptions)
              FilterChip(
                label: Text(option.label),
                selected: filter.sortOption.field == option.value,
                onSelected: (selected) {
                  onFilterChanged(filter.copyWith(
                    sortOption: selected ? SortOption(field: option.value, descending: true) : null,
                  ));
                },
              ),
          ],
        ),
        if (filter.sortOption.field != SortField.none) ...[
          const SizedBox(height: AppSizes.s),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('升序')),
              ButtonSegment(value: true, label: Text('降序')),
            ],
            selected: {filter.sortOption.descending},
            onSelectionChanged: (value) {
              onFilterChanged(filter.copyWith(
                sortOption: SortOption(field: SortField.none, descending: value.first)
              ));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('时间筛选', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.s),
        DateRangeFilterSection(
          filter: filter.dateFilter,
          onChanged: (dateFilter) {
            onFilterChanged(filter.copyWith(
              dateFilter: () => dateFilter,
            ));
          },
        ),
      ],
    );
  }

  Widget _buildStyleFilter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书法风格', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSizes.xs),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: [
            for (final style in ['楷书', '行书', '草书', '隶书'])
              FilterChip(
                label: Text(style),
                selected: filter.selectedStyle == style,
                onSelected: (selected) {
                  onFilterChanged(filter.copyWith(
                    selectedStyle: () => selected ? style : null,
                  ));
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolFilter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书写工具', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSizes.xs),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: [
            for (final tool in ['毛笔', '硬笔'])
              FilterChip(
                label: Text(tool),
                selected: filter.selectedTool == tool,
                onSelected: (selected) {
                  onFilterChanged(filter.copyWith(
                    selectedTool: () => selected ? tool : null,
                  ));
                },
              ),
          ],
        ),
      ],
    );
  }
}