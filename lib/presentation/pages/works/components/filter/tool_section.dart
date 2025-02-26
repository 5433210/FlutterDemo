import 'package:flutter/material.dart';

import '../../../../../domain/enums/work_tool.dart';
import '../../../../models/work_filter.dart';
import 'work_filter_section.dart';

class ToolSection extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const ToolSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WorkFilterSection(
      title: '书写工具',
      child: _buildToolChips(context),
    );
  }

  Widget _buildToolChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkTool.values.map((tool) {
        final selected = filter.tool?.value == tool.value;
        return FilterChip(
          label: Text(tool.label),
          selected: selected,
          onSelected: (value) => onFilterChanged(
            filter.copyWith(
              tool: () => value ? WorkTool.fromValue(tool.value) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
