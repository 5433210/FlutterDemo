/// 图像属性适配器
/// 用于编辑图像的属性，如位置、尺寸、缩放、旋转等
library;

import 'package:flutter/material.dart';

import '../../../../canvas/ui/property_panel/widgets/property_widgets.dart';
import 'property_panel_adapter.dart';

/// 图像属性适配器
class ImagePropertyAdapter extends BasePropertyPanelAdapter {
  @override
  List<String> get supportedElementTypes => ['image'];

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    if (selectedElements.isEmpty) {
      return const Center(child: Text('请选择一个图像'));
    }

    final element = selectedElements.first;
    final definitions = getPropertyDefinitions('image');

    return ListView(
      children: [
        // 基本属性组
        ExpansionTile(
          title: const Text('基本属性'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(definitions['src']!, element, onPropertyChanged),
            _buildPropertyTile(definitions['alt']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['visible']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['locked']!, element, onPropertyChanged),
          ],
        ),
        // 位置和尺寸组
        ExpansionTile(
          title: const Text('位置和尺寸'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(definitions['x']!, element, onPropertyChanged),
            _buildPropertyTile(definitions['y']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['width']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['height']!, element, onPropertyChanged),
          ],
        ),
        // 变换属性组
        ExpansionTile(
          title: const Text('变换属性'),
          children: [
            _buildPropertyTile(
                definitions['scaleX']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['scaleY']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['rotation']!, element, onPropertyChanged),
          ],
        ),
        // 外观属性组
        ExpansionTile(
          title: const Text('外观属性'),
          children: [
            _buildPropertyTile(
                definitions['opacity']!, element, onPropertyChanged),
          ],
        ),
      ],
    );
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    final definitions = getPropertyDefinitions('image');
    return definitions[propertyName]?.defaultValue;
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    return {
      'src': const PropertyDefinition(
        name: 'src',
        displayName: '图像源',
        type: PropertyType.string,
        isRequired: true,
        description: '图像文件路径或URL',
      ),
      'alt': const PropertyDefinition(
        name: 'alt',
        displayName: '替代文本',
        type: PropertyType.string,
        description: '图像的替代文本描述',
      ),
      'width': const PropertyDefinition(
        name: 'width',
        displayName: '宽度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
        description: '图像显示宽度',
      ),
      'height': const PropertyDefinition(
        name: 'height',
        displayName: '高度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
        description: '图像显示高度',
      ),
      'x': const PropertyDefinition(
        name: 'x',
        displayName: 'X坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '图像的X坐标',
      ),
      'y': const PropertyDefinition(
        name: 'y',
        displayName: 'Y坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '图像的Y坐标',
      ),
      'scaleX': const PropertyDefinition(
        name: 'scaleX',
        displayName: '水平缩放',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.1,
        maxValue: 5.0,
        description: '图像水平方向缩放比例',
      ),
      'scaleY': const PropertyDefinition(
        name: 'scaleY',
        displayName: '垂直缩放',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.1,
        maxValue: 5.0,
        description: '图像垂直方向缩放比例',
      ),
      'rotation': const PropertyDefinition(
        name: 'rotation',
        displayName: '旋转角度',
        type: PropertyType.number,
        defaultValue: 0.0,
        minValue: -360.0,
        maxValue: 360.0,
        description: '图像旋转角度（度）',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        description: '图像透明度',
      ),
      'visible': const PropertyDefinition(
        name: 'visible',
        displayName: '可见',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '图像是否可见',
      ),
      'locked': const PropertyDefinition(
        name: 'locked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '图像是否锁定编辑',
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! Map<String, dynamic>) return null;

    switch (propertyName) {
      case 'src':
        return element['src'] ?? '';
      case 'alt':
        return element['alt'] ?? '';
      case 'width':
        return element['width'] ?? 100.0;
      case 'height':
        return element['height'] ?? 100.0;
      case 'x':
        return element['x'] ?? 0.0;
      case 'y':
        return element['y'] ?? 0.0;
      case 'scaleX':
        return element['scaleX'] ?? 1.0;
      case 'scaleY':
        return element['scaleY'] ?? 1.0;
      case 'rotation':
        return element['rotation'] ?? 0.0;
      case 'opacity':
        return element['opacity'] ?? 1.0;
      case 'visible':
        return element['visible'] ?? true;
      case 'locked':
        return element['locked'] ?? false;
      default:
        return null;
    }
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! Map<String, dynamic>) return;

    switch (propertyName) {
      case 'src':
      case 'alt':
        if (value is String) element[propertyName] = value;
        break;
      case 'width':
      case 'height':
        if (value is num && value > 0) {
          element[propertyName] = value.toDouble();
        }
        break;
      case 'x':
      case 'y':
        if (value is num) element[propertyName] = value.toDouble();
        break;
      case 'scaleX':
      case 'scaleY':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.1, 5.0);
        }
        break;
      case 'rotation':
        if (value is num) {
          element[propertyName] = value.toDouble() % 360;
        }
        break;
      case 'opacity':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.0, 1.0);
        }
        break;
      case 'visible':
      case 'locked':
        if (value is bool) element[propertyName] = value;
        break;
    }
  }

  Widget _buildPropertyTile(
    PropertyDefinition property,
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    final currentValue = getPropertyValue(element, property.name);

    switch (property.type) {
      case PropertyType.string:
        return PropertyTextField(
          label: property.displayName,
          value: currentValue?.toString() ?? '',
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          hintText: property.description,
        );
      case PropertyType.number:
        return PropertyNumberField(
          label: property.displayName,
          value: (currentValue as num?)?.toDouble() ??
              property.defaultValue?.toDouble() ??
              0.0,
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          min: property.minValue?.toDouble(),
          max: property.maxValue?.toDouble(),
          suffix: property.unit,
        );
      case PropertyType.boolean:
        return PropertySwitch(
          label: property.displayName,
          value: currentValue == true,
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          description: property.description,
        );
      case PropertyType.slider:
        return PropertySlider(
          label: property.displayName,
          value: (currentValue as num?)?.toDouble() ??
              property.defaultValue?.toDouble() ??
              0.0,
          min: property.minValue?.toDouble() ?? 0.0,
          max: property.maxValue?.toDouble() ?? 1.0,
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          suffix: property.unit,
        );
      case PropertyType.color:
        return PropertyColorField(
          label: property.displayName,
          value: Color(currentValue as int? ?? 0xFF000000),
          onChanged: (color) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, color.value);
            }
          },
        );
      case PropertyType.select:
      case PropertyType.dropdown:
        if (property.allowedValues != null) {
          return PropertyDropdown(
            label: property.displayName,
            value: currentValue ??
                property.defaultValue ??
                property.allowedValues!.first,
            items: property.allowedValues!,
            onChanged: (value) {
              if (element is Map<String, dynamic> &&
                  element.containsKey('id')) {
                onPropertyChanged(element['id'], property.name, value);
              }
            },
          );
        }
        // Fallback to text field if no allowed values
        return PropertyTextField(
          label: property.displayName,
          value: currentValue?.toString() ?? '',
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
        );
      default:
        return PropertyTextField(
          label: property.displayName,
          value: currentValue?.toString() ?? '',
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          hintText: property.description,
        );
    }
  }
}
