import 'package:flutter/material.dart';

import '../../../widgets/practice/drag_state_manager.dart';

/// 拖拽预览图层组件
///
/// 该组件提供了一个独立的图层用于在拖拽操作期间显示元素的预览位置，
/// 与实际内容渲染分离，提高拖拽性能
class DragPreviewLayer extends StatefulWidget {
  /// 拖拽状态管理器
  final DragStateManager dragStateManager;

  /// 元素数据列表，用于构建预览
  final List<Map<String, dynamic>> elements;

  /// 自定义元素构建器（可选）
  /// 如果提供，则使用此构建器渲染元素；否则使用默认预览样式
  final Widget Function(
          String elementId, Offset position, Map<String, dynamic> element)?
      elementBuilder;

  const DragPreviewLayer({
    super.key,
    required this.dragStateManager,
    required this.elements,
    this.elementBuilder,
  });

  @override
  State<DragPreviewLayer> createState() => _DragPreviewLayerState();
}

class _DragPreviewLayerState extends State<DragPreviewLayer> {
  @override
  Widget build(BuildContext context) {
    // 如果没有活动的拖拽预览，返回空容器
    if (!widget.dragStateManager.isDragPreviewActive) {
      return const SizedBox.shrink();
    }

    // 获取所有正在拖拽的元素ID
    final draggingElementIds = widget.dragStateManager.draggingElementIds;

    // 创建一个透明层，显示所有拖拽元素的预览
    return RepaintBoundary(
      child: Positioned.fill(
        child: IgnorePointer(
          child: Opacity(
            opacity: DragConfig.dragPreviewOpacity,
            child: Stack(
              children: [
                for (final elementId in draggingElementIds)
                  Builder(
                    builder: (context) {
                      // 获取元素的预览位置
                      final previewPosition = widget.dragStateManager
                          .getElementPreviewPosition(elementId);

                      // 如果没有预览位置，不显示该元素
                      if (previewPosition == null) {
                        return const SizedBox.shrink();
                      }

                      // 查找元素数据
                      final element = widget.elements.firstWhere(
                        (e) => e['id'] == elementId,
                        orElse: () => <String, dynamic>{},
                      );

                      if (element.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // 如果提供了自定义构建器，使用它构建预览
                      if (widget.elementBuilder != null) {
                        return widget.elementBuilder!(
                            elementId, previewPosition, element);
                      }

                      // 否则使用默认预览样式
                      return _buildDefaultPreview(
                          elementId, previewPosition, element);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 移除监听器
    widget.dragStateManager.removeListener(_handleDragStateChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 监听拖拽状态变化
    widget.dragStateManager.addListener(_handleDragStateChange);
  }

  /// 构建默认预览样式
  Widget _buildDefaultPreview(
      String elementId, Offset position, Map<String, dynamic> element) {
    // 提取元素属性
    final elementWidth = (element['width'] as num).toDouble();
    final elementHeight = (element['height'] as num).toDouble();
    final elementRotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final elementType = element['type'] as String;

    // 根据元素类型构建不同的预览样式
    Widget previewContent;

    switch (elementType) {
      case 'text':
        // 简化的文本预览
        previewContent = Container(
          width: elementWidth,
          height: elementHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1.5),
            color: Colors.blue.withOpacity(0.1),
          ),
          child: const Center(
            child: Icon(Icons.text_fields, color: Colors.blue),
          ),
        );
        break;

      case 'image':
        // 简化的图片预览
        previewContent = Container(
          width: elementWidth,
          height: elementHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 1.5),
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Center(
            child: Icon(Icons.image, color: Colors.green),
          ),
        );
        break;

      case 'collection':
        // 简化的集字预览
        previewContent = Container(
          width: elementWidth,
          height: elementHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 1.5),
            color: Colors.orange.withOpacity(0.1),
          ),
          child: const Center(
            child: Icon(Icons.grid_on, color: Colors.orange),
          ),
        );
        break;

      default:
        // 默认预览样式
        previewContent = Container(
          width: elementWidth,
          height: elementHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 1.5),
            color: Colors.purple.withOpacity(0.1),
          ),
        );
    }

    // 应用位置和旋转
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Transform.rotate(
        angle: elementRotation * 3.14159265359 / 180,
        child: previewContent,
      ),
    );
  }

  /// 处理拖拽状态变化
  void _handleDragStateChange() {
    // 只有在拖拽预览活动时才重建组件
    if (widget.dragStateManager.isDragPreviewActive) {
      setState(() {});
    }
  }
}
