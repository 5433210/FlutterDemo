import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/providers/config_providers.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import 'work_filter_section.dart';

class StyleSection extends ConsumerWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const StyleSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return WorkFilterSection(
      title: l10n.calligraphyStyle,
      child: _buildStyleChips(context, ref),
    );
  }
  Widget _buildStyleChips(BuildContext context, WidgetRef ref) {
    final stylesAsync = ref.watch(activeStyleItemsProvider);
    final displayNamesAsync = ref.watch(styleDisplayNamesProvider);
    
    return stylesAsync.when(
      data: (styles) => displayNamesAsync.when(
        data: (displayNames) => Wrap(
          spacing: 8,
          runSpacing: 8,          children: styles.map((styleItem) {
            final selected = filter.style == styleItem.key;
            final displayName = displayNames[styleItem.key] ?? styleItem.displayName;
            return FilterChip(
              label: Text(displayName),
              selected: selected,
              onSelected: (value) {
                final newStyle = selected ? null : styleItem.key;
                onFilterChanged(
                  filter.copyWith(style: newStyle),
                );
              },
            );
          }).toList(),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
