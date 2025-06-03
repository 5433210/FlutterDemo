/// 集字元素属性适配器
/// 用于编辑集字元素的属性，如字符内容、布局、样式、字符图像等
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../canvas/ui/property_panel/widgets/property_widgets.dart';
import 'property_panel_adapter.dart';

/// 集字元素属性适配器
class CollectionPropertyAdapter extends BasePropertyPanelAdapter {
  final WidgetRef ref;

  CollectionPropertyAdapter(this.ref);

  @override
  List<String> get supportedElementTypes => ['collection'];

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    if (selectedElements.isEmpty) {
      return const Center(child: Text('请选择一个集字元素'));
    }

    final element = selectedElements.first;
    final definitions = getPropertyDefinitions('collection');

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
            _buildPropertyTile(
                definitions['width']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['height']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['rotation']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['opacity']!, element, onPropertyChanged),
          ],
        ),

        // 内容设置组
        ExpansionTile(
          title: const Text('内容设置'),
          initiallyExpanded: true,
          children: [
            _buildPropertyTile(
                definitions['characters']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['fontSize']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['fontColor']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['backgroundColor']!, element, onPropertyChanged),
          ],
        ),

        // 布局设置组
        ExpansionTile(
          title: const Text('布局设置'),
          children: [
            _buildPropertyTile(
                definitions['direction']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['flowDirection']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['characterSpacing']!, element, onPropertyChanged),
            _buildPropertyTile(
                definitions['lineSpacing']!, element, onPropertyChanged),
          ],
        ),

        // 字符图像设置组
        ExpansionTile(
          title: const Text('字符图像设置'),
          children: [
            _buildPropertyTile(
                definitions['defaultImageType']!, element, onPropertyChanged),
            _buildCharacterImageEditor(element, onPropertyChanged, context),
          ],
        ),
      ],
    );
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    final definitions = getPropertyDefinitions('collection');
    return definitions[propertyName]?.defaultValue;
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    // 基础属性（所有集字元素通用）
    final baseProperties = <String, PropertyDefinition>{
      'name': const PropertyDefinition(
        name: 'name',
        displayName: '名称',
        type: PropertyType.string,
        defaultValue: '集字内容',
        description: '集字元素的名称',
      ),
      'visible': const PropertyDefinition(
        name: 'visible',
        displayName: '可见',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '集字元素是否可见',
      ),
      'locked': const PropertyDefinition(
        name: 'locked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '集字元素是否锁定编辑',
      ),
      'x': const PropertyDefinition(
        name: 'x',
        displayName: 'X坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '集字元素的X坐标',
      ),
      'y': const PropertyDefinition(
        name: 'y',
        displayName: 'Y坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        description: '集字元素的Y坐标',
      ),
      'width': const PropertyDefinition(
        name: 'width',
        displayName: '宽度',
        type: PropertyType.number,
        defaultValue: 300.0,
        minValue: 10.0,
        description: '集字元素的宽度',
      ),
      'height': const PropertyDefinition(
        name: 'height',
        displayName: '高度',
        type: PropertyType.number,
        defaultValue: 200.0,
        minValue: 10.0,
        description: '集字元素的高度',
      ),
      'rotation': const PropertyDefinition(
        name: 'rotation',
        displayName: '旋转角度',
        type: PropertyType.number,
        defaultValue: 0.0,
        minValue: -360.0,
        maxValue: 360.0,
        description: '集字元素的旋转角度（度）',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        description: '集字元素的透明度',
      ),
    };

    // 集字元素特有属性
    final collectionProperties = <String, PropertyDefinition>{
      'characters': const PropertyDefinition(
        name: 'characters',
        displayName: '字符内容',
        type: PropertyType.text,
        defaultValue: '',
        description: '集字元素的字符内容',
      ),
      'direction': const PropertyDefinition(
        name: 'direction',
        displayName: '排列方向',
        type: PropertyType.select,
        defaultValue: 'horizontal',
        allowedValues: ['horizontal', 'vertical'],
        description: '字符的排列方向',
      ),
      'flowDirection': const PropertyDefinition(
        name: 'flowDirection',
        displayName: '流向',
        type: PropertyType.select,
        defaultValue: 'horizontal',
        allowedValues: ['horizontal', 'vertical'],
        description: '多行文本的流向',
      ),
      'characterSpacing': const PropertyDefinition(
        name: 'characterSpacing',
        displayName: '字符间距',
        type: PropertyType.number,
        defaultValue: 10.0,
        minValue: 0.0,
        description: '字符之间的间距',
      ),
      'lineSpacing': const PropertyDefinition(
        name: 'lineSpacing',
        displayName: '行间距',
        type: PropertyType.number,
        defaultValue: 10.0,
        minValue: 0.0,
        description: '行之间的间距',
      ),
      'fontColor': const PropertyDefinition(
        name: 'fontColor',
        displayName: '字体颜色',
        type: PropertyType.color,
        defaultValue: 0xFF000000,
        description: '字体的颜色',
      ),
      'backgroundColor': const PropertyDefinition(
        name: 'backgroundColor',
        displayName: '背景颜色',
        type: PropertyType.color,
        defaultValue: 0xFFFFFFFF,
        description: '背景的颜色',
      ),
      'fontSize': const PropertyDefinition(
        name: 'fontSize',
        displayName: '字号',
        type: PropertyType.number,
        defaultValue: 24.0,
        minValue: 8.0,
        maxValue: 144.0,
        description: '字体大小',
      ),
      'defaultImageType': const PropertyDefinition(
        name: 'defaultImageType',
        displayName: '默认字形',
        type: PropertyType.select,
        defaultValue: 'square-binary',
        allowedValues: [
          'square-binary',
          'square-transparent',
          'square-outline'
        ],
        description: '默认的字形类型',
      ),
    };

    // 合并所有属性
    return {...baseProperties, ...collectionProperties};
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! Map<String, dynamic>) return null;

    // 处理内容属性 (content 内部的属性)
    if (element.containsKey('content') &&
        element['content'] is Map<String, dynamic>) {
      final content = element['content'] as Map<String, dynamic>;

      // 检查content中是否有该属性
      if (content.containsKey(propertyName)) {
        return content[propertyName];
      }
    }

    // 处理常规属性
    return element[propertyName];
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! Map<String, dynamic>) return;

    // 处理内容属性 (content 内部的属性)
    if (propertyName == 'characters' ||
        propertyName == 'direction' ||
        propertyName == 'flowDirection' ||
        propertyName == 'characterSpacing' ||
        propertyName == 'lineSpacing' ||
        propertyName == 'fontColor' ||
        propertyName == 'backgroundColor' ||
        propertyName == 'fontSize' ||
        propertyName == 'defaultImageType') {
      // 确保 content 属性存在
      if (!element.containsKey('content')) {
        element['content'] = <String, dynamic>{};
      }

      final content = element['content'] as Map<String, dynamic>;

      // 根据属性类型进行适当的转换
      switch (propertyName) {
        case 'characters':
          if (value is String) {
            content[propertyName] = value;

            // 在文本更改时，可能需要更新字符图像信息
            _updateCharacterImagesForNewText(element, value);
          }
          break;
        case 'direction':
        case 'flowDirection':
        case 'defaultImageType':
          if (value is String) content[propertyName] = value;
          break;
        case 'characterSpacing':
        case 'lineSpacing':
        case 'fontSize':
          if (value is num) content[propertyName] = value.toDouble();
          break;
        case 'fontColor':
        case 'backgroundColor':
          if (value is int)
            content[propertyName] = value;
          else if (value is String) content[propertyName] = value;
          break;
      }
    } else {
      // 处理常规属性
      switch (propertyName) {
        case 'name':
          if (value is String) element[propertyName] = value;
          break;
        case 'visible':
        case 'locked':
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
          if (value is num) element[propertyName] = value.toDouble();
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
      }
    }
  }

  // 构建字符图像编辑器
  Widget _buildCharacterImageEditor(
      dynamic element,
      Function(String, String, dynamic) onPropertyChanged,
      BuildContext context) {
    if (element is! Map<String, dynamic> ||
        !element.containsKey('content') ||
        element['content'] is! Map<String, dynamic>) {
      return const SizedBox();
    }

    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (characters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('请先输入字符内容'),
      );
    }

    // 这里只显示简化的控件，完整功能需要在专门的面板中实现
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('字符图像预览 (使用属性面板获得完整功能)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < characters.length; i++)
                if (characters[i] != '\n')
                  _buildCharacterPreview(
                      characters[i], i, element, onPropertyChanged),
            ],
          ),
        ],
      ),
    );
  }

  // 构建单个字符预览
  Widget _buildCharacterPreview(
      String char,
      int index,
      Map<String, dynamic> element,
      Function(String, String, dynamic) onPropertyChanged) {
    final content = element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo = characterImages['$index'] as Map<String, dynamic>?;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 字符文本
          Text(
            char,
            style: const TextStyle(fontSize: 24),
          ),

          // 字符状态指示
          if (imageInfo != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建属性编辑控件
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
      case PropertyType.text:
        return PropertyTextField(
          label: property.displayName,
          value: currentValue?.toString() ?? '',
          onChanged: (value) {
            if (element is Map<String, dynamic> && element.containsKey('id')) {
              onPropertyChanged(element['id'], property.name, value);
            }
          },
          hintText: property.description,
          maxLines: 5,
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
            itemBuilder: (value) {
              // 为下拉选项提供友好的显示名称
              switch (value) {
                case 'horizontal':
                  return '水平';
                case 'vertical':
                  return '垂直';
                case 'square-binary':
                  return '方形二值图';
                case 'square-transparent':
                  return '方形透明图';
                case 'square-outline':
                  return '方形轮廓图';
                default:
                  return value.toString();
              }
            },
          );
        }
        // 没有选项时回退到文本字段
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

  // 在文本更改时更新字符图像信息
  void _updateCharacterImagesForNewText(
      Map<String, dynamic> element, String newText) {
    try {
      final content = element['content'] as Map<String, dynamic>;

      // 获取现有字符图像信息
      Map<String, dynamic> characterImages = {};
      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      }

      // 保留有效的字符图像信息
      final Set<String> validKeys = {};
      for (int i = 0; i < newText.length; i++) {
        validKeys.add('$i');
      }

      // 移除无效的字符图像信息
      final keysToRemove = characterImages.keys
          .where((key) => !validKeys.contains(key))
          .toList();

      for (final key in keysToRemove) {
        characterImages.remove(key);
      }

      // 更新content中的characterImages
      content['characterImages'] = characterImages;
    } catch (e) {
      debugPrint('更新字符图像信息失败: $e');
    }
  }
}
