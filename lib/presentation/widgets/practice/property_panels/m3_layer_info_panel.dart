import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'm3_panel_styles.dart';

/// Material 3 图层信息面板组件
/// 用于在各种元素的属性面板中显示图层信息（只读）
class M3LayerInfoPanel extends StatelessWidget {
  final Map<String, dynamic>? layer;

  const M3LayerInfoPanel({
    Key? key,
    required this.layer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (layer == null) return const SizedBox.shrink();

    final layerName = layer!['name'] as String? ?? l10n.unnamedLayer;
    final isVisible = layer!['isVisible'] as bool? ?? true;
    final isLocked = layer!['isLocked'] as bool? ?? false;

    return M3PanelStyles.buildPanelCard(
      context: context,
      title: l10n.layerInfo,
      initiallyExpanded: true,
      children: [
        // 图层名称
        M3PanelStyles.buildSectionTitle(context, l10n.layerName),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(76),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            layerName,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // 图层状态
        Row(
          children: [
            // 可见性状态
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  M3PanelStyles.buildSectionTitle(context, l10n.visibility),
                  Row(
                    children: [
                      Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: isVisible
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVisible ? l10n.visible : l10n.hideElement,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 锁定状态
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  M3PanelStyles.buildSectionTitle(context, l10n.lockStatus),
                  Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        size: 20,
                        color: isLocked
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLocked ? l10n.locked : l10n.unlocked,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
