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

    return SizedBox(
      width: width,
      height: height,
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

    Widget childWidget;
    switch (type) {
      case 'text':
        childWidget = TextElementRenderer(
          element: child,
          scale: scale,
        );
        break;
      case 'image':
        childWidget = ImageElementRenderer(
          element: child,
          scale: scale,
        );
        break;
      case 'collection':
        childWidget = CollectionElementRenderer(
          element: child,
          scale: scale,
        );
        break;
      case 'group':
        childWidget = GroupElementRenderer(
          element: child,
          scale: scale,
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

    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: rotation * (3.14159265359 / 180),
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.5),
                      width: 1.0,
                    ),
                  )
                : null,
            child: childWidget,
          ),
        ),
      ),
    );
  }
}
