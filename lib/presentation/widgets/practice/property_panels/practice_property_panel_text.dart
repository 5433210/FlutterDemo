import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

/// 文本内容属性面板
class TextPropertyPanel extends PracticePropertyPanel {
  // 文本控制器静态变量
  static final TextEditingController _textController = TextEditingController();

  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const TextPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = controller.state.getLayerById(layerId);
    }

    // 文本特有属性
    final text = element['text'] as String? ?? '';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = element['fontFamily'] as String? ?? 'sans-serif';
    final fontColor = element['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        element['backgroundColor'] as String? ?? 'transparent';
    final textAlign = element['textAlign'] as String? ?? 'left';

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '文本内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          title: '几何属性',
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
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 文本设置部分
        materialExpansionTile(
          title: const Text('文本设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本内容
                  const Text('文本内容'),
                  _buildTextContentField(text),

                  const SizedBox(height: 16.0),

                  // 字体设置
                  const Text('字体设置'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '字号',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: fontSize.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateProperty('fontSize', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 这里可以添加更多字体设置控件
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  // 字体族设置
                  DropdownButton<String>(
                    value: fontFamily,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'sans-serif', child: Text('Sans Serif')),
                      DropdownMenuItem(value: 'serif', child: Text('Serif')),
                      DropdownMenuItem(
                          value: 'monospace', child: Text('Monospace')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('fontFamily', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 对齐方式
                  const Text('对齐方式'),
                  ToggleButtons(
                    isSelected: [
                      textAlign == 'left',
                      textAlign == 'center',
                      textAlign == 'right',
                    ],
                    onPressed: (index) {
                      String newAlign;
                      switch (index) {
                        case 0:
                          newAlign = 'left';
                          break;
                        case 1:
                          newAlign = 'center';
                          break;
                        case 2:
                          newAlign = 'right';
                          break;
                        default:
                          newAlign = 'left';
                      }
                      _updateProperty('textAlign', newAlign);
                    },
                    children: const [
                      Icon(Icons.align_horizontal_left),
                      Icon(Icons.align_horizontal_center),
                      Icon(Icons.align_horizontal_right),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建文本内容输入字段，保持焦点并实时更新
  Widget _buildTextContentField(String initialText) {
    // 只在初始值变化时更新控制器，避免光标重置
    if (_textController.text != initialText) {
      // 保存当前光标位置
      final selection = _textController.selection;

      // 更新文本，保持光标位置，并添加安全检查
      try {
        _textController.value = TextEditingValue(
          text: initialText,
          selection: TextSelection(
            baseOffset: selection.baseOffset.clamp(0, initialText.length),
            extentOffset: selection.extentOffset.clamp(0, initialText.length),
          ),
        );
      } catch (e) {
        // 如果控制器已经被销毁，则初始化一个新的
        debugPrint('文本控制器已销毁，初始化新控制器');
      }
    }

    return TextField(
      decoration: const InputDecoration(
        hintText: '输入文本内容',
        border: OutlineInputBorder(),
      ),
      controller: _textController,
      maxLines: 5,
      onChanged: (value) {
        // 实时更新文本内容
        _updateProperty('text', value);
      },
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
