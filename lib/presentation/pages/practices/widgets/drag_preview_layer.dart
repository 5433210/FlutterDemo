import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/element_snapshot.dart';
import 'drag_operation_manager.dart';

/// 拖拽预览图层组件
///
/// 该组件提供了一个独立的图层用于在拖拽操作期间显示元素的预览位置，
/// 与实际内容渲染分离，提高拖拽性能
class DragPreviewLayer extends StatefulWidget {
  /// 拖拽状态管理器
  final DragStateManager dragStateManager;

  /// 拖拽操作管理器（可选，提供快照支持）
  final DragOperationManager? dragOperationManager;

  /// 元素数据列表，用于构建预览
  final List<Map<String, dynamic>> elements;

  /// 自定义元素构建器（可选）
  /// 如果提供，则使用此构建器渲染元素；否则使用默认预览样式
  final Widget Function(
          String elementId, Offset position, Map<String, dynamic> element)?
      elementBuilder;

  /// 是否优先使用ElementSnapshot系统
  final bool useSnapshotSystem;

  const DragPreviewLayer({
    super.key,
    required this.dragStateManager,
    required this.elements,
    this.dragOperationManager,
    this.elementBuilder,
    this.useSnapshotSystem = true,
  });

  @override
  State<DragPreviewLayer> createState() => _DragPreviewLayerState();
}

class _DragPreviewLayerState extends State<DragPreviewLayer> {
  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 DragPreviewLayer: build() 开始');
    debugPrint(
        '   isDragPreviewActive: ${widget.dragStateManager.isDragPreviewActive}');
    debugPrint('   isDragging: ${widget.dragStateManager.isDragging}');
    debugPrint(
        '   draggingElementIds: ${widget.dragStateManager.draggingElementIds}');

    // 如果没有活动的拖拽预览，返回空容器
    if (!widget.dragStateManager.isDragPreviewActive) {
      debugPrint('🎯 DragPreviewLayer: ❌ 没有活动的拖拽预览，返回空容器');
      return const SizedBox.shrink();
    }

    // 获取所有正在拖拽的元素ID
    final draggingElementIds = widget.dragStateManager.draggingElementIds;
    debugPrint('🎯 DragPreviewLayer: 构建预览层，拖拽元素: $draggingElementIds');

