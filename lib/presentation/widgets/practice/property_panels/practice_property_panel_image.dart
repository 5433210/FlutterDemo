import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

/// 图片内容属性面板
class ImagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;

  const ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
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

    // 图片特有属性
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';

    // 裁剪属性
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final cropLeft = (content['cropLeft'] as num?)?.toDouble() ?? 0.0;
    final cropRight = (content['cropRight'] as num?)?.toDouble() ?? 0.0;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '图片内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

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
                        child: _buildNumberField(
                          label: 'X',
                          value: x,
                          onChanged: (value) => _updateProperty('x', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Y',
                          value: y,
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
                        child: _buildNumberField(
                          label: '宽度',
                          value: width,
                          onChanged: (value) => _updateProperty('width', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: '高度',
                          value: height,
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 旋转角度
                  _buildNumberField(
                    label: '旋转',
                    value: rotation,
                    suffix: '°',
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
                  // 透明度滑块
                  const Text('透明度:'),
                  Row(
                    children: [
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Slider(
                              value: opacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              label: '${(opacity * 100).toStringAsFixed(0)}%',
                              onChanged: (value) {
                                setState(() {});
                              },
                              onChangeEnd: (value) {
                                _updateProperty('opacity', value);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${(opacity * 100).toStringAsFixed(0)}%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 图片选择部分
        materialExpansionTile(
          title: const Text('图片选择'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectImageFromLocal(context),
                          child: const Text('选择图片'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 从作品选择
                          },
                          child: const Text('从作品选择'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      // 从集字中选择
                    },
                    child: const Text('从集字中选择'),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图片预览部分
        materialExpansionTile(
          title: const Text('图片预览'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text('加载图片失败'));
                            },
                          )
                        : const Center(child: Text('没有选择图片')),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图片变换部分
        materialExpansionTile(
          title: const Text('图片变换'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 裁剪设置
                  const Text('裁剪:'),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: '上',
                          value: cropTop,
                          onChanged: (value) =>
                              _updateContentProperty('cropTop', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: '下',
                          value: cropBottom,
                          onChanged: (value) =>
                              _updateContentProperty('cropBottom', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: '左',
                          value: cropLeft,
                          onChanged: (value) =>
                              _updateContentProperty('cropLeft', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: _buildNumberField(
                          label: '右',
                          value: cropRight,
                          onChanged: (value) =>
                              _updateContentProperty('cropRight', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 旋转按钮
                  const Text('旋转:'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: '',
                          value: rotation,
                          suffix: '°',
                          onChanged: (value) =>
                              _updateProperty('rotation', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation + 90) % 360),
                        child: const Text('+90°'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation - 90) % 360),
                        child: const Text('-90°'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation + 180) % 360),
                        child: const Text('180°'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 翻转按钮
                  const Text('翻转:'),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateContentProperty(
                              'flipHorizontal',
                              !(content['flipHorizontal'] as bool? ?? false)),
                          child: const Text('水平翻转'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateContentProperty(
                              'flipVertical',
                              !(content['flipVertical'] as bool? ?? false)),
                          child: const Text('垂直翻转'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 应用和重置按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyTransform,
                          child: const Text('应用变换'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _resetTransform,
                          child: const Text('重置变换'),
                        ),
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

  // 应用变换
  void _applyTransform() {
    // 实际应用变换的逻辑应该在这里实现
    // 这里可能需要调用图片处理服务
  }

  // 构建图层选项
  List<DropdownMenuItem<String>> _buildLayerItems() {
    final layers = controller.state.layers;
    return layers.map((layer) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? '图层1';
      return DropdownMenuItem<String>(
        value: layerId,
        child: Text(layerName),
      );
    }).toList();
  }

  // 构建数字输入字段
  Widget _buildNumberField({
    required String label,
    required double value,
    String? suffix,
    required Function(double) onChanged,
  }) {
    // 使用静态变量保存控制器实例，以保持焦点
    final Map<String, TextEditingController> controllers = {};
    final String key = '$label-$value';

    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: value.toStringAsFixed(0));
    } else if (controllers[key]!.text != value.toStringAsFixed(0)) {
      // 只在值变化时更新，避免光标重置
      final selection = controllers[key]!.selection;
      controllers[key]!.text = value.toStringAsFixed(0);

      // 保持原有光标位置
      if (selection.start <= value.toStringAsFixed(0).length &&
          selection.end <= value.toStringAsFixed(0).length) {
        controllers[key]!.selection = selection;
      }
    }

    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        suffixText: suffix,
      ),
      controller: controllers[key],
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final newValue = double.tryParse(value);
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  // 重置变换
  void _resetTransform() {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['flipHorizontal'] = false;
    content['flipVertical'] = false;
    _updateProperty('content', content);
    _updateProperty('rotation', 0.0);
  }

  // 从本地选择图片
  Future<void> _selectImageFromLocal(BuildContext context) async {
    // 调用onSelectImage回调，该回调应该在上层实现文件选择功能
    onSelectImage();
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content[key] = value;
    _updateProperty('content', content);
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
