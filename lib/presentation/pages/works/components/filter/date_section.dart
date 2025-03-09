import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../providers/work_browse_provider.dart';
import 'date_range_filter_section.dart';
import 'date_range_section.dart';

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
            onFilterChanged(filter.copyWith(
              datePreset: dateFilter?.preset ?? filter.datePreset,
              dateRange: dateFilter?.effectiveRange,
            ));
          },
        ),
      ],
    );
  }
}

class _CustomTab extends ConsumerWidget {
  const _CustomTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s),
        child: DateRangeSection(
          initialValue: state.filter.dateRange,
          onChanged: (range) {
            if (range != null) {
              viewModel.updateDateRange(range);
            } else {
              viewModel.clearDateFilter();
            }
          },
        ),
      ),
    );
  }
}

class _PresetTab extends ConsumerWidget {
  const _PresetTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s),
      child: Wrap(
        spacing: AppSizes.xs,
        runSpacing: AppSizes.xs,
        children: DateRangePreset.values
            .map((preset) => FilterChip(
                  label: Text(preset.label),
                  selected: state.filter.datePreset == preset,
                  onSelected: (selected) =>
                      viewModel.updateDatePreset(selected ? preset : null),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    );
  }
}
