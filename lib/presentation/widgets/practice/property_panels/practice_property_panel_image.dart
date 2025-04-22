import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
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

    // 翻转属性
    final flipHorizontal = content['flipHorizontal'] as bool? ?? false;
    final flipVertical = content['flipVertical'] as bool? ?? false;

    // 绘制模式
    final fitMode = content['fitMode'] as String? ?? 'contain';

    return ListView(
      children: [
        // 基本属性面板（放在最上方）
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
                                _updateProperty('opacity', value);
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
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          onPressed: () => _selectImageFromLocal(context),
                          label: const Text('从本地选择'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.collections),
                          onPressed: () {
                            // 从作品选择
                          },
                          label: const Text('从作品选择'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.text_format),
                    onPressed: () {
                      // 从集字中选择
                    },
                    label: const Text('从集字中选择'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
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
                      color: Colors.grey.shade200,
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRect(
                            child: Transform(
                              transform: Matrix4.identity()
                                ..scale(
                                  flipHorizontal ? -1.0 : 1.0,
                                  flipVertical ? -1.0 : 1.0,
                                ),
                              alignment: Alignment.center,
                              child: Image.network(
                                imageUrl,
                                fit: _getFitMode(fitMode),
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.red, size: 40),
                                        const SizedBox(height: 8),
                                        Text(
                                            '加载图片失败: ${error.toString().substring(0, 30)}...'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('没有选择图片',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 适应模式选择
                  const Text('图片适应模式:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFitModeButton('contain', '适应', fitMode),
                      _buildFitModeButton('cover', '填充', fitMode),
                      _buildFitModeButton('fill', '拉伸', fitMode),
                      _buildFitModeButton('none', '原始', fitMode),
                    ],
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
                  const Text('裁剪:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
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
                  const Text('旋转:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
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
                      _buildRotationButton(
                          '+90°',
                          () => _updateProperty(
                              'rotation', (rotation + 90) % 360)),
                      const SizedBox(width: 8.0),
                      _buildRotationButton(
                          '-90°',
                          () => _updateProperty(
                              'rotation', (rotation - 90) % 360)),
                      const SizedBox(width: 8.0),
                      _buildRotationButton(
                          '180°',
                          () => _updateProperty(
                              'rotation', (rotation + 180) % 360)),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 翻转按钮
                  const Text('翻转:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                flipHorizontal ? Colors.blue : null,
                            foregroundColor:
                                flipHorizontal ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'flipHorizontal', !flipHorizontal),
                          label: const Text('水平翻转'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: flipVertical ? Colors.blue : null,
                            foregroundColor: flipVertical ? Colors.white : null,
                          ),
                          onPressed: () => _updateContentProperty(
                              'flipVertical', !flipVertical),
                          label: const Text('垂直翻转'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 应用和重置按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          onPressed: () => _applyTransform(context),
                          label: const Text('应用变换'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          onPressed: () => _resetTransform(context),
                          label: const Text('重置变换'),
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
  void _applyTransform(BuildContext context) {
    // 获取当前变换参数
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    // 通知外部应用变换
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('变换已应用'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 适应模式按钮
  Widget _buildFitModeButton(String mode, String label, String currentMode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: currentMode == mode ? Colors.blue : null,
        foregroundColor: currentMode == mode ? Colors.white : null,
      ),
      onPressed: () => _updateContentProperty('fitMode', mode),
      child: Text(label),
    );
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
    final TextEditingController controller =
        TextEditingController(text: value.toStringAsFixed(0));
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        suffixText: suffix,
      ),
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final newValue = double.tryParse(value);
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  // 旋转按钮
  Widget _buildRotationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // 获取适应模式
  BoxFit _getFitMode(String fitMode) {
    switch (fitMode) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.contain;
    }
  }

  // 重置变换
  void _resetTransform(BuildContext context) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['flipHorizontal'] = false;
    content['flipVertical'] = false;
    content['fitMode'] = 'contain';
    _updateProperty('content', content);
    _updateProperty('rotation', 0.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('变换已重置'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
