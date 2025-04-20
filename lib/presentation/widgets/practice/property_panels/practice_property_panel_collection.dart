import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
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
    final direction = element['direction'] as String? ?? 'horizontal';
    final flowDirection =
        element['flowDirection'] as String? ?? 'top-to-bottom';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (element['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (element['letterSpacing'] as num?)?.toDouble() ?? 5.0;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '集字内容属性',
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

        // 书写设置部分
        materialExpansionTile(
          title: const Text('书写设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 书写方向
                  const Text('书写方向'),
                  DropdownButton<String>(
                    value: direction,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'horizontal', child: Text('左往右')),
                      DropdownMenuItem(value: 'vertical', child: Text('右往左')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('direction', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 行间方向
                  const Text('行间方向'),
                  DropdownButton<String>(
                    value: flowDirection,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'top-to-bottom', child: Text('上往下')),
                      DropdownMenuItem(
                          value: 'bottom-to-top', child: Text('下往上')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('flowDirection', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 间距设置
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '行间距',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: TextEditingController(
                              text: lineSpacing.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null) {
                              _updateProperty('lineSpacing', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '字间距',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: TextEditingController(
                              text: letterSpacing.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null) {
                              _updateProperty('letterSpacing', newValue);
                            }
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
                  const Text('汉字内容'),
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
                      // 这里可以添加颜色选择器
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 集字预览（简化版）
                  const Text('集字预览'),
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
