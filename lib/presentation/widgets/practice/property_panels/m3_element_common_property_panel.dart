import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';

/// Material 3 元素通用属性面板
/// 用于显示元素的通用属性，如名称、ID、图层等
class M3ElementCommonPropertyPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final PracticeEditController controller;

  const M3ElementCommonPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final name = element['name'] as String? ?? l10n.unnamedElement;
    final id = element['id'] as String;
    final type = element['type'] as String;
    final layerId = element['layerId'] as String?;
    final isLocked = element['locked'] as bool? ?? false;
    final isHidden = element['hidden'] as bool? ?? false;

    // 获取图层数据
    final layers = controller.state.layers;

    // 获取元素类型显示名称
    String typeDisplayName;
    switch (type) {
      case 'text':
        typeDisplayName = l10n.text;
        break;
      case 'image':
        typeDisplayName = l10n.image;
        break;
      case 'collection':
        typeDisplayName = l10n.collection;
        break;
      case 'group':
        typeDisplayName = l10n.group;
        break;
      default:
        typeDisplayName = l10n.elements;
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  _getIconForType(type),
                  size: 20.0,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  typeDisplayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // 锁定按钮
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isLocked ? l10n.unlockElement : l10n.lockElement,
                  onPressed: () => _updateProperty('locked', !isLocked),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20.0,
                ),
                const SizedBox(width: 8.0),
                // 可见性按钮
                IconButton(
                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: isHidden ? colorScheme.onSurfaceVariant : colorScheme.primary,
                  ),
                  tooltip: isHidden ? l10n.showElement : l10n.hideElement,
                  onPressed: () => _updateProperty('hidden', !isHidden),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20.0,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 元素名称
            TextField(
              decoration: InputDecoration(
                labelText: l10n.name,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                hintText: l10n.unnamedElement,
              ),
              controller: TextEditingController(text: name),
              onChanged: (value) => _updateProperty('name', value),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12.0),

            // 图层选择
            if (layers.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.layer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                value: layerId,
                items: _buildLayerItems(context),
                onChanged: (value) {
                  if (value != null) {
                    _updateProperty('layerId', value);
                  }
                },
                isExpanded: true,
                dropdownColor: colorScheme.surfaceContainerHigh,
              ),

            // ID显示（只读）
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Text(
                    '${l10n.elementId}: ',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      id,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建图层下拉选项
  List<DropdownMenuItem<String>> _buildLayerItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    final layers = controller.state.layers;
    return layers.map((layer) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? l10n.unnamedLayer;
      final isVisible = layer['isVisible'] as bool? ?? true;
      final isLocked = layer['isLocked'] as bool? ?? false;

      // 显示图层状态图标
      Widget icon = const SizedBox(width: 0);
      if (!isVisible) {
        icon = Icon(Icons.visibility_off, size: 16.0, color: colorScheme.onSurfaceVariant);
      } else if (isLocked) {
        icon = Icon(Icons.lock, size: 16.0, color: colorScheme.tertiary);
      }

      return DropdownMenuItem<String>(
        value: layerId,
        child: Row(
          children: [
            Text(layerName),
            const SizedBox(width: 4.0),
            icon,
          ],
        ),
      );
    }).toList();
  }

  // 根据元素类型获取图标
  IconData _getIconForType(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'collection':
        return Icons.font_download;
      case 'group':
        return Icons.group_work;
      default:
        return Icons.crop_square;
    }
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
