import 'package:flutter/material.dart';

import '../practice_edit_controller.dart';

/// 元素通用属性面板
/// 用于显示元素的通用属性，如名称、ID、图层等
class ElementCommonPropertyPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final PracticeEditController controller;

  const ElementCommonPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = element['name'] as String? ?? '未命名元素';
    final id = element['id'] as String;
    final type = element['type'] as String;
    final layerId = element['layerId'] as String?;
    final isLocked = element['locked'] as bool? ?? false;
    final isHidden = element['hidden'] as bool? ?? false;

    // 获取图层数据
    final layers = controller.state.layers;

    // 获取元素类型显示名称
    String typeDisplayName = '元素';
    switch (type) {
      case 'text':
        typeDisplayName = '文本';
        break;
      case 'image':
        typeDisplayName = '图片';
        break;
      case 'collection':
        typeDisplayName = '集字';
        break;
      case 'group':
        typeDisplayName = '组合';
        break;
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  _getIconForType(type),
                  size: 20.0,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8.0),
                Text(
                  typeDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const Spacer(),
                // 锁定按钮
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked ? Colors.orange : Colors.grey,
                  ),
                  tooltip: isLocked ? '解锁元素' : '锁定元素',
                  onPressed: () => _updateProperty('locked', !isLocked),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20.0,
                ),
                const SizedBox(width: 8.0),
                // 可见性按钮
                IconButton(
                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: isHidden ? Colors.grey : Colors.blue,
                  ),
                  tooltip: isHidden ? '显示元素' : '隐藏元素',
                  onPressed: () => _updateProperty('hidden', !isHidden),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20.0,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 元素名称
            TextField(
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                hintText: '输入元素名称',
              ),
              controller: TextEditingController(text: name),
              onChanged: (value) => _updateProperty('name', value),
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 8.0),

            // 图层选择
            if (layers.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '图层',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                value: layerId,
                items: _buildLayerItems(),
                onChanged: (value) {
                  if (value != null) {
                    _updateProperty('layerId', value);
                  }
                },
                isExpanded: true,
              ),

            // ID显示（只读）
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Text(
                    'ID: ',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      id,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建图层下拉选项
  List<DropdownMenuItem<String>> _buildLayerItems() {
    final layers = controller.state.layers;
    return layers.map((layer) {
      final layerId = layer['id'] as String;
      final layerName = layer['name'] as String? ?? '图层1';
      final isVisible = layer['isVisible'] as bool? ?? true;
      final isLocked = layer['isLocked'] as bool? ?? false;

      // 显示图层状态图标
      Widget icon = Container(width: 0);
      if (!isVisible) {
        icon = const Icon(Icons.visibility_off, size: 16.0, color: Colors.grey);
      } else if (isLocked) {
        icon = const Icon(Icons.lock, size: 16.0, color: Colors.orange);
      }

      return DropdownMenuItem<String>(
        value: layerId,
        child: Row(
          children: [
            Text(layerName),
            const SizedBox(width: 4.0),
            icon,
          ],
        ),
      );
    }).toList();
  }

  // 根据元素类型获取图标
  IconData _getIconForType(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'collection':
        return Icons.font_download;
      case 'group':
        return Icons.group_work;
      default:
        return Icons.crop_square;
    }
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
