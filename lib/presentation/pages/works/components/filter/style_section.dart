import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/enums/work_style.dart';
import '../../../../models/work_filter.dart';
import '../../../../providers/work_browse_provider.dart';
import '../../../../viewmodels/states/work_browse_state.dart';
import '../../../../viewmodels/work_browse_view_model.dart';
import 'work_filter_section.dart';

class StyleSection extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const StyleSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WorkFilterSection(
      title: '书法风格',
      child: _buildStyleChips(context),
    );
  }

  Widget _buildStyleChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkStyle.values.map((style) {
        final selected = filter.style?.value == style.value;
        return FilterChip(
          label: Text(style.label),
          selected: selected,
          onSelected: (value) => onFilterChanged(
            filter.copyWith(
              style: () => value ? WorkStyle.fromValue(style.value) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
