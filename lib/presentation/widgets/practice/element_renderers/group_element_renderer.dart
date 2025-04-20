import 'package:flutter/material.dart';

import 'collection_element_renderer.dart';
import 'image_element_renderer.dart';
import 'text_element_renderer.dart';

/// 组合元素渲染器
class GroupElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isSelected;
  final double scale;

  const GroupElementRenderer({
    Key? key,
    required this.element,
    this.isSelected = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = element['content'] as Map<String, dynamic>;
    final List<dynamic> children = content['children'] as List<dynamic>;
    final width = (element['width'] as num).toDouble() * scale;
    final height = (element['height'] as num).toDouble() * scale;

    // 简化组合控件结构，只使用一个Container
    return Container(
      width: width,
      height: height,
      // 如果选中则显示蓝色边框，否则显示灰色边框
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      // 直接使用Stack渲染子元素
      child: Stack(
        clipBehavior: Clip.none,
        children: children.map<Widget>((child) {
          return _buildChildElement(child);
        }).toList(),
      ),
    );
  }

  /// 构建子元素
  Widget _buildChildElement(Map<String, dynamic> child) {
    final String type = child['type'] as String;
    final double x = (child['x'] as num).toDouble() * scale;
    final double y = (child['y'] as num).toDouble() * scale;
    final double width = (child['width'] as num).toDouble() * scale;
    final double height = (child['height'] as num).toDouble() * scale;
    final double rotation = (child['rotation'] as num? ?? 0.0).toDouble();
    final double opacity = (child['opacity'] as num? ?? 1.0).toDouble();

    // 根据不同类型创建不同的渲染器
    Widget childWidget;
    switch (type) {
      case 'text':
        childWidget = TextElementRenderer(
          element: child,
          scale: scale,
          isSelected: isSelected,
        );
        break;
      case 'image':
        childWidget = ImageElementRenderer(
          element: child,
          scale: scale,
          isSelected: isSelected,
        );
        break;
      case 'collection':
        childWidget = CollectionElementRenderer(
          element: child,
          scale: scale,
          isSelected: isSelected,
        );
        break;
      case 'group':
        childWidget = GroupElementRenderer(
          element: child,
          scale: scale,
          isSelected: isSelected,
        );
        break;
      default:
        childWidget = Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.2),
          child: Center(
            child: Text('未知元素类型: $type'),
          ),
        );
    }

    // 使用DecoratedBox来添加边框，这样不会影响元素尺寸和位置
    final decoratedChild = DecoratedBox(
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(
                color: Colors.blue.withOpacity(0.5),
                width: 1.0,
              )
            : Border.all(
                color: Colors.transparent,
                width: 0,
              ),
      ),
      child: childWidget,
    );

    // 简化Positioned结构
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: rotation * (3.14159265359 / 180),
        alignment: Alignment.center,
        child: Opacity(
          opacity: opacity,
          child: decoratedChild,
        ),
      ),
    );
  }
}
