import 'package:flutter/material.dart';
import '../../../../../domain/enums/work_style.dart';

class StyleSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);
    
    return WorkFilterSection(
      title: '书法风格',
      child: _buildStyleChips(state, viewModel),
    );
  }

  Widget _buildStyleChips(WorkBrowseState state, WorkBrowseViewModel viewModel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkStyle.values.map((style) {
        final selected = state.filter.style == style;
        return FilterChip(
          label: Text(style.label),
          selected: selected,
          onSelected: (value) => 
              viewModel.updateFilter(state.filter.copyWith(
                style: value ? style : null,
              )),
        );
      }).toList(),
    );
  }
}
