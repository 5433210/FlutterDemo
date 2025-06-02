// filepath: lib/canvas/ui/layer_panel/layer_info_panel.dart

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/interfaces/layer_data.dart';
import '../common/panel_styles.dart';

/// 图层信息面板组件
/// 用于在属性面板中显示图层的基本信息（只读）
class LayerInfoPanel extends StatelessWidget {
  /// 图层数据
  final LayerData? layer;

  /// 图层上的元素数量
  final int elementCount;

  const LayerInfoPanel({
    Key? key,
    required this.layer,
    this.elementCount = 0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (layer == null) return const SizedBox.shrink();

    final layerName = layer!.name;
    final isVisible = layer!.visible;
    final isLocked = layer!.locked;

    return PanelStyles.buildExpandableCard(
      context: context,
      title: l10n.layerInfo,
      defaultExpanded: true,
      children: [
        // 图层名称
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.name,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                width: double.infinity,
                child: Text(
                  layerName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 图层状态
        Row(
          children: [
            // 可见性状态
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.visibility,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        color: isVisible
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVisible ? l10n.visible : l10n.hideElement,
                        style: textTheme.bodySmall?.copyWith(
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
                  Text(
                    l10n.lockStatus,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        size: 16,
                        color: isLocked
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLocked ? l10n.locked : l10n.unlocked,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ), // 图层元素计数
        const SizedBox(height: 16),
        Text(
          '${l10n.elements}: $elementCount',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
