import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_practice_property_panel_base.dart';

/// Material 3 多选属性面板
class M3MultiSelectionPropertyPanel extends M3PracticePropertyPanel {
  final List<String> selectedIds;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3MultiSelectionPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 获取所有选中的元素
    final elements = selectedIds
        .map((id) => controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == id,
            orElse: () => <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();

    if (elements.isEmpty) {
      return Center(
        child: Text(
          l10n.noElementsSelected,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 计算共同属性
    final commonOpacity = _getCommonOpacity(elements);
    final commonLocked = _getCommonLocked(elements);
    final commonHidden = _getCommonHidden(elements);
    final commonLayerId = _getCommonLayerId(elements);

    // 获取图层信息
    final layer = commonLayerId != null
        ? controller.state.layers.firstWhere(
            (l) => l['id'] == commonLayerId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    return ListView(
      children: [
        // 多选标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.selected}: ${selectedIds.length} ${l10n.elements}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 多选操作卡片
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commonProperties,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 锁定和可见性控制
                Row(
                  children: [
                    // 锁定控制
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          l10n.locked,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: commonLocked ?? false,
                        activeColor: colorScheme.primary,
                        onChanged: commonLocked != null
                            ? (value) {
                                _updateAllElements('locked', value);
                              }
                            : null,
                        secondary: Icon(
                          commonLocked == true ? Icons.lock : Icons.lock_open,
                          color: commonLocked == true
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        dense: true,
                      ),
                    ),

                    // 可见性控制
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          l10n.visible,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: !(commonHidden ?? false),
                        activeColor: colorScheme.primary,
                        onChanged: commonHidden != null
                            ? (value) {
                                _updateAllElements('hidden', !value);
                              }
                            : null,
                        secondary: Icon(
                          commonHidden == true
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: commonHidden == true
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 透明度控制
                if (commonOpacity != null) ...[
                  Text(
                    l10n.opacity,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: commonOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(commonOpacity * 100).round()}%',
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.surfaceContainerHighest,
                          onChanged: (value) {
                            _updateAllElements('opacity', value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(commonOpacity * 100).round()}%',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 图层信息
                if (layer != null) ...[
                  Text(
                    l10n.layer,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      Icons.layers,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      layer['name'] as String? ?? l10n.unnamedLayer,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          (layer['isVisible'] as bool? ?? true)
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 16,
                          color: (layer['isVisible'] as bool? ?? true)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          (layer['isLocked'] as bool? ?? false)
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 16,
                          color: (layer['isLocked'] as bool? ?? false)
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    dense: true,
                  ),
                ],

                const SizedBox(height: 16),

                // 批量操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // 删除所有选中的元素
                        for (final id in selectedIds) {
                          controller.deleteElement(id);
                        }
                      },
                      icon: Icon(
                        Icons.delete,
                        color: colorScheme.error,
                        size: 18,
                      ),
                      label: Text(
                        l10n.deleteAll,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 组合所有选中的元素
                        controller.groupSelectedElements();
                      },
                      icon: Icon(
                        Icons.group_work,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      label: Text(
                        l10n.group,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 获取所有元素的共同隐藏状态
  bool? _getCommonHidden(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstHidden = elements.first['hidden'] as bool? ?? false;

    for (final element in elements) {
      final hidden = element['hidden'] as bool? ?? false;
      if (hidden != firstHidden) {
        return null; // 不一致
      }
    }

    return firstHidden;
  }

  // 获取所有元素的共同图层ID
  String? _getCommonLayerId(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstLayerId = elements.first['layerId'] as String?;
    if (firstLayerId == null) return null;

    for (final element in elements) {
      final layerId = element['layerId'] as String?;
      if (layerId != firstLayerId) {
        return null; // 不一致
      }
    }

    return firstLayerId;
  }

  // 获取所有元素的共同锁定状态
  bool? _getCommonLocked(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstLocked = elements.first['locked'] as bool? ?? false;

    for (final element in elements) {
      final locked = element['locked'] as bool? ?? false;
      if (locked != firstLocked) {
        return null; // 不一致
      }
    }

    return firstLocked;
  }

  // 获取所有元素的共同不透明度
  double? _getCommonOpacity(List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return null;

    final firstOpacity = (elements.first['opacity'] as num?)?.toDouble() ?? 1.0;

    for (final element in elements) {
      final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
      if ((opacity - firstOpacity).abs() > 0.01) {
        return null; // 不一致
      }
    }

    return firstOpacity;
  }

  // 更新所有选中元素的属性
  void _updateAllElements(String key, dynamic value) {
    for (final id in selectedIds) {
      onElementPropertiesChanged({key: value});
    }
  }
}
