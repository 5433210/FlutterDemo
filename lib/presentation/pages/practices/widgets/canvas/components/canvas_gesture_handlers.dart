import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../../../widgets/practice/smart_canvas_gesture_handler.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../../content_render_controller.dart';
import 'canvas_ui_components.dart';

/// 画布手势处理器
/// 负责处理所有画布手势相关的逻辑
mixin CanvasGestureHandlers {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;
  
  /// 获取手势处理器（由使用此mixin的类实现）
  SmartCanvasGestureHandler get gestureHandler;
  
  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;
  
  // 注意：拖拽操作管理器相关功能暂时移除，等待具体实现
  
  /// 获取内容渲染控制器（由使用此mixin的类实现）
  ContentRenderController get contentRenderController;
  
  /// 获取选择框状态通知器（由使用此mixin的类实现）
  ValueNotifier<SelectionBoxState> get selectionBoxNotifier;
  
  /// 获取转换控制器（由使用此mixin的类实现）
  TransformationController get transformationController;
  
  /// 获取拖拽相关状态（由使用此mixin的类实现）
  bool get isDragging;
  Offset get dragStart;
  Offset get elementStartPosition;
  bool get isReadyForDrag;
  
  /// 状态更新方法（由使用此mixin的类实现）
  void updateDragState({
    bool? isDragging,
    bool? isResizing,
    bool? isRotating,
    Map<String, dynamic>? originalElementProperties,
    Offset? dragStart,
    Offset? elementStartPosition,
    bool? isReadyForDrag,
  });
  
  /// 触发setState（由使用此mixin的类实现）
  void triggerSetState();
  
  /// 网格吸附方法（由使用此mixin的类实现）
  void applyGridSnapToSelectedElements();

  /// 初始化手势处理器
  void initializeGestureHandler() {
    AppLogger.info('初始化手势处理器', tag: 'Canvas');
    
    final handler = SmartCanvasGestureHandler(
      controller: controller,
      dragStateManager: dragStateManager,
      onDragStart: _handleDragStart,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: _handleDragEnd,
      getScaleFactor: () {
        final Matrix4 matrix = transformationController.value;
        return matrix.getMaxScaleOnAxis();
      },
    );
    
    // 由具体实现类设置 gestureHandler
    AppLogger.info('手势处理器初始化完成', tag: 'Canvas');
  }

  /// 处理拖拽开始
  Future<void> _handleDragStart(
    bool isDragging,
    Offset dragStart,
    Offset elementPosition,
    Map<String, Offset> elementPositions,
  ) async {
    AppLogger.debug(
      '拖拽开始',
      tag: 'Canvas',
      data: {
        'isDragging': isDragging,
        'dragStart': '$dragStart',
        'selectedElementsCount': controller.state.selectedElementIds.length,
      },
    );

    updateDragState(
      isDragging: isDragging,
      dragStart: dragStart,
      elementStartPosition: elementPosition,
    );

    // 通知内容渲染控制器拖拽开始
    if (isDragging && controller.state.selectedElementIds.isNotEmpty) {
      AppLogger.debug(
        '处理拖拽开始',
        tag: 'Canvas',
        data: {
          'elementIds': controller.state.selectedElementIds.toList(),
          'startPosition': '$dragStart',
        },
      );

      // 通知内容渲染控制器潜在的变化
      for (final elementId in controller.state.selectedElementIds) {
        final element = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == elementId,
          orElse: () => <String, dynamic>{},
        );
        if (element.isNotEmpty) {
          contentRenderController.initializeElement(
            elementId: elementId,
            properties: element,
          );
        }
      }

      AppLogger.info('拖拽开始处理完成', tag: 'Canvas');
    } else {
      AppLogger.debug(
        '跳过拖拽处理',
        tag: 'Canvas',
        data: {
          'isDragging': isDragging,
          'selectedElementsCount': controller.state.selectedElementIds.length,
        },
      );
    }
  }

  /// 处理拖拽更新
  void _handleDragUpdate() {
    // 如果是选择框更新，使用ValueNotifier而不是setState
    if (gestureHandler.isSelectionBoxActive) {
      AppLogger.debug('更新选择框', tag: 'Canvas');
      selectionBoxNotifier.value = SelectionBoxState(
        isActive: gestureHandler.isSelectionBoxActive,
        startPoint: gestureHandler.selectionBoxStart,
        endPoint: gestureHandler.selectionBoxEnd,
      );
    } else {
      // 对于元素拖拽，使用ContentRenderController通知而不是setState
      if (controller.state.selectedElementIds.isNotEmpty) {
        AppLogger.debug(
          '更新元素拖拽',
          tag: 'Canvas',
          data: {'selectedElementsCount': controller.state.selectedElementIds.length},
        );
        
        for (final elementId in controller.state.selectedElementIds) {
          final element = controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == elementId,
            orElse: () => <String, dynamic>{},
          );
          if (element.isNotEmpty) {
            contentRenderController.notifyElementChanged(
              elementId: elementId,
              newProperties: element,
            );
          }
        }
      }
    }
  }

  /// 处理拖拽结束
  Future<void> _handleDragEnd() async {
    AppLogger.debug('拖拽结束', tag: 'Canvas');
    
    updateDragState(isDragging: false);

    // 处理元素平移后的网格吸附
    applyGridSnapToSelectedElements();

    // 通知内容渲染控制器拖拽后的元素变化
    if (controller.state.selectedElementIds.isNotEmpty) {
      AppLogger.debug(
        '通知元素变化',
        tag: 'Canvas',
        data: {'selectedElementsCount': controller.state.selectedElementIds.length},
      );
      
      for (final elementId in controller.state.selectedElementIds) {
        final element = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == elementId,
          orElse: () => <String, dynamic>{},
        );
        if (element.isNotEmpty) {
          contentRenderController.notifyElementChanged(
            elementId: elementId,
            newProperties: element,
          );
        }
      }
    }
  }

  /// 检查是否可能需要处理任何特殊手势（用于决定是否设置pan手势回调）
  bool shouldHandleAnySpecialGesture(List<Map<String, dynamic>> elements) {
    AppLogger.debug(
      '检查是否需要处理特殊手势',
      tag: 'Canvas',
      data: {
        'isPreview': controller.state.isPreviewMode,
        'currentTool': controller.state.currentTool,
        'selectedElementsCount': controller.state.selectedElementIds.length,
        'isDragging': isDragging,
        'dragManagerDragging': dragStateManager.isDragging,
      },
    );

    // 如果在预览模式，不处理任何手势
    if (controller.state.isPreviewMode) {
      AppLogger.debug('预览模式，不处理手势', tag: 'Canvas');
      return false;
    }

    // 如果在select模式下，需要处理选择框
    if (controller.state.currentTool == 'select') {
      AppLogger.debug('select模式，需要处理选择框', tag: 'Canvas');
      return true;
    }

    // 如果正在进行拖拽操作，需要处理
    if (isDragging || dragStateManager.isDragging) {
      AppLogger.debug('正在拖拽，需要处理', tag: 'Canvas');
      return true;
    }

    // 只有在有选中元素时才可能需要处理元素拖拽
    if (controller.state.selectedElementIds.isNotEmpty) {
      AppLogger.debug('有选中元素，可能需要处理拖拽', tag: 'Canvas');
      return true;
    }

    // 其他情况让InteractiveViewer完全接管
    AppLogger.debug('无特殊手势需求，让InteractiveViewer处理', tag: 'Canvas');
    return false;
  }

  /// 检查是否需要处理特殊手势（元素拖拽、选择框）
  bool shouldHandleSpecialGesture(
    DragStartDetails details,
    List<Map<String, dynamic>> elements,
  ) {
    AppLogger.debug(
      '检查特殊手势处理需求',
      tag: 'Canvas',
      data: {
        'selectedElementIds': controller.state.selectedElementIds,
        'currentTool': controller.state.currentTool,
        'clickPosition': '${details.localPosition}',
      },
    );

    // 如果在预览模式，不处理任何手势
    if (controller.state.isPreviewMode) {
      AppLogger.debug('预览模式，不处理手势', tag: 'Canvas');
      return false;
    }

    // 1. 首先检查是否点击在已选中的元素上（元素拖拽 - 在任何工具模式下都可以）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // Check if element is hidden
      if (element['hidden'] == true) continue;

      // Check if layer is hidden
      final layerId = element['layerId'] as String?;
      bool isLayerHidden = false;
      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null) {
          isLayerHidden = layer['isVisible'] == false;
        }
      }
      if (isLayerHidden) continue;

      // Check if clicking inside element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside && controller.state.selectedElementIds.contains(id)) {
        AppLogger.debug(
          '点击在已选中元素上，需要处理元素拖拽',
          tag: 'Canvas',
          data: {
            'elementId': id,
            'currentTool': controller.state.currentTool,
          },
        );
        return true;
      }
    }

    // 2. 如果在select模式下，处理选择框（框选模式）
    if (controller.state.currentTool == 'select') {
      AppLogger.debug('select模式，需要处理选择框', tag: 'Canvas');
      return true;
    }

    // 3. 其他情况不处理，让InteractiveViewer处理画布平移
    AppLogger.debug('无特殊手势需求，让InteractiveViewer处理', tag: 'Canvas');
    return false;
  }

  /// 处理点击下降事件
  void handleTapDown(TapDownDetails details, List<Map<String, dynamic>> elements) {
    AppLogger.debug(
      '处理点击下降事件',
      tag: 'Canvas',
      data: {'clickPosition': '${details.localPosition}'},
    );

    // 检查是否点击在选中元素上，如果是，准备拖拽
    if (shouldHandleSpecialGesture(
      DragStartDetails(localPosition: details.localPosition),
      elements,
    )) {
      AppLogger.debug('点击在选中元素上，准备拖拽', tag: 'Canvas');
      // 由具体实现类处理拖拽准备状态的设置
    } else {
      AppLogger.debug('点击在空白区域', tag: 'Canvas');
      // 由具体实现类处理空白区域点击
    }
  }

  /// 处理点击抬起事件
  void handleTapUp(TapUpDetails details, List<Map<String, dynamic>> elements) {
    AppLogger.debug(
      '处理点击抬起事件',
      tag: 'Canvas',
      data: {
        'clickPosition': '${details.localPosition}',
        'selectedElementsCount': controller.state.selectedElementIds.length,
      },
    );

    gestureHandler.handleTapUp(details, elements);

    // 触发状态更新
    triggerSetState();

    AppLogger.debug(
      '点击处理完成',
      tag: 'Canvas',
      data: {'selectedElementsCount': controller.state.selectedElementIds.length},
    );
  }

  /// 处理平移开始事件
  void handlePanStart(DragStartDetails details, List<Map<String, dynamic>> elements) {
    AppLogger.debug(
      '平移开始',
      tag: 'Canvas',
      data: {
        'clickPosition': '${details.localPosition}',
        'selectedElementIds': controller.state.selectedElementIds,
        'currentTool': controller.state.currentTool,
      },
    );

    // 动态检查是否需要处理特殊手势
    final shouldHandle = shouldHandleSpecialGesture(
      DragStartDetails(localPosition: details.localPosition),
      elements,
    );
    
    AppLogger.debug(
      '特殊手势检查结果',
      tag: 'Canvas',
      data: {'shouldHandle': shouldHandle},
    );

    if (shouldHandle) {
      AppLogger.debug('处理特殊手势', tag: 'Canvas');
      gestureHandler.handlePanStart(details, elements);
    } else {
      AppLogger.debug('空白区域点击，不处理', tag: 'Canvas');
      // 关键：不调用任何处理逻辑，让手势穿透
    }
  }

  /// 处理平移更新事件
  void handlePanUpdate(DragUpdateDetails details) {
    AppLogger.debug(
      '平移更新',
      tag: 'Canvas',
      data: {'position': '${details.localPosition}'},
    );

    // 处理选择框更新
    if (controller.state.currentTool == 'select' && 
        gestureHandler.isSelectionBoxActive) {
      AppLogger.debug('处理选择框更新', tag: 'Canvas');
      gestureHandler.handlePanUpdate(details);
      selectionBoxNotifier.value = SelectionBoxState(
        isActive: true,
        startPoint: gestureHandler.selectionBoxStart,
        endPoint: gestureHandler.selectionBoxEnd,
      );
      return;
    }

    // 处理元素拖拽
    if (isDragging || dragStateManager.isDragging) {
      AppLogger.debug('处理元素拖拽', tag: 'Canvas');
      gestureHandler.handlePanUpdate(details);
      return;
    }

    AppLogger.debug('空白区域手势，不拦截', tag: 'Canvas');
  }

  /// 处理平移结束事件
  void handlePanEnd(DragEndDetails details) {
    AppLogger.debug('平移结束', tag: 'Canvas');

    // 处理选择框结束
    if (controller.state.currentTool == 'select' && 
        gestureHandler.isSelectionBoxActive) {
      gestureHandler.handlePanEnd(details);
    }

    // 处理拖拽结束
    if (isDragging || dragStateManager.isDragging) {
      gestureHandler.handlePanEnd(details);
    }
  }

  /// 处理平移取消事件
  void handlePanCancel() {
    AppLogger.debug('平移取消', tag: 'Canvas');

    // 处理选择框取消
    if (controller.state.currentTool == 'select' && 
        gestureHandler.isSelectionBoxActive) {
      gestureHandler.handlePanCancel();
    }

    // 处理拖拽取消
    if (isDragging || dragStateManager.isDragging) {
      gestureHandler.handlePanCancel();
    }
  }

  /// 处理辅助点击下降事件（右键）
  void handleSecondaryTapDown(TapDownDetails details) {
    AppLogger.debug(
      '处理辅助点击下降事件',
      tag: 'Canvas',
      data: {'position': '${details.localPosition}'},
    );
    gestureHandler.handleSecondaryTapDown(details);
  }

  /// 处理辅助点击抬起事件（右键）
  void handleSecondaryTapUp(TapUpDetails details, List<Map<String, dynamic>> elements) {
    AppLogger.debug(
      '处理辅助点击抬起事件',
      tag: 'Canvas',
      data: {'position': '${details.localPosition}'},
    );
    gestureHandler.handleSecondaryTapUp(details, elements);
  }
} 