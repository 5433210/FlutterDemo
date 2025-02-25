import 'package:flutter/material.dart';
import '../../../../../domain/enums/date_range_preset.dart';

class DateRangeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return WorkFilterSection(
      title: '创作时间',
      child: Column(
        children: [
          _buildPresets(state, viewModel),
          const SizedBox(height: 8),
          _buildCustomDateRange(context, state, viewModel),
        ],
      ),  
    );
  }

  Widget _buildPresets(WorkBrowseState state, WorkBrowseViewModel viewModel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DateRangePreset.values.map((preset) => 
        FilterChip(
          label: Text(preset.label),
          selected: state.filter.datePreset == preset,
          onSelected: (value) => viewModel.updateDatePreset(value ? preset : null),
        ),
      ).toList(),
    );
  }

  Widget _buildCustomDateRange(
    BuildContext context,
    WorkBrowseState state,
    WorkBrowseViewModel viewModel,
  ) {
    return OutlinedButton(
      child: Text(state.filter.dateRange?.toString() ?? '自定义日期范围'),
      onPressed: () => _showDateRangePicker(context, viewModel),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    WorkBrowseViewModel viewModel,  
  ) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (dateRange != null) {
      viewModel.updateDateRange(dateRange);
    }
  }
}
