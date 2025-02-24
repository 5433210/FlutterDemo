import 'package:flutter/material.dart';
import '../../models/date_range_filter.dart';
import '../../models/work_filter.dart';
import '../filter/filter_panel.dart';
import 'date_range_filter_section.dart';
import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';

class WorkFilterPanel extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterPanel(
          title: '书法风格',
          items: WorkStyle.values,
          selectedValue: filter.style,
          onSelected: (value) {
            final currentStyle = filter.style;
            onFilterChanged(filter.copyWith(
              style: currentStyle == value ? null : value as WorkStyle,
            ));
          },
        ),
        FilterPanel(
          title: '书写工具',
          items: WorkTool.values,
          selectedValue: filter.tool,
          onSelected: (value) {
            final currentTool = filter.tool;
            onFilterChanged(filter.copyWith(
              tool: currentTool == value ? null : value as WorkTool,
            ));
          },
        ),
        DateRangeFilterSection(
          key: ValueKey(filter.dateRange),
          filter: DateRangeFilter(
              preset: filter.datePreset,
              end: filter.dateRange?.end,
              start: filter.dateRange?.start),
          onChanged: (range) {
            onFilterChanged(filter.copyWith(
                dateRange: DateTimeRange(
                    start: filter.dateRange?.start ?? DateTime.now(),
                    end: filter.dateRange?.end ?? DateTime.now())));
          },
        ),
      ],
    );
  }
}
