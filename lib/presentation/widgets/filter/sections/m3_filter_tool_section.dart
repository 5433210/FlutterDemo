import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/providers/config_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的书写工具筛选部分组件
class M3FilterToolSection extends ConsumerWidget {
  /// 当前选中的书写工具
  final String? selectedTool;

  /// 书写工具变化时的回调
  final ValueChanged<String?> onToolChanged;

  /// 构造函数
  const M3FilterToolSection({
    super.key,
    required this.selectedTool,
    required this.onToolChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    final activeToolItems = ref.watch(activeToolItemsProvider);
    final toolDisplayNames = ref.watch(toolDisplayNamesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.writingTool,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        activeToolItems.when(
          data: (tools) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tools.map((tool) {
              final isSelected = selectedTool == tool.key;
              final displayName = toolDisplayNames.maybeWhen(
                data: (names) => names[tool.key] ?? tool.displayName,
                orElse: () => tool.displayName,
              );
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (selected) {
                  onToolChanged(selected ? tool.key : null);
                },
              );
            }).toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text(
            'Loading error', // TODO: Add proper localization
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
