/// 形状属性适配器
/// 用于编辑形状的属性，如位置、尺寸、填充、描边等
library;

import 'package:flutter/material.dart';

import '../../../../canvas/ui/property_panel/widgets/property_widgets.dart';
import 'property_panel_adapter.dart';

/// 形状属性适配器
class ShapePropertyAdapter extends BasePropertyPanelAdapter {
  @override
  List<String> get supportedElementTypes =>
      ['shape', 'rectangle', 'circle', 'ellipse', 'line', 'polygon', 'star'];

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    if (selectedElements.isEmpty) {
      return const Center(child: Text('请选择一个形状'));
    }

    final element = selectedElements.first;
    final shapeType = element['shapeType'] as String? ?? 'rectangle';
    final definitions = getPropertyDefinitions(shapeType);

    return ListView(
      children: [
        // 基本属性组
        ExpansionTile(
          title: const Text('基本属性'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(
                definitions['name']!, element, onPropertyChanged),
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
            if (shapeType != 'line') ...[
              _buildPropertyTile(
                  definitions['width']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['height']!, element, onPropertyChanged),
            ],
            _buildPropertyTile(
                definitions['rotation']!, element, onPropertyChanged),
          ],
        ),
        // 填充属性组
        ExpansionTile(
          title: const Text('填充属性'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(
                definitions['fillEnabled']!, element, onPropertyChanged),
            if (element['fillEnabled'] == true) ...[
              _buildPropertyTile(
                  definitions['fillColor']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['fillType']!, element, onPropertyChanged),
            ],
          ],
        ),
        // 描边属性组
        ExpansionTile(
          title: const Text('描边属性'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(
                definitions['strokeEnabled']!, element, onPropertyChanged),
            if (element['strokeEnabled'] == true) ...[
              _buildPropertyTile(
                  definitions['strokeColor']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['strokeWidth']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['strokeStyle']!, element, onPropertyChanged),
            ],
          ],
        ),
        // 阴影属性组
        ExpansionTile(
          title: const Text('阴影属性'),
          children: [
            _buildPropertyTile(
                definitions['shadowEnabled']!, element, onPropertyChanged),
            if (element['shadowEnabled'] == true) ...[
              _buildPropertyTile(
                  definitions['shadowColor']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['shadowBlur']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['shadowOffsetX']!, element, onPropertyChanged),
              _buildPropertyTile(
                  definitions['shadowOffsetY']!, element, onPropertyChanged),
            ],
          ],
        ),
        // 形状特定属性组
        if (_hasSpecificProperties(shapeType))
          ExpansionTile(
            title: Text('${_getShapeTypeLabel(shapeType)}特定属性'),
            children: _buildSpecificProperties(
                shapeType, element, definitions, onPropertyChanged),
          ),
      ],
    );
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    final definitions = getPropertyDefinitions('shape');
    return definitions[propertyName]?.defaultValue;
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    // 基础属性（所有形状通用）
    final baseProperties = <String, PropertyDefinition>{
      'name': const PropertyDefinition(
        name: 'name',
        displayName: '名称',
        type: PropertyType.string,
        defaultValue: '形状',
        description: '形状的名称',
      ),
      'visible': const PropertyDefinition(
        name: 'visible',
        displayName: '可见',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '形状是否可见',
      ),
      'locked': const PropertyDefinition(
        name: 'locked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '形状是否锁定编辑',
      ),
      'x': const PropertyDefinition(
        name: 'x',
        displayName: 'X坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '形状的X坐标',
      ),
      'y': const PropertyDefinition(
        name: 'y',
        displayName: 'Y坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '形状的Y坐标',
      ),
      'width': const PropertyDefinition(
        name: 'width',
        displayName: '宽度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
        description: '形状的宽度',
      ),
      'height': const PropertyDefinition(
        name: 'height',
        displayName: '高度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
        description: '形状的高度',
      ),
      'rotation': const PropertyDefinition(
        name: 'rotation',
        displayName: '旋转角度',
        type: PropertyType.number,
        defaultValue: 0.0,
        minValue: -360.0,
        maxValue: 360.0,
        description: '形状的旋转角度（度）',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        description: '形状的透明度',
      ),
      'fillEnabled': const PropertyDefinition(
        name: 'fillEnabled',
        displayName: '启用填充',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '是否启用形状填充',
      ),
      'fillColor': const PropertyDefinition(
        name: 'fillColor',
        displayName: '填充颜色',
        type: PropertyType.color,
        defaultValue: 0xFF2196F3,
        description: '形状的填充颜色',
      ),
      'fillType': const PropertyDefinition(
        name: 'fillType',
        displayName: '填充类型',
        type: PropertyType.select,
        defaultValue: 'solid',
        allowedValues: ['solid', 'gradient', 'pattern'],
        description: '填充的类型',
      ),
      'strokeEnabled': const PropertyDefinition(
        name: 'strokeEnabled',
        displayName: '启用描边',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '是否启用形状描边',
      ),
      'strokeColor': const PropertyDefinition(
        name: 'strokeColor',
        displayName: '描边颜色',
        type: PropertyType.color,
        defaultValue: 0xFF000000,
        description: '形状的描边颜色',
      ),
      'strokeWidth': const PropertyDefinition(
        name: 'strokeWidth',
        displayName: '描边宽度',
        type: PropertyType.number,
        defaultValue: 2.0,
        minValue: 0.0,
        maxValue: 20.0,
        description: '描边的宽度',
      ),
      'strokeStyle': const PropertyDefinition(
        name: 'strokeStyle',
        displayName: '描边样式',
        type: PropertyType.select,
        defaultValue: 'solid',
        allowedValues: ['solid', 'dashed', 'dotted'],
        description: '描边的样式',
      ),
      'shadowEnabled': const PropertyDefinition(
        name: 'shadowEnabled',
        displayName: '启用阴影',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '是否启用阴影效果',
      ),
      'shadowColor': const PropertyDefinition(
        name: 'shadowColor',
        displayName: '阴影颜色',
        type: PropertyType.color,
        defaultValue: 0x40000000,
        description: '阴影的颜色',
      ),
      'shadowBlur': const PropertyDefinition(
        name: 'shadowBlur',
        displayName: '阴影模糊',
        type: PropertyType.number,
        defaultValue: 4.0,
        minValue: 0.0,
        maxValue: 20.0,
        description: '阴影的模糊程度',
      ),
      'shadowOffsetX': const PropertyDefinition(
        name: 'shadowOffsetX',
        displayName: '阴影X偏移',
        type: PropertyType.number,
        defaultValue: 2.0,
        description: '阴影的X轴偏移',
      ),
      'shadowOffsetY': const PropertyDefinition(
        name: 'shadowOffsetY',
        displayName: '阴影Y偏移',
        type: PropertyType.number,
        defaultValue: 2.0,
        description: '阴影的Y轴偏移',
      ),
    };

