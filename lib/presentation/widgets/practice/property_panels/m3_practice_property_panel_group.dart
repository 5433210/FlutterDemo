import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_practice_property_panel_base.dart';

/// Material 3 组合内容属性面板
class M3GroupPropertyPanel extends M3PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const M3GroupPropertyPanel({
    super.key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(controller: controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 获取基本属性
    final x = (element['x'] as num?)?.toDouble() ?? 0.0;
    final y = (element['y'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final name = element['name'] as String? ?? l10n.unnamedGroup;
    final id = element['id'] as String;
    final layerId = element['layerId'] as String?;
    final isLocked = element['locked'] as bool? ?? false;
    final isHidden = element['hidden'] as bool? ?? false;

    // 获取组合内的元素
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final children = content['children'] as List<dynamic>? ?? [];

    // 获取图层信息
    final layer = layerId != null
        ? controller.state.layers.firstWhere(
            (l) => l['id'] == layerId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    return ListView(
      children: [
        // 组合标题
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.group_work,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.practiceEditGroupProperties,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 基本属性卡片
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
                  l10n.basicInfo,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // 元素名称
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => _updateProperty('name', value),
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
                        value: isLocked,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          _updateProperty('locked', value);
                        },
                        secondary: Icon(
                          isLocked ? Icons.lock : Icons.lock_open,
                          color: isLocked
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
                        value: !isHidden,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          _updateProperty('hidden', !value);
                        },
                        secondary: Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          color: isHidden
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // 图层信息
                if (layer != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      Icons.layers,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      l10n.layer,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(
                      layer['name'] as String? ?? l10n.unnamedLayer,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 8),
                        Icon(
                          (layer['isLocked'] as bool? ?? false)
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 16,
                          color: (layer['isLocked'] as bool? ?? false)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],

                // 元素ID（只读）
                const SizedBox(height: 8),
                Text(
                  'ID: $id',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          context: context,
          title: l10n.practiceEditGeometryProperties,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onXChanged: (value) => _updateProperty('x', value),
          onYChanged: (value) => _updateProperty('y', value),
          onWidthChanged: (value) => _updateProperty('width', value),
          onHeightChanged: (value) => _updateProperty('height', value),
          onRotationChanged: (value) => _updateProperty('rotation', value),
        ),

        // 视觉属性部分
        buildVisualSection(
          context: context,
          title: l10n.practiceEditVisualProperties,
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 组合信息部分
        m3ExpansionTile(
          context: context,
          title: l10n.groupInfo,
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.contains} ${children.length} ${l10n.elements}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 取消组合
                      controller.ungroupElements(element['id'] as String);
                    },
                    icon: const Icon(Icons.group_off),
                    label: Text(l10n.ungroup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
