import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_element.dart';
import 'property_panel_base.dart';

/// 组合元素的属性面板
class GroupElementPropertyPanel extends StatelessWidget {
  final GroupElement element;
  final Function(PracticeElement) onElementChanged;
  final VoidCallback? onUngroup;

  const GroupElementPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementChanged,
    this.onUngroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 组合内容元素标题
            Row(
              children: [
                const Text(
                  '组合内容属性',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onUngroup != null)
                  TextButton.icon(
                    icon: const Icon(Icons.splitscreen),
                    label: const Text('取消组合'),
                    onPressed: onUngroup,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 基础属性（位置、大小、旋转、透明度、锁定）
            BasicPropertyPanel(
              element: element,
              onElementChanged: onElementChanged,
            ),

            const SizedBox(height: 16),

            // 组合信息
            const PropertyGroupTitle(title: '组合信息'),

            // 组合内元素数量
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      '元素数量',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text('${element.children.length}个'),
                ],
              ),
            ),
            const Divider(),

            // 组合中的元素类型统计
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      '元素类型',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(_getElementTypesInfo()),
                ],
              ),
            ),
            const Divider(),

            // 组合中各元素列表
            const PropertyGroupTitle(title: '包含的元素'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: element.children.length,
              itemBuilder: (context, index) {
                final child = element.children[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: _getElementTypeIcon(child.type),
                    title: Text(_getElementTitle(child)),
                    subtitle: Text(
                        '位置: (${child.x.toInt()}, ${child.y.toInt()}) '
                        '大小: ${child.width.toInt()}x${child.height.toInt()} '
                        '旋转: ${child.rotation.toInt()}°'),
                    trailing: Text('${index + 1}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 获取元素标题
  String _getElementTitle(PracticeElement element) {
    switch (element.type) {
      case 'text':
        final textElement = element as TextElement;
        return '文本: ${textElement.text.length > 10 ? '${textElement.text.substring(0, 10)}...' : textElement.text}';
      case 'image':
        final imageElement = element as ImageElement;
        final fileName = imageElement.imageUrl.split('/').last;
        return '图片: ${fileName.isEmpty ? '未命名' : fileName}';
      case 'collection':
        final collectionElement = element as CollectionElement;
        return '集字: ${collectionElement.characters.length > 10 ? collectionElement.characters.substring(0, 10) + '...' : collectionElement.characters}';
      case 'group':
        final groupElement = element as GroupElement;
        return '组合(${groupElement.children.length}个元素)';
      default:
        return '未知元素';
    }
  }

  // 根据元素类型获取图标
  Widget _getElementTypeIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'text':
        iconData = Icons.text_fields;
        iconColor = Colors.blue;
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      case 'collection':
        iconData = Icons.collections;
        iconColor = Colors.orange;
        break;
      case 'group':
        iconData = Icons.group_work;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }

  // 获取组合中元素类型统计信息
  String _getElementTypesInfo() {
    final types = <String, int>{};

    for (final child in element.children) {
      types[child.type] = (types[child.type] ?? 0) + 1;
    }

    final result = <String>[];
    types.forEach((type, count) {
      result.add('$type: $count');
    });

    return result.join('、');
  }
}
