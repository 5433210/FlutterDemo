import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';
import 'practice_property_panel_base.dart';

/// 图层属性面板
class LayerPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const LayerPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final name = layer['name'] as String? ?? '图层1';
    final visible = layer['visible'] as bool? ?? true;
    final locked = layer['locked'] as bool? ?? false;
    final opacity = (layer['opacity'] as num?)?.toDouble() ?? 1.0;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '图层属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 基本属性
        materialExpansionTile(
          title: const Text('基本属性'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图层名称
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '图层名称',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: name),
                    onChanged: (value) {
                      _updateProperty('name', value);
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // 可见性
                  Row(
                    children: [
                      Checkbox(
                        value: visible,
                        onChanged: (value) {
                          if (value != null) {
                            _updateProperty('visible', value);
                          }
                        },
                      ),
                      const Text('可见'),
                    ],
                  ),

                  // 锁定
                  Row(
                    children: [
                      Checkbox(
                        value: locked,
                        onChanged: (value) {
                          if (value != null) {
                            _updateProperty('locked', value);
                          }
                        },
                      ),
                      const Text('锁定'),
                    ],
                  ),

                  // 透明度
                  const Text('透明度'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(opacity * 100).toStringAsFixed(0)}%',
                          onChanged: (value) {
                            _updateProperty('opacity', value);
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

        // 图层操作
        materialExpansionTile(
          title: const Text('图层操作'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图层顺序
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _moveLayer('up'),
                        child: const Text('上移'),
                      ),
                      ElevatedButton(
                        onPressed: () => _moveLayer('down'),
                        child: const Text('下移'),
                      ),
                      ElevatedButton(
                        onPressed: () => _moveLayer('top'),
                        child: const Text('置顶'),
                      ),
                      ElevatedButton(
                        onPressed: () => _moveLayer('bottom'),
                        child: const Text('置底'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 图层管理
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _duplicateLayer,
                        child: const Text('复制图层'),
                      ),
                      ElevatedButton(
                        onPressed: _deleteLayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('删除图层'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图层内容
        materialExpansionTile(
          title: const Text('图层内容'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图层元素列表
                  const Text('图层元素'),
                  const SizedBox(height: 8.0),
                  _buildLayerElementsList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建图层元素列表
  Widget _buildLayerElementsList() {
    // 使用 controller.state 中的元素列表
    final allElements = controller.state.currentPageElements;
    final elements = allElements
        .where((element) => element['layerId'] == layer['id'])
        .toList();

    if (elements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('此图层没有元素'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final element = elements[index];
        final type = element['type'] as String? ?? 'unknown';
        final id = element['id'] as String;

        // 根据元素类型显示不同的图标
        IconData iconData;
        switch (type) {
          case 'text':
            iconData = Icons.text_fields;
            break;
          case 'image':
            iconData = Icons.image;
            break;
          case 'collection':
            iconData = Icons.collections;
            break;
          case 'group':
            iconData = Icons.group_work;
            break;
          default:
            iconData = Icons.question_mark;
        }

        return ListTile(
          leading: Icon(iconData),
          title: Text('$type ${index + 1}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _toggleElementVisibility(id),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteElement(id),
              ),
            ],
          ),
          onTap: () => _selectElement(id),
        );
      },
    );
  }

  // 删除元素
  void _deleteElement(String elementId) {
    controller.deleteElement(elementId);
  }

  // 删除图层
  void _deleteLayer() {
    controller.deleteLayer(layer['id'] as String);
  }

  // 复制图层
  void _duplicateLayer() {
    // 实现复制图层逻辑
    final layerId = layer['id'] as String;
    final layerIndex =
        controller.state.layers.indexWhere((l) => l['id'] == layerId);

    if (layerIndex < 0) return;

    // 复制图层
    final originalLayer = controller.state.layers[layerIndex];
    final newLayer =
        Map<String, dynamic>.from(originalLayer as Map<String, dynamic>);

    // 生成新的ID和名称
    newLayer['id'] = '${layerId}_copy';
    newLayer['name'] = '${newLayer['name']} 复制';

    // 添加到图层列表
    controller.state.layers.add(newLayer);

    // 标记为未保存状态
    controller.state.hasUnsavedChanges = true;
  }

  // 移动图层
  void _moveLayer(String direction) {
    // 实现图层移动逻辑
    final layerId = layer['id'] as String;
    final layers = controller.state.layers;
    final index = layers.indexWhere((l) => l['id'] == layerId);

    if (index < 0) return;

    if (direction == 'up' && index > 0) {
      // 上移
      final temp = layers[index];
      layers[index] = layers[index - 1];
      layers[index - 1] = temp;
      // 标记为未保存状态
      controller.state.hasUnsavedChanges = true;
      // 通知界面更新
    } else if (direction == 'down' && index < layers.length - 1) {
      // 下移
      final temp = layers[index];
      layers[index] = layers[index + 1];
      layers[index + 1] = temp;
      // 标记为未保存状态
      controller.state.hasUnsavedChanges = true;
    }
  }

  // 选择元素
  void _selectElement(String elementId) {
    controller.selectElement(elementId);
  }

  // 切换元素可见性
  void _toggleElementVisibility(String elementId) {
    // 实现元素可见性切换逻辑
    final element = controller.state.getElementById(elementId);
    if (element != null) {
      // 假设元素有 isVisible 属性
      final isVisible = element['isVisible'] as bool? ?? true;
      element['isVisible'] = !isVisible;
      controller.state.hasUnsavedChanges = true;
    }
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onLayerPropertiesChanged(updates);
  }
}
