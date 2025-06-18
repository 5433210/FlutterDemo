import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/providers/config_providers.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import 'work_filter_section.dart';

class ToolSection extends ConsumerWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const ToolSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return WorkFilterSection(
      title: l10n.writingTool,
      child: _buildToolChips(context, ref),
    );
  }
  Widget _buildToolChips(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(activeToolItemsProvider);
    final displayNamesAsync = ref.watch(toolDisplayNamesProvider);
    
    return toolsAsync.when(
      data: (tools) => displayNamesAsync.when(
        data: (displayNames) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.map((toolItem) {
            final selected = filter.tool == toolItem.key;
            final displayName = displayNames[toolItem.key] ?? toolItem.displayName;
            return FilterChip(
              label: Text(displayName),
              selected: selected,
              onSelected: (value) {
                final newTool = selected ? null : toolItem.key;
                onFilterChanged(
                  filter.copyWith(tool: newTool),
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
