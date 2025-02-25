import 'package:flutter/material.dart';
import '../../../../models/date_range_filter.dart';

class DateSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return WorkFilterSection(
      title: '创作时间',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预设日期范围
          _buildPresetButtons(state, viewModel),
          const SizedBox(height: 16),
          // 自定义日期范围
          _buildCustomDateRange(context, state, viewModel),
        ],
      ),
    );
  }

  Widget _buildPresetButtons(WorkBrowseState state, WorkBrowseViewModel viewModel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPresetButton(
          label: '最近7天',
          selected: state.filter.datePreset == DateRangePreset.last7Days,
          onPressed: () => viewModel.updateDateRange(DateRangePreset.last7Days),
        ),
        // ...其他预设按钮
      ],
    );
  }

  Widget _buildCustomDateRange(
    BuildContext context, 
    WorkBrowseState state,
    WorkBrowseViewModel viewModel,
  ) {
    return Row(
      children: [
        // 自定义日期范围选择器
      ],
    );
  }
}
