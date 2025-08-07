import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'm3_panel_styles.dart';

/// Material 3 元素通用属性面板
/// 用于显示元素的通用属性，如名称、ID、图层等
class M3ElementCommonPropertyPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final PracticeEditController controller;

  // 🚀 优化：静态变量移至class级别
  static int _buildCount = 0;
  static String _lastElementId = '';

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

    // 🚀 优化：减少元素通用属性面板的重复构建日志
    _buildCount++;
    final hasSignificantChange = id != _lastElementId || _buildCount % 30 == 0;
    
    if (hasSignificantChange) {
      EditPageLogger.propertyPanelDebug(
        '元素通用属性面板构建',
        data: {
          'elementId': id,
          'elementType': type,
          'buildCount': _buildCount,
          'changeType': id != _lastElementId ? 'element_change' : 'milestone',
          'optimization': 'common_panel_build_optimized',
        },
      );
      
      _lastElementId = id;
    }

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
        typeDisplayName = l10n.characterCollection;
        break;
      case 'group':
        typeDisplayName = l10n.group;
        break;
      default:
        typeDisplayName = l10n.elements;
    }

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'element_common_properties',
      title: typeDisplayName,
      defaultExpanded: true,
      children: [
        // 元素状态控制
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 锁定按钮
            Row(
              children: [
                Text(
                  l10n.locked,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4.0),
                Switch(
                  value: isLocked,
                  activeColor: colorScheme.primary,
                  onChanged: (value) => _updateProperty('locked', value),
                ),
              ],
            ),
            const SizedBox(width: 16.0),
            // 可见性按钮
            Row(
              children: [
                Text(
                  l10n.visible,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4.0),
                Switch(
                  value: !isHidden,
                  activeColor: colorScheme.primary,
                  onChanged: (value) => _updateProperty('hidden', !value),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 元素名称
        M3PanelStyles.buildSectionTitle(context, l10n.name),
        TextField(
          decoration: InputDecoration(
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
        const SizedBox(height: 16.0),

        // 图层选择
        if (layers.isNotEmpty) ...[
          M3PanelStyles.buildSectionTitle(context, l10n.layer),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            ),
            value: _getValidLayerId(layerId, layers),
            items: _buildLayerItems(context),
            onChanged: (value) {
              if (value != null) {
                _updateLayerProperty(value);
              }
            },
            isExpanded: true,
            dropdownColor: colorScheme.surfaceContainerHigh,
          ),
          const SizedBox(height: 16.0),
        ],

        // ID显示（只读）
        M3PanelStyles.buildSectionTitle(context, l10n.elementId),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest
                .withAlpha(76), // 0.3 透明度，使用withAlpha代替withOpacity
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            id,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
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
      List<Widget> icons = [];
      if (!isVisible) {
        icons.add(Icon(Icons.visibility_off,
            size: 16.0, color: colorScheme.onSurfaceVariant));
      }
      if (isLocked) {
        icons.add(Icon(Icons.lock, size: 16.0, color: colorScheme.tertiary));
      }

      return DropdownMenuItem<String>(
        value: layerId,
        child: Row(
          children: [
            Expanded(child: Text(layerName)),
            const SizedBox(width: 4.0),
            ...icons,
          ],
        ),
      );
    }).toList();
  }

  // 获取有效的图层ID
  String? _getValidLayerId(String? currentLayerId, List<Map<String, dynamic>> layers) {
    // 如果当前图层ID有效，直接返回
    if (currentLayerId != null && layers.any((layer) => layer['id'] == currentLayerId)) {
      return currentLayerId;
    }
    
    // 如果无效或为空，返回第一个可用图层的ID
    if (layers.isNotEmpty) {
      final firstLayerId = layers.first['id'] as String;
      
      if (currentLayerId != null && currentLayerId != firstLayerId) {
        EditPageLogger.propertyPanelDebug(
          '元素图层ID自动修正',
          data: {
            'elementId': element['id'],
            'invalidLayerId': currentLayerId,
            'correctedLayerId': firstLayerId,
            'operation': 'layer_id_correction',
          },
        );
      }
      
      return firstLayerId;
    }
    
    // 如果没有图层，返回null
    return null;
  }

  // 更新图层属性（专门处理图层变更）
  void _updateLayerProperty(String newLayerId) {
    final currentLayerId = element['layerId'] as String?;
    
    if (currentLayerId != newLayerId) {
      EditPageLogger.propertyPanelDebug(
        '元素图层变更',
        data: {
          'elementId': element['id'],
          'elementType': element['type'],
          'fromLayerId': currentLayerId,
          'toLayerId': newLayerId,
          'operation': 'layer_change',
        },
      );
      
      // 获取图层信息用于日志
      final layers = controller.state.layers;
      final fromLayer = layers.where((layer) => layer['id'] == currentLayerId).firstOrNull;
      final toLayer = layers.where((layer) => layer['id'] == newLayerId).firstOrNull;
      
      EditPageLogger.propertyPanelDebug(
        '图层变更详细信息',
        data: {
          'elementId': element['id'],
          'fromLayerName': fromLayer?['name'],
          'toLayerName': toLayer?['name'],
          'fromLayerVisible': fromLayer?['isVisible'],
          'toLayerVisible': toLayer?['isVisible'],
          'fromLayerLocked': fromLayer?['isLocked'],
          'toLayerLocked': toLayer?['isLocked'],
          'operation': 'layer_change_details',
        },
      );
    }
    
    _updateProperty('layerId', newLayerId);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final currentValue = element[key];
    
    if (currentValue != value) {
      EditPageLogger.propertyPanelDebug(
        '元素属性变更',
        data: {
          'elementId': element['id'],
          'elementType': element['type'],
          'propertyKey': key,
          'fromValue': currentValue,
          'toValue': value,
          'operation': 'property_change',
        },
      );
      
      // 特殊属性的额外日志
      if (key == 'locked' || key == 'hidden') {
        EditPageLogger.propertyPanelDebug(
          '元素状态变更',
          data: {
            'elementId': element['id'],
            'statusType': key,
            'newStatus': value,
            'operation': 'status_change',
          },
        );
      } else if (key == 'name') {
        EditPageLogger.propertyPanelDebug(
          '元素名称变更',
          data: {
            'elementId': element['id'],
            'oldName': currentValue,
            'newName': value,
            'nameLength': (value as String).length,
            'operation': 'name_change',
          },
        );
      }
    }
    
    try {
      final updates = {key: value};
      onElementPropertiesChanged(updates);
    } catch (error, stackTrace) {
      EditPageLogger.propertyPanelError(
        '元素属性更新失败',
        error: error,
        stackTrace: stackTrace,
        data: {
          'elementId': element['id'],
          'propertyKey': key,
          'propertyValue': value,
          'operation': 'property_update_error',
        },
      );
    }
  }
}
