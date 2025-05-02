import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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

    return ExpansionTile(
      title: Text(
        l10n.layerInfo,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      initiallyExpanded: true,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerLow,
      collapsedBackgroundColor: colorScheme.surfaceContainerLow,
      childrenPadding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图层名称
              _buildInfoRow(
                context,
                label: l10n.layerName,
                content: Text(
                  layer!['name'] as String? ?? l10n.unnamedLayer,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),

              // 图层可见性
              _buildInfoRow(
                context,
                label: l10n.visibility,
                content: Row(
                  children: [
                    Icon(
                      (layer!['isVisible'] as bool? ?? true)
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                      color: (layer!['isVisible'] as bool? ?? true)
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (layer!['isVisible'] as bool? ?? true) ? l10n.visible : l10n.hideElement,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),

              // 图层锁定状态
              _buildInfoRow(
                context,
                label: l10n.lockStatus,
                content: Row(
                  children: [
                    Icon(
                      (layer!['isLocked'] as bool? ?? false)
                          ? Icons.lock
                          : Icons.lock_open,
                      size: 20,
                      color: (layer!['isLocked'] as bool? ?? false)
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (layer!['isLocked'] as bool? ?? false) ? l10n.locked : l10n.unlocked,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建信息行
  Widget _buildInfoRow(BuildContext context, {required String label, required Widget content}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
