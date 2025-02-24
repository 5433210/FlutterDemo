import 'package:flutter/material.dart';
import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../models/date_range_filter.dart';
import '../../models/work_filter.dart';
import '../../theme/app_sizes.dart';
import 'date_range_filter_section.dart';

class WorkFilterPanel extends StatefulWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  _WorkFilterPanelState createState() => _WorkFilterPanelState();
}

class _WorkFilterPanelState extends State<WorkFilterPanel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSortSection(context),
          const Divider(height: AppSizes.l),
          _buildStyleSection(context),
          const Divider(height: AppSizes.l),
          _buildToolSection(context),
          const Divider(height: AppSizes.l),
          _buildDateSection(context),
        ],
      ),
    );
  }

  Widget _buildSortSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDescending = widget.filter.sortOption.descending;
    
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
                onTap: () => widget.onFilterChanged(widget.filter.copyWith(
                  sortOption: widget.filter.sortOption.copyWith(
                    descending: !isDescending,
                  ),
                )),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDescending ? '降序' : '升序',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sort,
                      size: 18,
                      textDirection: isDescending ? TextDirection.rtl : TextDirection.ltr,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s),
        ...SortField.values.map((field) => _buildSortItem(field, field.label)),
      ],
    );
  }

  Widget _buildSortItem(SortField field, String label) {
    final bool selected = widget.filter.sortOption.field == field;
    final theme = Theme.of(context);

    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.s),
        onTap: () => _handleSortFieldChanged(field),
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
                  onChanged: (_) => _handleSortFieldChanged(field),
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

  void _handleSortFieldChanged(SortField field) {
    widget.onFilterChanged(widget.filter.copyWith(
      sortOption: widget.filter.sortOption.copyWith(field: field)
    ));
  }

  Widget _buildStyleSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书法风格', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSizes.s),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: WorkStyle.values.map((style) => FilterChip(
            label: Text(style.label),
            selected: widget.filter.style == style,
            onSelected: (selected) => widget.onFilterChanged(widget.filter.copyWith(
              style: () => selected ? style : null
            )),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildToolSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书写工具', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSizes.s),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: WorkTool.values.map((tool) => FilterChip(
            label: Text(tool.label),
            selected: widget.filter.tool == tool,
            onSelected: (selected) => widget.onFilterChanged(widget.filter.copyWith(
              tool: () => selected ? tool : null
            )),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创作时间', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSizes.s),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: widget.filter.datePreset,
            start: widget.filter.dateRange?.start,  // 使用 start 而不是 startDate
            end: widget.filter.dateRange?.end,      // 使用 end 而不是 endDate
          ),
          onChanged: (dateFilter) {
            widget.onFilterChanged(widget.filter.copyWith(
              datePreset:() => dateFilter?.preset,
              dateRange: () => dateFilter?.effectiveRange,
            ));
          },
        ),
      ],
    );
  }
}
