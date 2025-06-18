import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/providers/config_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的书法风格筛选部分组件
class M3FilterStyleSection extends ConsumerWidget {
  /// 当前选中的书法风格
  final String? selectedStyle;

  /// 书法风格变化时的回调
  final ValueChanged<String?> onStyleChanged;
  /// 构造函数
  const M3FilterStyleSection({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    final activeStyleItems = ref.watch(activeStyleItemsProvider);
    final styleDisplayNames = ref.watch(styleDisplayNamesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calligraphyStyle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        activeStyleItems.when(
          data: (styles) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              final isSelected = selectedStyle == style.key;
              final displayName = styleDisplayNames.maybeWhen(
                data: (names) => names[style.key] ?? style.displayName,
                orElse: () => style.displayName,
              );
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (selected) {
                  onStyleChanged(selected ? style.key : null);
                },
              );
            }).toList(),
          ),
          loading: () => const CircularProgressIndicator(),          error: (error, stackTrace) => Text(
            'Loading error', // TODO: Add proper localization
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