    // 特定形状的专有属性
    Map<String, PropertyDefinition> specificProperties = {};

    // 根据形状类型添加特定属性
    switch (elementType) {
      case 'rectangle':
        specificProperties = {
          'borderRadius': const PropertyDefinition(
            name: 'borderRadius',
            displayName: '圆角半径',
            type: PropertyType.number,
            defaultValue: 0.0,
            minValue: 0.0,
            maxValue: 50.0,
            description: '矩形的圆角半径',
          ),
          'uniformRadius': const PropertyDefinition(
            name: 'uniformRadius',
            displayName: '统一圆角',
            type: PropertyType.boolean,
            defaultValue: true,
            description: '是否使用统一的圆角半径',
          ),
        };
        break;
      case 'circle':
      case 'ellipse':
        specificProperties = {
          'startAngle': const PropertyDefinition(
            name: 'startAngle',
            displayName: '起始角度',
            type: PropertyType.number,
            defaultValue: 0.0,
            minValue: 0.0,
            maxValue: 360.0,
            description: '椭圆弧的起始角度',
          ),
          'sweepAngle': const PropertyDefinition(
            name: 'sweepAngle',
            displayName: '扫描角度',
            type: PropertyType.number,
            defaultValue: 360.0,
            minValue: 1.0,
            maxValue: 360.0,
            description: '椭圆弧的扫描角度',
          ),
        };
        break;
      case 'line':
        specificProperties = {
          'endX': const PropertyDefinition(
            name: 'endX',
            displayName: '结束X坐标',
            type: PropertyType.number,
            defaultValue: 100.0,
            description: '线条结束点的X坐标',
          ),
          'endY': const PropertyDefinition(
            name: 'endY',
            displayName: '结束Y坐标',
            type: PropertyType.number,
            defaultValue: 0.0,
            description: '线条结束点的Y坐标',
          ),
          'lineCap': const PropertyDefinition(
            name: 'lineCap',
            displayName: '线帽样式',
            type: PropertyType.select,
            defaultValue: 'round',
            allowedValues: ['butt', 'round', 'square'],
            description: '线条端点的样式',
          ),
          'arrowStart': const PropertyDefinition(
            name: 'arrowStart',
            displayName: '起点箭头',
            type: PropertyType.boolean,
            defaultValue: false,
            description: '是否在起点显示箭头',
          ),
          'arrowEnd': const PropertyDefinition(
            name: 'arrowEnd',
            displayName: '终点箭头',
            type: PropertyType.boolean,
            defaultValue: false,
            description: '是否在终点显示箭头',
          ),
        };
        break;
      case 'polygon':
        specificProperties = {
          'sides': const PropertyDefinition(
            name: 'sides',
            displayName: '边数',
            type: PropertyType.number,
            defaultValue: 6.0,
            minValue: 3.0,
            maxValue: 20.0,
            description: '多边形的边数',
          ),
          'regularPolygon': const PropertyDefinition(
            name: 'regularPolygon',
            displayName: '正多边形',
            type: PropertyType.boolean,
            defaultValue: true,
            description: '是否为正多边形',
          ),
        };
        break;
      case 'star':
        specificProperties = {
          'points': const PropertyDefinition(
            name: 'points',
            displayName: '角数',
            type: PropertyType.number,
            defaultValue: 5.0,
            minValue: 3.0,
            maxValue: 20.0,
            description: '星形的角数',
          ),
          'innerRadius': const PropertyDefinition(
            name: 'innerRadius',
            displayName: '内半径比例',
            type: PropertyType.number,
            defaultValue: 0.5,
            minValue: 0.1,
            maxValue: 0.9,
            description: '内半径与外半径的比例',
          ),
        };
        break;
      default:
        break;
    }

