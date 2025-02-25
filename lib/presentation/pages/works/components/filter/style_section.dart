import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/enums/work_style.dart';
import '../../../../providers/work_browse_provider.dart';
import '../../../../viewmodels/states/work_browse_state.dart';
import '../../../../viewmodels/work_browse_view_model.dart';
import 'work_filter_section.dart';

class StyleSection extends ConsumerWidget {
  const StyleSection({super.key});

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
          onSelected: (value) {
            debugPrint('StyleSection - style selected: $style, value: $value'); // 添加日志
            viewModel.updateFilter(state.filter.copyWith(
              style: () => value ? style : null,
            ));
          },
        );
      }).toList(),
    );
  }
}