    // 创建一个透明层，显示所有拖拽元素的预览
    return RepaintBoundary(
      child: Stack(
        children: [
          // 使用IgnorePointer包装整个预览层，避免干扰用户交互
          IgnorePointer(
            child: Opacity(
              opacity: DragConfig.dragPreviewOpacity,
              child: Stack(
                children: [
                  for (final elementId in draggingElementIds)
                    Builder(
                      builder: (context) {
                        debugPrint('🎯 DragPreviewLayer: 构建元素 $elementId 的预览');

                        // 尝试使用ElementSnapshot系统获取预览（如果可用）
                        if (widget.useSnapshotSystem &&
                            widget.dragOperationManager != null) {
                          final snapshot = widget.dragOperationManager!
                              .getSnapshotForElement(elementId);
                          if (snapshot != null) {
                            debugPrint(
                                '🎯 DragPreviewLayer: 使用快照预览元素 $elementId');
                            return _buildSnapshotPreview(elementId, snapshot);
                          }
                        }

                        // 获取元素的预览位置
                        final previewPosition = widget.dragStateManager
                            .getElementPreviewPosition(elementId);

                        // 如果没有预览位置，不显示该元素
                        if (previewPosition == null) {
                          debugPrint(
                              '🎯 DragPreviewLayer: 元素 $elementId 没有预览位置');
                          return const SizedBox.shrink();
                        }

                        debugPrint(
                            '🎯 DragPreviewLayer: 元素 $elementId 预览位置: $previewPosition');

                        // 查找元素数据
                        final element = widget.elements.firstWhere(
                          (e) => e['id'] == elementId,
                          orElse: () => <String, dynamic>{},
                        );

                        if (element.isEmpty) {
                          debugPrint(
                              '🎯 DragPreviewLayer: 元素 $elementId 数据未找到');
                          return const SizedBox.shrink();
                        }

                        // 如果提供了自定义构建器，使用它构建预览
                        if (widget.elementBuilder != null) {
                          debugPrint(
                              '🎯 DragPreviewLayer: 使用自定义构建器预览元素 $elementId');
                          return widget.elementBuilder!(
                              elementId, previewPosition, element);
                        }

                        // 否则使用默认预览样式
                        debugPrint(
                            '🎯 DragPreviewLayer: 使用默认样式预览元素 $elementId');
                        return _buildDefaultPreview(
                            elementId, previewPosition, element);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
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
    _logSnapshotAvailability();
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

    // 确保预览尺寸不小于最小值，确保视觉可见性
    final displayWidth = math.max(elementWidth, 20.0);
    final displayHeight = math.max(elementHeight, 20.0);

    // 为超小元素添加更明显的视觉反馈
    final bool isVerySmall = elementWidth < 30.0 || elementHeight < 30.0;
    final bool isExtremelySmall = elementWidth < 15.0 || elementHeight < 15.0;

    // 根据元素尺寸调整边框宽度和透明度
    final borderWidth = isExtremelySmall ? 3.0 : (isVerySmall ? 2.5 : 1.5);
    final opacity = isExtremelySmall ? 0.2 : 0.1;

    // 根据元素类型构建不同的预览样式
    Widget previewContent;

    switch (elementType) {
      case 'text':
        // 简化的文本预览
        previewContent = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: borderWidth),
            color: Colors.blue.withOpacity(opacity),
          ),
          child: Center(
            child: Icon(
              Icons.text_fields,
              color: Colors.blue,
              size: isVerySmall
                  ? math.min(displayWidth, displayHeight) * 0.6
                  : null,
            ),
          ),
        );
        break;

      case 'image':
        // 简化的图片预览
        previewContent = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: borderWidth),
            color: Colors.green.withOpacity(opacity),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              color: Colors.green,
              size: isVerySmall
                  ? math.min(displayWidth, displayHeight) * 0.6
                  : null,
            ),
          ),
        );
        break;

      case 'collection':
        // 简化的集字预览
        previewContent = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: borderWidth),
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
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: borderWidth),
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

  /// 使用ElementSnapshot构建高性能预览
  Widget _buildSnapshotPreview(String elementId, ElementSnapshot snapshot) {
    // 从快照获取位置
    final x = (snapshot.properties['x'] as num).toDouble();
    final y = (snapshot.properties['y'] as num).toDouble();
    final position = Offset(x, y);

    // 如果快照有缓存的Widget，优先使用它
    if (snapshot.cachedWidget != null) {
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: snapshot.cachedWidget!,
      );
    }

    // 根据元素类型构建不同的预览
    final elementType = snapshot.elementType;
    final width = snapshot.size.width;
    final height = snapshot.size.height;

    // 确保预览尺寸不小于最小值，确保视觉可见性
    final displayWidth = math.max(width, 20.0);
    final displayHeight = math.max(height, 20.0);

    // 为超小元素添加视觉反馈
    final bool isVerySmall = width < 30.0 || height < 30.0;
    final borderWidth = isVerySmall ? 2.5 : 1.5;

    Widget child;
    switch (elementType) {
      case 'text':
        final text = snapshot.properties['text'] as String? ?? '';
        final fontSize =
            (snapshot.properties['fontSize'] as num?)?.toDouble() ?? 14.0;
        child = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.blue.withOpacity(0.7), width: borderWidth),
            color: Colors.white.withOpacity(0.9),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        );
        break;
      case 'image':
        child = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.green.withOpacity(0.7), width: borderWidth),
            color: Colors.white.withOpacity(0.9),
          ),
          child: const Icon(Icons.image, color: Colors.green),
        );
        break;
      default:
        child = Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.purple.withOpacity(0.7), width: borderWidth),
            color: Colors.white.withOpacity(0.9),
          ),
          child: Center(
            child: Text(
              elementType,
              style: const TextStyle(color: Colors.purple),
            ),
          ),
        );
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: child,
    );
  }

  /// 处理拖拽状态变化
  void _handleDragStateChange() {
    debugPrint('🔄 DragPreviewLayer: 拖拽状态变化');
    debugPrint(
        '   isDragPreviewActive: ${widget.dragStateManager.isDragPreviewActive}');
    debugPrint('   isDragging: ${widget.dragStateManager.isDragging}');

    // 在任何拖拽状态变化时都重建组件，以确保正确的显示/隐藏行为
    if (mounted) {
      setState(() {});
    }
  }

  /// 记录快照系统的可用性
  void _logSnapshotAvailability() {
    if (widget.useSnapshotSystem && widget.dragOperationManager != null) {
      final snapshots = widget.dragOperationManager!.getAllSnapshots();
      debugPrint('📊 DragPreviewLayer: 快照系统已启用，共有 ${snapshots.length} 个快照');
    } else {
      debugPrint('📊 DragPreviewLayer: 快照系统未启用，使用传统预览渲染');
    }
  }
}
