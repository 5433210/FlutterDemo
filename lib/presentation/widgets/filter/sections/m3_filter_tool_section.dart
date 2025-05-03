import 'package:flutter/material.dart';

import '../../../../domain/enums/work_tool.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的书写工具筛选部分组件
class M3FilterToolSection extends StatelessWidget {
  /// 当前选中的书写工具
  final WorkTool? selectedTool;

  /// 可用的书写工具列表
  final List<WorkTool> availableTools;

  /// 书写工具变化时的回调
  final ValueChanged<WorkTool?> onToolChanged;

  /// 构造函数
  const M3FilterToolSection({
    super.key,
    required this.selectedTool,
    required this.availableTools,
    required this.onToolChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filterToolSection,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTools.map((tool) {
            final isSelected = selectedTool == tool;
            return FilterChip(
              label: Text(_getLocalizedToolName(tool, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                onToolChanged(selected ? tool : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 获取本地化的书写工具名称
  String _getLocalizedToolName(WorkTool tool, AppLocalizations l10n) {
    switch (tool) {
      case WorkTool.brush:
        return l10n.filterToolBrush;
      case WorkTool.hardPen:
        return l10n.filterToolHardPen;
      case WorkTool.other:
        return l10n.filterToolOther;
    }
  }
}
