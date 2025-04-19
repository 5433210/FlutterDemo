import 'package:flutter/material.dart';

import 'element_renderers/collection_element_renderer.dart';
import 'element_renderers/group_element_renderer.dart';
import 'element_renderers/image_element_renderer.dart';
import 'element_renderers/text_element_renderer.dart';

/// 元素渲染器主类，负责根据元素类型选择合适的渲染器
class ElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isSelected;
  final bool isEditing;
  final Function(String)? onElementTap;
  final Function(String)? onElementDoubleTap;
  final Function(String, double, double)? onElementDragEnd;
  final double scale;

  const ElementRenderer({
    Key? key,
    required this.element,
    this.isSelected = false,
    this.isEditing = false,
    this.onElementTap,
    this.onElementDoubleTap,
    this.onElementDragEnd,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String elementType = element['type'] as String;
    final String elementId = element['id'] as String;
    final double x = (element['x'] as num).toDouble() * scale;
    final double y = (element['y'] as num).toDouble() * scale;
    final double width = (element['width'] as num).toDouble() * scale;
    final double height = (element['height'] as num).toDouble() * scale;
    final double rotation = (element['rotation'] as num? ?? 0.0).toDouble();
    final double opacity = (element['opacity'] as num? ?? 1.0).toDouble();

    // 根据元素类型选择渲染器
    Widget elementWidget;
    switch (elementType) {
      case 'text':
        elementWidget = TextElementRenderer(
          element: element,
          isEditing: isEditing && isSelected,
          scale: scale,
        );
        break;
      case 'image':
        elementWidget = ImageElementRenderer(
          element: element,
          scale: scale,
        );
        break;
      case 'collection':
        elementWidget = CollectionElementRenderer(
          element: element,
          scale: scale,
        );
        break;
      case 'group':
        elementWidget = GroupElementRenderer(
          element: element,
          isSelected: isSelected,
          scale: scale,
        );
        break;
      default:
        elementWidget = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey.withOpacity(0.2),
          ),
          child: Center(
            child: Text('未知元素类型: $elementType'),
          ),
        );
    }

    // 应用位置、大小、旋转和不透明度
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation * (3.14159265359 / 180), // 角度转弧度
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: () => onElementTap?.call(elementId),
            onDoubleTap: () => onElementDoubleTap?.call(elementId),
            onPanEnd: (details) {
              // 处理移动结束事件
              if (onElementDragEnd != null && isSelected) {
                onElementDragEnd!.call(
                  elementId,
                  details.velocity.pixelsPerSecond.dx,
                  details.velocity.pixelsPerSecond.dy,
                );
              }
            },
            child: Container(
              width: width,
              height: height,
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 2.0 / scale,
                      ),
                    )
                  : null,
              child: elementWidget,
            ),
          ),
        ),
      ),
    );
  }
}
