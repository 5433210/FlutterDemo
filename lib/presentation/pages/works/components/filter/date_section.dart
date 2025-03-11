import 'package:flutter/material.dart';

import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../theme/app_sizes.dart';
import 'date_range_filter_section.dart';

class DateSection extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const DateSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创作时间', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.s),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: filter.datePreset,
            start: filter.dateRange?.start,
            end: filter.dateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 如果日期筛选被清除，重置所有相关字段
              onFilterChanged(filter.copyWith(
                datePreset: DateRangePreset.all,
                dateRange: null,
              ));
            } else {
              onFilterChanged(filter.copyWith(
                datePreset: dateFilter.preset ?? DateRangePreset.all,
                dateRange: dateFilter.effectiveRange,
              ));
            }
          },
        ),
      ],
    );
  }
}
