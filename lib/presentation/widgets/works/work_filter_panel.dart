import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/date_range_filter.dart';
import '../../models/work_filter.dart';
import '../../theme/app_sizes.dart';

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
            _buildDateRangeFilter(context),
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
                    sortOption: SortOption(
                      field: selected ? option.value : SortField.none,
                      descending: filter.sortOption.descending,
                    ),
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
                sortOption: filter.sortOption.copyWith(
                  descending: value.first,
                ),
              ));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('时间筛选', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.s),
        SizedBox(
          height: 300, // 固定高度避免溢出
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Tab 标签栏
                TabBar(
                  tabs: const [
                    Tab(text: '快捷选择'),
                    Tab(text: '自定义范围'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSizes.m),
                
                // Tab 内容区
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildQuickDatePresets(),
                      _buildCustomDateRange(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDatePresets() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
      child: Wrap(
        spacing: AppSizes.s,
        runSpacing: AppSizes.s,
        children: [
          for (final preset in DateRangePreset.values)
            FilterChip(
              label: Text(preset.label),
              selected: filter.dateFilter?.preset == preset,
              onSelected: (selected) {
                onFilterChanged(filter.copyWith(
                  dateFilter: () => selected 
                    ? DateRangeFilter.preset(preset)
                    : null,
                ));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRange(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s),
      child: Column(
        children: [
          // 开始日期
          _buildDateField(
            context,
            label: '开始日期',
            date: filter.dateFilter?.startDate,
            onDateSelected: (date) {
              onFilterChanged(filter.copyWith(
                dateFilter: () => DateRangeFilter(
                  startDate: date,
                  endDate: filter.dateFilter?.endDate,
                ),
              ));
            },
          ),
          const SizedBox(height: AppSizes.m),
          // 结束日期
          _buildDateField(
            context,
            label: '结束日期',
            date: filter.dateFilter?.endDate,
            onDateSelected: (date) {
              onFilterChanged(filter.copyWith(
                dateFilter: () => DateRangeFilter(
                  startDate: filter.dateFilter?.startDate,
                  endDate: date,
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSizes.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  date != null 
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : '点击选择日期',
                ),
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    onDateSelected(selected);
                  }
                },
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onDateSelected(null),
              ),
          ],
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