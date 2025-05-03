import 'package:flutter/material.dart';

import '../../../../domain/enums/work_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的书法风格筛选部分组件
class M3FilterStyleSection extends StatelessWidget {
  /// 当前选中的书法风格
  final WorkStyle? selectedStyle;

  /// 可用的书法风格列表
  final List<WorkStyle> availableStyles;

  /// 书法风格变化时的回调
  final ValueChanged<WorkStyle?> onStyleChanged;

  /// 构造函数
  const M3FilterStyleSection({
    super.key,
    required this.selectedStyle,
    required this.availableStyles,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filterStyleSection,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableStyles.map((style) {
            final isSelected = selectedStyle == style;
            return FilterChip(
              label: Text(_getLocalizedStyleName(style, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                onStyleChanged(selected ? style : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 获取本地化的书法风格名称
  String _getLocalizedStyleName(WorkStyle style, AppLocalizations l10n) {
    switch (style) {
      case WorkStyle.regular:
        return l10n.filterStyleRegular;
      case WorkStyle.running:
        return l10n.filterStyleRunning;
      case WorkStyle.cursive:
        return l10n.filterStyleCursive;
      case WorkStyle.clerical:
        return l10n.filterStyleClerical;
      case WorkStyle.seal:
        return l10n.filterStyleSeal;
      case WorkStyle.other:
        return l10n.filterStyleOther;
    }
  }
}
