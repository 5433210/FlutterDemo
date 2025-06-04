/// 文本元素属性面板适配器
library;

import 'package:flutter/material.dart';

import '../adapters/property_panel_adapter.dart';

/// 文本元素属性面板适配器
class TextPropertyPanelAdapter extends BasePropertyPanelAdapter {
  @override
  List<String> get supportedElementTypes => ['text', 'collection'];

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    if (selectedElements.isEmpty) {
      return const Center(
        child: Text('请选择文本元素'),
      );
    }

    if (selectedElements.length == 1) {
      // 单个元素编辑
      return _buildSingleTextEditor(
        context,
        selectedElements.first,
        onPropertyChanged,
        config ?? const PropertyPanelConfig(),
      );
    } else {
      // 批量编辑
      return _buildBatchTextEditor(
        context,
        selectedElements,
        onPropertyChanged,
        config ?? const PropertyPanelConfig(),
      );
    }
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    final definition = getPropertyDefinitions('text')[propertyName];
    return definition?.defaultValue;
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    return {
      'text': const PropertyDefinition(
        name: 'text',
        displayName: '文本内容',
        type: PropertyType.string,
        defaultValue: '',
        isRequired: true,
        description: '显示的文本内容',
      ),
      'fontSize': const PropertyDefinition(
        name: 'fontSize',
        displayName: '字体大小',
        type: PropertyType.number,
        defaultValue: 16.0,
        minValue: 8.0,
        maxValue: 72.0,
        unit: 'px',
        description: '文本的字体大小',
      ),
      'fontColor': const PropertyDefinition(
        name: 'fontColor',
        displayName: '字体颜色',
        type: PropertyType.color,
        defaultValue: '#000000',
        description: '文本的颜色',
      ),
      'fontFamily': const PropertyDefinition(
        name: 'fontFamily',
        displayName: '字体',
        type: PropertyType.select,
        defaultValue: 'SourceHanSans',
        allowedValues: [
          'SourceHanSans',
          'SourceHanSerif',
          'SimSun',
          'SimHei',
          'KaiTi',
          'FangSong',
        ],
        description: '文本使用的字体',
      ),
      'fontWeight': const PropertyDefinition(
        name: 'fontWeight',
        displayName: '字体粗细',
        type: PropertyType.select,
        defaultValue: 'normal',
        allowedValues: [
          'normal',
          'bold',
          'w100',
          'w200',
          'w300',
          'w400',
          'w500',
          'w600',
          'w700',
          'w800',
          'w900'
        ],
        description: '文本的粗细程度',
      ),
      'textAlign': const PropertyDefinition(
        name: 'textAlign',
        displayName: '文本对齐',
        type: PropertyType.select,
        defaultValue: 'left',
        allowedValues: ['left', 'center', 'right', 'justify'],
        description: '文本的对齐方式',
      ),
      'letterSpacing': const PropertyDefinition(
        name: 'letterSpacing',
        displayName: '字间距',
        type: PropertyType.number,
        defaultValue: 0.0,
        minValue: -5.0,
        maxValue: 10.0,
        unit: 'px',
        isAdvanced: true,
        description: '字符之间的间距',
      ),
      'lineHeight': const PropertyDefinition(
        name: 'lineHeight',
        displayName: '行高',
        type: PropertyType.number,
        defaultValue: 1.2,
        minValue: 0.8,
        maxValue: 3.0,
        isAdvanced: true,
        description: '文本的行高倍数',
      ),
      'x': const PropertyDefinition(
        name: 'x',
        displayName: 'X 坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        unit: 'px',
        description: '元素的X坐标位置',
      ),
      'y': const PropertyDefinition(
        name: 'y',
        displayName: 'Y 坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
        unit: 'px',
        description: '元素的Y坐标位置',
      ),
      'width': const PropertyDefinition(
        name: 'width',
        displayName: '宽度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 10.0,
        unit: 'px',
        description: '元素的宽度',
      ),
      'height': const PropertyDefinition(
        name: 'height',
        displayName: '高度',
        type: PropertyType.number,
        defaultValue: 30.0,
        minValue: 10.0,
        unit: 'px',
        description: '元素的高度',
      ),
      'rotation': const PropertyDefinition(
        name: 'rotation',
        displayName: '旋转角度',
        type: PropertyType.number,
        defaultValue: 0.0,
        minValue: -360.0,
        maxValue: 360.0,
        unit: '°',
        isAdvanced: true,
        description: '元素的旋转角度',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.slider,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        isAdvanced: true,
        description: '元素的透明度',
      ),
      'isLocked': const PropertyDefinition(
        name: 'isLocked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '是否锁定元素不可编辑',
      ),
      'isVisible': const PropertyDefinition(
        name: 'isVisible',
        displayName: '可见',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '是否显示元素',
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is Map<String, dynamic>) {
      // 处理旧格式的元素数据
      switch (propertyName) {
        case 'text':
          return element['text'] ?? element['content']?['text'];
        case 'fontSize':
          return element['fontSize'] ?? element['content']?['fontSize'];
        case 'fontColor':
          return element['fontColor'] ?? element['content']?['fontColor'];
        case 'fontFamily':
          return element['fontFamily'] ?? element['content']?['fontFamily'];
        case 'x':
          return element['x'] ?? element['bounds']?['left'];
        case 'y':
          return element['y'] ?? element['bounds']?['top'];
        case 'width':
          return element['width'] ?? element['bounds']?['width'];
        case 'height':
          return element['height'] ?? element['bounds']?['height'];
        default:
          return element[propertyName];
      }
    }
    return null;
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is Map<String, dynamic>) {
      // 处理旧格式的元素数据
      switch (propertyName) {
        case 'text':
          if (element['content'] != null) {
            element['content']['text'] = value;
          } else {
            element['text'] = value;
          }
          break;
        case 'fontSize':
          if (element['content'] != null) {
            element['content']['fontSize'] = value;
          } else {
            element['fontSize'] = value;
          }
          break;
        case 'fontColor':
          if (element['content'] != null) {
            element['content']['fontColor'] = value;
          } else {
            element['fontColor'] = value;
          }
          break;
        case 'x':
          element['x'] = value;
          if (element['bounds'] != null) {
            element['bounds']['left'] = value;
          }
          break;
        case 'y':
          element['y'] = value;
          if (element['bounds'] != null) {
            element['bounds']['top'] = value;
          }
          break;
        case 'width':
          element['width'] = value;
          if (element['bounds'] != null) {
            element['bounds']['width'] = value;
          }
          break;
        case 'height':
          element['height'] = value;
          if (element['bounds'] != null) {
            element['bounds']['height'] = value;
          }
          break;
        default:
          element[propertyName] = value;
      }
    }
  }

  Widget _buildAdvancedPropertiesEditor(
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('高级属性', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 透明度滑块
            Row(
              children: [
                const Expanded(flex: 2, child: Text('透明度')),
                Expanded(
                  flex: 3,
                  child: Slider(
                    value: (getPropertyValue(element, 'opacity') ?? 1.0)
                        .toDouble(),
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label:
                        '${((getPropertyValue(element, 'opacity') ?? 1.0) * 100).round()}%',
                    onChanged: (value) {
                      onPropertyChanged(element['id'] ?? '', 'opacity', value);
                    },
                  ),
                ),
              ],
            ),

            // 旋转角度
            Row(
              children: [
                const Expanded(flex: 2, child: Text('旋转角度')),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: (getPropertyValue(element, 'rotation') ?? 0.0)
                        .toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: '°',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final rotation = double.tryParse(value) ?? 0.0;
                      onPropertyChanged(
                          element['id'] ?? '', 'rotation', rotation);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchTextEditor(
    BuildContext context,
    List<dynamic> elements,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig config,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '批量编辑 (${elements.length} 个元素)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('修改的属性将应用到所有选中的文本元素'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _startBatchEdit(elements, onPropertyChanged),
                  child: const Text('开始批量编辑'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontPropertiesEditor(
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('字体属性', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 字体大小
            Row(
              children: [
                const Expanded(flex: 2, child: Text('字体大小')),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue:
                        (getPropertyValue(element, 'fontSize') ?? 16.0)
                            .toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: 'px',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final fontSize = double.tryParse(value) ?? 16.0;
                      onPropertyChanged(
                          element['id'] ?? '', 'fontSize', fontSize);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 字体选择
            Row(
              children: [
                const Expanded(flex: 2, child: Text('字体')),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value:
                        getPropertyValue(element, 'fontFamily')?.toString() ??
                            'SourceHanSans',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'sans-serif',
                      'SourceHanSans',
                      'SourceHanSerif',
                      'SimSun',
                      'SimHei',
                      'KaiTi',
                      'FangSong'
                    ]
                        .map((font) =>
                            DropdownMenuItem(value: font, child: Text(font)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onPropertyChanged(
                            element['id'] ?? '', 'fontFamily', value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionEditor(
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('位置和大小', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue:
                        (getPropertyValue(element, 'x') ?? 0.0).toString(),
                    decoration: const InputDecoration(
                      labelText: 'X',
                      border: OutlineInputBorder(),
                      suffixText: 'px',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final x = double.tryParse(value) ?? 0.0;
                      onPropertyChanged(element['id'] ?? '', 'x', x);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        (getPropertyValue(element, 'y') ?? 0.0).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Y',
                      border: OutlineInputBorder(),
                      suffixText: 'px',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final y = double.tryParse(value) ?? 0.0;
                      onPropertyChanged(element['id'] ?? '', 'y', y);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: (getPropertyValue(element, 'width') ?? 100.0)
                        .toString(),
                    decoration: const InputDecoration(
                      labelText: '宽度',
                      border: OutlineInputBorder(),
                      suffixText: 'px',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final width = double.tryParse(value) ?? 100.0;
                      onPropertyChanged(element['id'] ?? '', 'width', width);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: (getPropertyValue(element, 'height') ?? 30.0)
                        .toString(),
                    decoration: const InputDecoration(
                      labelText: '高度',
                      border: OutlineInputBorder(),
                      suffixText: 'px',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final height = double.tryParse(value) ?? 30.0;
                      onPropertyChanged(element['id'] ?? '', 'height', height);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleTextEditor(
    BuildContext context,
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig config,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基础属性
        _buildTextContentEditor(element, onPropertyChanged),
        const SizedBox(height: 16),
        _buildFontPropertiesEditor(element, onPropertyChanged),
        const SizedBox(height: 16),
        _buildPositionEditor(element, onPropertyChanged),

        // 高级属性
        if (config.showAdvancedProperties) ...[
          const SizedBox(height: 16),
          _buildAdvancedPropertiesEditor(element, onPropertyChanged),
        ],
      ],
    );
  }

  Widget _buildTextContentEditor(
    dynamic element,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文本内容', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: getPropertyValue(element, 'text')?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: '文本',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              onChanged: (value) {
                onPropertyChanged(element['id'] ?? '', 'text', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startBatchEdit(
    List<dynamic> elements,
    Function(String elementId, String property, dynamic value)
        onPropertyChanged,
  ) {
    // 批量编辑的具体实现
    // 这里可以打开一个对话框或切换到批量编辑模式
  }
}
