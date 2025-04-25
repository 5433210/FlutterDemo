import 'package:flutter/material.dart';

import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

/// 集字内容属性面板
class CollectionPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;

  const CollectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
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

    // 集字特有属性
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    return ListView(
      children: [
        // 基本属性部分 (放在最顶部)
        ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        materialExpansionTile(
          title: const Text('几何属性'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // X和Y位置
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: 'X',
                          value: x,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('x', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: 'Y',
                          value: y,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('y', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 宽度和高度
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: '宽度',
                          value: width,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) => _updateProperty('width', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: '高度',
                          value: height,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 旋转角度
                  EditableNumberField(
                    label: '旋转',
                    value: rotation,
                    suffix: '°',
                    min: -360,
                    max: 360,
                    decimalPlaces: 1,
                    onChanged: (value) => _updateProperty('rotation', value),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 视觉属性部分
        materialExpansionTile(
          title: const Text('视觉设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 透明度
                  const Text('透明度:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(opacity * 100).round()}%',
                          onChanged: (value) {
                            _updateProperty('opacity', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '透明度',
                          value: opacity * 100, // 转换为百分比
                          suffix: '%',
                          min: 0,
                          max: 100,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            // 转换回 0-1 范围
                            _updateProperty('opacity', value / 100);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 内边距设置
                  const Text('内边距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: padding,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${padding.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '内边距',
                          value: padding,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 内容设置部分
        materialExpansionTile(
          title: const Text('内容设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 汉字内容
                  const Text('汉字内容:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '输入要展示的汉字',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: characters),
                    maxLines: 3,
                    onChanged: (value) {
                      onUpdateChars(value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 集字预览（简化版）
                  const Text('集字预览:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount:
                          characters.isEmpty ? 0 : characters.characters.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              characters.characters.elementAt(index),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 字号设置
                  const Text('字号:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: fontSize,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${fontSize.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '字号',
                          value: fontSize,
                          suffix: 'px',
                          min: 1,
                          max: 200,
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距设置
                  const Text('字间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: letterSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${letterSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '字间距',
                          value: letterSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 行间距设置
                  const Text('行间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: lineSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${lineSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '行间距',
                          value: lineSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 水平对齐方式
                  const Text('水平对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        textAlign == 'left',
                        textAlign == 'center',
                        textAlign == 'right',
                        textAlign == 'justify',
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
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'left';
                        }
                        _updateContentProperty('textAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_left),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_right),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  const Text('垂直对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        verticalAlign == 'top',
                        verticalAlign == 'middle',
                        verticalAlign == 'bottom',
                        verticalAlign == 'justify',
                      ],
                      onPressed: (index) {
                        String newAlign;
                        switch (index) {
                          case 0:
                            newAlign = 'top';
                            break;
                          case 1:
                            newAlign = 'middle';
                            break;
                          case 2:
                            newAlign = 'bottom';
                            break;
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'top';
                        }
                        _updateContentProperty('verticalAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_top),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_bottom),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 书写方向
                  const Text('书写方向:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildWritingModeButton(
                        mode: 'horizontal-l',
                        label: '横排左书',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_l_to_r,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-r',
                        label: '竖排右书',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_r_to_l,
                      ),
                      _buildWritingModeButton(
                        mode: 'horizontal-r',
                        label: '横排右书',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_left,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-l',
                        label: '竖排左书',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_right,
                      ),
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

  // 构建书写模式按钮
  Widget _buildWritingModeButton({
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: () {
        _updateContentProperty('writingMode', mode);
      },
    );
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    final content = Map<String, dynamic>.from(
        element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
