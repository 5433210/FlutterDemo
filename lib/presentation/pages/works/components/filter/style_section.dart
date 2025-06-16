import 'package:flutter/material.dart';

import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return WorkFilterSection(
      title: l10n.calligraphyStyle,
      child: _buildStyleChips(context),
    );
  }

  Widget _buildStyleChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkStyle.values.map((style) {
        final selected = filter.style?.value == style.value;
        return FilterChip(
          label: Text(_getStyleLabel(style, l10n)),
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
  
  String _getStyleLabel(WorkStyle style, AppLocalizations l10n) {
    return switch (style) {
      WorkStyle.regular => l10n.workStyleRegular,
      WorkStyle.running => l10n.workStyleRunning,
      WorkStyle.cursive => l10n.workStyleCursive,
      WorkStyle.clerical => l10n.workStyleClerical,
      WorkStyle.seal => l10n.workStyleSeal,
      WorkStyle.other => l10n.workToolOther,
    };
  }
}
