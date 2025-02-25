import 'package:flutter/material.dart';
import '../../../../../domain/enums/work_tool.dart';

class ToolSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return WorkFilterSection(
      title: '书写工具',
      child: _buildToolChips(state, viewModel),
    );
  }

  Widget _buildToolChips(WorkBrowseState state, WorkBrowseViewModel viewModel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkTool.values.map((tool) {
        final selected = state.filter.tool == tool;
        return FilterChip(
          label: Text(tool.label),
          selected: selected,
          onSelected: (value) => 
              viewModel.updateFilter(state.filter.copyWith(
                tool: value ? tool : null,
              )),
        );
      }).toList(),
    );
  }
}