    // 合并基础属性和特定属性
    return {...baseProperties, ...specificProperties};
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! Map<String, dynamic>) return null;

    // 获取形状类型
    final shapeType = element['shapeType'] as String? ?? 'rectangle';

    // 尝试从元素中获取属性值
    final value = element[propertyName];
    if (value != null) return value;

    // 如果没有值，返回默认值
    // 使用特定形状类型的属性定义
    final definitions = getPropertyDefinitions(shapeType);
    return definitions[propertyName]?.defaultValue;
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! Map<String, dynamic>) return;

    // 形状类型相关属性的特殊处理
    switch (propertyName) {
      case 'name':
      case 'shapeType':
        if (value is String) element[propertyName] = value;
        break;
      case 'visible':
      case 'locked':
      case 'fillEnabled':
      case 'strokeEnabled':
      case 'shadowEnabled':
      case 'uniformRadius':
      case 'regularPolygon':
      case 'arrowStart':
      case 'arrowEnd':
        if (value is bool) element[propertyName] = value;
        break;
      case 'width':
      case 'height':
        if (value is num && value > 0) {
          element[propertyName] = value.toDouble();
        }
        break;
      case 'x':
      case 'y':
      case 'endX':
      case 'endY':
      case 'shadowOffsetX':
      case 'shadowOffsetY':
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
      case 'borderRadius':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.0, 50.0);
        }
        break;
      case 'strokeWidth':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.0, 20.0);
        }
        break;
      case 'shadowBlur':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.0, 20.0);
        }
        break;
      case 'sides':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(3.0, 20.0);
        }
        break;
      case 'points':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(3.0, 20.0);
        }
        break;
      case 'innerRadius':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.1, 0.9);
        }
        break;
      case 'startAngle':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(0.0, 360.0);
        }
        break;
      case 'sweepAngle':
        if (value is num) {
          element[propertyName] = value.toDouble().clamp(1.0, 360.0);
        }
        break;
      case 'fillColor':
      case 'strokeColor':
      case 'shadowColor':
        if (value is int) element[propertyName] = value;
        break;
      case 'fillType':
      case 'strokeStyle':
      case 'lineCap':
        if (value is String) element[propertyName] = value;
        break;
    }

    // 处理依赖属性
    switch (propertyName) {
      case 'fillEnabled':
        if (value == false) {
          // 禁用填充时重置填充类型
          element['fillType'] = 'none';
        }
        break;
      case 'strokeEnabled':
        if (value == false) {
          // 禁用描边时重置描边宽度
          element['strokeWidth'] = 0.0;
        }
        break;
      case 'shadowEnabled':
        if (value == false) {
          // 禁用阴影时重置阴影属性
          element['shadowBlur'] = 0.0;
          element['shadowOffsetX'] = 0.0;
          element['shadowOffsetY'] = 0.0;
        }
        break;
    }
  }

  /// 构建属性编辑控件
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
            itemBuilder: (value) => value.toString(),
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
          divisions: (property.maxValue != null && property.minValue != null)
              ? ((property.maxValue! - property.minValue!) * 10).toInt()
              : null,
          suffix: property.unit,
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

  /// 构建形状特定属性
  List<Widget> _buildSpecificProperties(
    String shapeType,
    dynamic element,
    Map<String, PropertyDefinition> definitions,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    switch (shapeType) {
      case 'rectangle':
        return [
          _buildPropertyTile(
              definitions['borderRadius']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['uniformRadius']!, element, onPropertyChanged),
        ];
      case 'circle':
      case 'ellipse':
        return [
          _buildPropertyTile(
              definitions['startAngle']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['sweepAngle']!, element, onPropertyChanged),
        ];
      case 'line':
        return [
          _buildPropertyTile(definitions['endX']!, element, onPropertyChanged),
          _buildPropertyTile(definitions['endY']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['lineCap']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['arrowStart']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['arrowEnd']!, element, onPropertyChanged),
        ];
      case 'polygon':
        return [
          _buildPropertyTile(definitions['sides']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['regularPolygon']!, element, onPropertyChanged),
        ];
      case 'star':
        return [
          _buildPropertyTile(
              definitions['points']!, element, onPropertyChanged),
          _buildPropertyTile(
              definitions['innerRadius']!, element, onPropertyChanged),
        ];
      default:
        return [];
    }
  }

  /// 获取形状类型显示名称
  String _getShapeTypeLabel(String shapeType) {
    switch (shapeType) {
      case 'rectangle':
        return '矩形';
      case 'circle':
        return '圆形';
      case 'ellipse':
        return '椭圆';
      case 'line':
        return '线条';
      case 'polygon':
        return '多边形';
      case 'star':
        return '星形';
      default:
        return '形状';
    }
  }

  /// 检查形状是否有特定属性
  bool _hasSpecificProperties(String shapeType) {
    return ['rectangle', 'circle', 'ellipse', 'line', 'polygon', 'star']
        .contains(shapeType);
  }
}
