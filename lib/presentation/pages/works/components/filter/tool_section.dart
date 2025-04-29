import 'package:flutter/material.dart';

import '../../../../../domain/enums/work_tool.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return WorkFilterSection(
      title: l10n.filterToolSection,
      child: _buildToolChips(context),
    );
  }

  Widget _buildToolChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkTool.values.map((tool) {
        final selected = filter.tool?.value == tool.value;
        return FilterChip(
          label: Text(_getToolLabel(tool, l10n)),
          selected: selected,
          onSelected: (value) {
            // 如果是取消选择或者点击当前已选中的项，则清除选择
            final newTool = selected ? null : WorkTool.fromValue(tool.value);
            onFilterChanged(
              filter.copyWith(tool: newTool),
            );
          },
        );
      }).toList(),
    );
  }
  
  String _getToolLabel(WorkTool tool, AppLocalizations l10n) {
    return switch (tool) {
      WorkTool.brush => l10n.filterToolBrush,
      WorkTool.hardPen => l10n.filterToolHardPen,
      WorkTool.other => l10n.filterToolOther,
    };
  }
}
