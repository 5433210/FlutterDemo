import 'package:flutter/material.dart';

import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/models/work/work_filter.dart';
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
          onSelected: (value) {
            // 如果是取消选择或者点击当前已选中的项，则清除选择
            final newStyle = selected ? null : WorkStyle.fromValue(style.value);
            onFilterChanged(
              filter.copyWith(style: newStyle),
            );
          },
        );
      }).toList(),
    );
  }
}
