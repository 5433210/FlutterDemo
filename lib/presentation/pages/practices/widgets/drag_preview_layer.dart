import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
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
    // 🔍[RESIZE_FIX] 使用ListenableBuilder确保正确响应DragStateManager变化
    return ListenableBuilder(
      listenable: widget.dragStateManager,
      builder: (context, child) {
        // 🔍[RESIZE_FIX] DragPreviewLayer关键调试
        EditPageLogger.canvasDebug('DragPreviewLayer构建开始', data: {
          'isDragPreviewActive': widget.dragStateManager.isDragPreviewActive,
          'isDragging': widget.dragStateManager.isDragging,
          'draggingElementIds': widget.dragStateManager.draggingElementIds
        });

        // 如果没有活动的拖拽预览，返回空容器
        if (!widget.dragStateManager.isDragPreviewActive) {
          EditPageLogger.canvasDebug('DragPreviewLayer无活动拖拽预览');
          return const SizedBox.shrink();
        }

        // 获取所有正在拖拽的元素ID
        final draggingElementIds = widget.dragStateManager.draggingElementIds;
        if (draggingElementIds.isEmpty) {
          EditPageLogger.canvasDebug('DragPreviewLayer无拖拽中元素');
          return const SizedBox.shrink();
        }

        EditPageLogger.canvasDebug('DragPreviewLayer构建预览层', data: {
          'draggingElementIds': draggingElementIds
        });

        // 创建一个透明层，显示所有拖拽元素的预览
        return RepaintBoundary(
          child: IgnorePointer(
            // 使用IgnorePointer包装整个预览层，避免干扰用户交互
            child: Opacity(
              opacity: DragConfig.dragPreviewOpacity,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none, // 允许子元素溢出容器边界
                children: draggingElementIds.map((elementId) {
                  // 为每个元素构建单独的预览
                  return Builder(
                    builder: (context) {
                      EditPageLogger.canvasDebug('构建元素预览', data: {
                        'elementId': elementId
                      });

                      // 🔧 优先使用完整的预览属性（支持resize和rotate）
                      final previewProperties = widget.dragStateManager
                          .getElementPreviewProperties(elementId);
                      
                      Widget elementPreview;
                      
                      if (previewProperties != null) {
                        // 使用完整的预览属性构建元素
                        EditPageLogger.canvasDebug('使用完整属性预览元素', data: {
                          'elementId': elementId
                        });
                        elementPreview = _buildFullPropertyPreview(elementId, previewProperties);
                      } else {
                        // 回退到传统的位置偏移方式
                        final previewPosition = widget.dragStateManager
                            .getElementPreviewPosition(elementId);

                        // 🔍[RESIZE_FIX] 调试预览位置
                        EditPageLogger.canvasDebug('元素预览位置', data: {
                          'elementId': elementId,
                          'previewPosition': '$previewPosition'
                        });

                        // 如果没有预览位置，不显示该元素
                        if (previewPosition == null) {
                          EditPageLogger.canvasDebug('元素没有预览位置', data: {
                            'elementId': elementId
                          });
                          return const SizedBox.shrink();
                        }

                        // 查找元素数据
                        final element = widget.elements.firstWhere(
                          (e) => e['id'] == elementId,
                          orElse: () => <String, dynamic>{},
                        );

                        if (element.isEmpty) {
                          EditPageLogger.canvasDebug('元素数据未找到', data: {
                            'elementId': elementId
                          });
                          return const SizedBox.shrink();
                        }

                        // 如果提供了自定义构建器，使用它构建预览
                        if (widget.elementBuilder != null) {
                          EditPageLogger.canvasDebug('使用自定义构建器预览元素', data: {
                            'elementId': elementId
                          });
                          elementPreview = widget.elementBuilder!(
                              elementId, previewPosition, element);
                        } else {
                          // 否则使用默认预览样式
                          EditPageLogger.canvasDebug('使用默认样式预览元素', data: {
                            'elementId': elementId
                          });
                          elementPreview = _buildDefaultPreview(
                              elementId, previewPosition, element);
                        }
                      }
                      
                      return elementPreview;
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(DragPreviewLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听DragStateManager变化
    if (widget.dragStateManager != oldWidget.dragStateManager) {
      oldWidget.dragStateManager.removeListener(_handleDragStateChange);
      widget.dragStateManager.addListener(_handleDragStateChange);
      EditPageLogger.canvasDebug('DragStateManager已更新');
    }

    // 检查元素列表变化
    if (widget.elements.length != oldWidget.elements.length) {
      EditPageLogger.canvasDebug('元素列表长度变化', data: {
        'oldLength': oldWidget.elements.length,
        'newLength': widget.elements.length
      });
    }
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

  /// 🔧 新增：构建基于完整属性的预览（支持resize和rotate）
  Widget _buildFullPropertyPreview(String elementId, Map<String, dynamic> properties) {
    // 提取元素属性
    final x = (properties['x'] as num?)?.toDouble() ?? 0.0;
    final y = (properties['y'] as num?)?.toDouble() ?? 0.0;
    final elementWidth = (properties['width'] as num?)?.toDouble() ?? 20.0;
    final elementHeight = (properties['height'] as num?)?.toDouble() ?? 20.0;
    final elementRotation = (properties['rotation'] as num?)?.toDouble() ?? 0.0;
    final elementType = (properties['type'] as String?) ?? 'unknown';

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

    EditPageLogger.canvasDebug('使用完整属性构建预览', data: {
      'position': '($x, $y)',
      'size': '(${displayWidth}, ${displayHeight})',
      'rotation': '${elementRotation}°'
    });

    // 应用位置和旋转
    return Positioned(
      left: x,
      top: y,
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
    EditPageLogger.canvasDebug('拖拽状态变化', data: {
      'isDragPreviewActive': widget.dragStateManager.isDragPreviewActive,
      'isDragging': widget.dragStateManager.isDragging,
      'draggingElementIds': widget.dragStateManager.draggingElementIds
    });

    // 检查是否是从拖拽状态到非拖拽状态的转变
    bool isDragEnding = !widget.dragStateManager.isDragging &&
        !widget.dragStateManager.isDragPreviewActive &&
        widget.dragStateManager.draggingElementIds.isEmpty;

    if (isDragEnding) {
      EditPageLogger.canvasDebug('拖拽操作结束，清理预览层');
    }

    // 在任何拖拽状态变化时都重建组件，以确保正确的显示/隐藏行为
    if (mounted) {
      setState(() {});
    }
  }

  /// 记录快照系统的可用性
  void _logSnapshotAvailability() {
    if (widget.useSnapshotSystem && widget.dragOperationManager != null) {
      final snapshots = widget.dragOperationManager!.getAllSnapshots();
      EditPageLogger.canvasDebug('快照系统已启用', data: {
        'snapshotCount': snapshots.length
      });
    } else {
      EditPageLogger.canvasDebug('快照系统未启用，使用传统预览渲染');
    }
  }
}
