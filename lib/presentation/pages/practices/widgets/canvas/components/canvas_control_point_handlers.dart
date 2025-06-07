import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../../content_render_controller.dart';
import '../../element_change_types.dart';

/// 画布控制点处理器
/// 负责处理控制点相关的逻辑，包括拖拽、缩放、旋转等
mixin CanvasControlPointHandlers {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;
  
  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;
  
  /// 获取内容渲染控制器（由使用此mixin的类实现）
  ContentRenderController get contentRenderController;
  
  /// 获取mounted状态（由使用此mixin的类实现）
  bool get mounted;
  
  /// 触发setState（由使用此mixin的类实现）
  void setState(VoidCallback fn);

  // 状态管理
  bool _isResizing = false;
  bool _isRotating = false;
  Map<String, dynamic>? _originalElementProperties;
  Map<String, double>? _freeControlPointsFinalState;
  bool _isReadyForDrag = false;
  bool _isDragging = false;

  /// 获取状态访问器
  bool get isResizing => _isResizing;
  bool get isRotating => _isRotating;
  bool get isReadyForDrag => _isReadyForDrag;
  bool get isDragging => _isDragging;
  Map<String, dynamic>? get originalElementProperties => _originalElementProperties;

  /// 更新拖拽状态
  void updateDragState({
    bool? isDragging,
    bool? isResizing,
    bool? isRotating,
    Map<String, dynamic>? originalElementProperties,
    bool? isReadyForDrag,
    Offset? dragStart,
    Offset? elementStartPosition,
  }) {
    if (isDragging != null) _isDragging = isDragging;
    if (isResizing != null) _isResizing = isResizing;
    if (isRotating != null) _isRotating = isRotating;
    if (originalElementProperties != null) _originalElementProperties = originalElementProperties;
    if (isReadyForDrag != null) _isReadyForDrag = isReadyForDrag;
    // dragStart 和 elementStartPosition 可以被子类使用
  }

  /// 处理控制点拖拽开始事件 - 实现Preview阶段
  void handleControlPointDragStart(int controlPointIndex) {
    AppLogger.debug(
      '控制点拖拽开始',
      tag: 'Canvas',
      data: {
        'controlPointIndex': controlPointIndex,
        'selectedCount': controller.state.selectedElementIds.length,
      },
    );

    if (controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 获取当前元素属性并保存，用于稍后创建撤销操作
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 保存元素的原始属性
    _originalElementProperties = Map<String, dynamic>.from(element);

    // 记录当前是调整大小还是旋转
    _isRotating = (controlPointIndex == 8);
    _isResizing = !_isRotating;

    // Phase 1: Preview - 启动拖拽状态管理器并创建预览快照
    final elementPosition = Offset(
      (element['x'] as num).toDouble(),
      (element['y'] as num).toDouble(),
    );

    // 使用统一的DragStateManager处理
    dragStateManager.startDrag(
      elementIds: {elementId},
      startPosition: elementPosition,
      elementStartPositions: {elementId: elementPosition},
      elementStartProperties: {
        elementId: Map<String, dynamic>.from(element)
      },
    );

    AppLogger.info(
      '控制点拖拽预览阶段完成',
      tag: 'Canvas',
      data: {
        'elementId': elementId,
        'isRotating': _isRotating,
        'isResizing': _isResizing,
      },
    );
  }

  /// 处理控制点更新 - 实现Live阶段
  void handleControlPointUpdate(int controlPointIndex, Offset delta) {
    AppLogger.debug(
      '控制点更新',
      tag: 'Canvas',
      data: {
        'controlPointIndex': controlPointIndex,
        'delta': '$delta',
      },
    );

    if (controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 在Live阶段，主要关注性能监控
    if (dragStateManager.isDragging) {
      dragStateManager.updatePerformanceStatsOnly();
    }

    AppLogger.debug('控制点Live阶段更新完成', tag: 'Canvas');
  }

  /// 处理控制点拖拽结束事件 - 实现Commit阶段
  void handleControlPointDragEnd(int controlPointIndex) {
    AppLogger.debug(
      '控制点拖拽结束',
      tag: 'Canvas',
      data: {'controlPointIndex': controlPointIndex},
    );

    if (controller.state.selectedElementIds.isEmpty || _originalElementProperties == null) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 获取当前元素属性
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    try {
      // Phase 3: Commit - 结束拖拽状态管理器并提交最终更改
      dragStateManager.endDrag(shouldCommitChanges: true);

      // 强制内容渲染控制器刷新，确保元素恢复可见性
      contentRenderController.markElementDirty(elementId, ElementChangeType.multiple);

      // 处理旋转控制点
      if (_isRotating) {
        AppLogger.debug('处理旋转操作', tag: 'Canvas');

        // 使用FreeControlPoints传递的最终状态
        if (_freeControlPointsFinalState != null &&
            _freeControlPointsFinalState!.containsKey('rotation')) {
          final finalRotation = _freeControlPointsFinalState!['rotation']!;

          AppLogger.debug(
            '应用旋转变换',
            tag: 'Canvas',
            data: {'rotation': finalRotation},
          );

          // 应用最终旋转值
          element['rotation'] = finalRotation;

          // 更新Controller中的元素属性
          controller.updateElementProperties(elementId, {
            'rotation': finalRotation,
          });
        } else {
          // 回退：如果没有最终状态，保持当前rotation不变
          final currentRotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
          controller.updateElementProperties(elementId, {
            'rotation': currentRotation,
          });
        }

        // 创建撤销操作
        createUndoOperation(elementId, _originalElementProperties!, element);

        _isRotating = false;
        _originalElementProperties = null;
        AppLogger.info('旋转操作完成', tag: 'Canvas');
        return;
      }

      // 处理调整大小控制点
      if (_isResizing) {
        AppLogger.debug('处理调整大小操作', tag: 'Canvas');

        // 计算resize的最终变化
        final resizeResult = calculateResizeFromFreeControlPoints(elementId, controlPointIndex);

        if (resizeResult != null) {
          // 🔧 在Commit阶段应用网格吸附
          final finalResult = calculateFinalElementProperties(resizeResult);
          
          // 应用resize变化（使用吸附后的最终结果）
          element['x'] = finalResult['x']!;
          element['y'] = finalResult['y']!;
          element['width'] = finalResult['width']!;
          element['height'] = finalResult['height']!;

          AppLogger.debug(
            '应用调整大小变换',
            tag: 'Canvas',
            data: finalResult,
          );

          // 更新Controller中的元素属性
          controller.updateElementProperties(elementId, {
            'x': finalResult['x']!,
            'y': finalResult['y']!,
            'width': finalResult['width']!,
            'height': finalResult['height']!,
          });
        }

        // 创建撤销操作
        createUndoOperation(elementId, _originalElementProperties!, element);

        // 确保UI更新
        controller.notifyListeners();

        _isResizing = false;
        _originalElementProperties = null;
        AppLogger.info('调整大小操作完成', tag: 'Canvas');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '控制点拖拽Commit阶段错误',
        tag: 'Canvas',
        error: e,
        stackTrace: stackTrace,
      );
      
      // 发生错误时恢复原始状态
      if (_originalElementProperties != null) {
        for (final key in _originalElementProperties!.keys) {
          element[key] = _originalElementProperties![key];
        }
        controller.notifyListeners();
      }
    } finally {
      // 确保清理状态
      _isRotating = false;
      _isResizing = false;
      _originalElementProperties = null;
      _freeControlPointsFinalState = null;

      // 重置拖拽状态
      _isReadyForDrag = false;
      _isDragging = false;

      // 立即触发状态更新
      if (mounted) {
        setState(() {});
      }

      // 添加延迟刷新确保完整可见性恢复
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          // 标记元素为脏以强制重新渲染
          if (controller.state.selectedElementIds.isNotEmpty) {
            final elementId = controller.state.selectedElementIds.first;
            contentRenderController.markElementDirty(elementId, ElementChangeType.multiple);

            // 通知DragStateManager强制清理拖拽状态
            dragStateManager.cancelDrag();

            // 确保DragPreviewLayer不再显示该元素
            setState(() {});

            // 更新控制器状态以确保UI更新
            controller.notifyListeners();
          }
        }
      });
    }

    AppLogger.info('控制点拖拽Commit阶段完成', tag: 'Canvas');
  }

  /// 控制点主导架构：处理控制点拖拽结束并接收最终状态
  void handleControlPointDragEndWithState(int controlPointIndex, Map<String, double> finalState) {
    // 特殊处理：-2表示Live阶段的实时更新，-1表示平移操作
    if (controlPointIndex == -2) {
      AppLogger.debug('控制点Live阶段实时更新', tag: 'Canvas', data: finalState);
      handleControlPointLiveUpdate(finalState);
      return;
    }

    AppLogger.debug(
      '控制点主导架构：收到最终状态',
      tag: 'Canvas',
      data: {
        'controlPointIndex': controlPointIndex,
        'finalState': finalState,
      },
    );

    if (controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 获取原始元素，保留所有非几何属性
    final originalElement = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (originalElement.isEmpty) {
      AppLogger.warning('找不到原始元素', tag: 'Canvas', data: {'elementId': elementId});
      return;
    }

    // 🔧 在主导架构中应用网格吸附
    final snappedFinalState = controller.state.snapEnabled 
        ? applyGridSnapToProperties(finalState)
        : finalState;

    // 构建控制点主导的完整元素预览属性（使用吸附后的状态）
    final controlPointDrivenProperties = Map<String, dynamic>.from(originalElement);
    controlPointDrivenProperties.addAll({
      'x': snappedFinalState['x'] ?? originalElement['x'],
      'y': snappedFinalState['y'] ?? originalElement['y'],
      'width': snappedFinalState['width'] ?? originalElement['width'],
      'height': snappedFinalState['height'] ?? originalElement['height'],
      'rotation': snappedFinalState['rotation'] ?? originalElement['rotation'],
    });

    AppLogger.debug(
      '控制点主导的完整属性',
      tag: 'Canvas',
      data: controlPointDrivenProperties,
    );

    // 将控制点状态推送给DragStateManager，让DragPreviewLayer跟随
    if (dragStateManager.isDragging && dragStateManager.isElementDragging(elementId)) {
      AppLogger.debug('推送控制点状态到DragStateManager', tag: 'Canvas');
      dragStateManager.updateElementPreviewProperties(elementId, controlPointDrivenProperties);
    } else {
      AppLogger.debug('启动拖拽系统以支持预览', tag: 'Canvas');

      // 启动拖拽系统以支持预览
      final elementPosition = Offset(
          (snappedFinalState['x'] ?? originalElement['x'] as num).toDouble(),
          (snappedFinalState['y'] ?? originalElement['y'] as num).toDouble());

      dragStateManager.startDrag(
        elementIds: {elementId},
        startPosition: elementPosition,
        elementStartPositions: {elementId: elementPosition},
        elementStartProperties: {elementId: controlPointDrivenProperties},
      );

      // 立即更新预览属性
      dragStateManager.updateElementPreviewProperties(elementId, controlPointDrivenProperties);
    }

    // 保存最终状态，供Commit阶段使用（使用吸附后的状态）
    _freeControlPointsFinalState = snappedFinalState;

    AppLogger.info('控制点主导架构处理完成', tag: 'Canvas');
  }

  /// 控制点主导架构：处理Live阶段的实时状态更新
  void handleControlPointLiveUpdate(Map<String, double> liveState) {
    if (controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 获取原始元素，保留所有非几何属性
    final originalElement = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (originalElement.isEmpty) {
      return;
    }

    // 🔧 在Live阶段应用网格吸附
    final snappedLiveState = controller.state.snapEnabled 
        ? applyGridSnapToProperties(liveState)
        : liveState;

    // 构建Live阶段的预览属性（使用吸附后的状态）
    final livePreviewProperties = Map<String, dynamic>.from(originalElement);
    livePreviewProperties.addAll({
      'x': snappedLiveState['x'] ?? originalElement['x'],
      'y': snappedLiveState['y'] ?? originalElement['y'],
      'width': snappedLiveState['width'] ?? originalElement['width'],
      'height': snappedLiveState['height'] ?? originalElement['height'],
      'rotation': snappedLiveState['rotation'] ?? originalElement['rotation'],
    });

    // 实时更新DragStateManager，让DragPreviewLayer跟随控制点
    if (dragStateManager.isDragging && dragStateManager.isElementDragging(elementId)) {
      dragStateManager.updateElementPreviewProperties(elementId, livePreviewProperties);
      AppLogger.debug('Live阶段：DragPreviewLayer已更新', tag: 'Canvas');
    }
  }

  /// 应用网格吸附到属性
  Map<String, double> applyGridSnapToProperties(Map<String, double> properties) {
    if (!controller.state.snapEnabled) {
      debugPrint('🎯 网格吸附未启用，跳过属性吸附');
      return properties;
    }

    final gridSize = controller.state.gridSize;
    final snappedProperties = <String, double>{};
    
    debugPrint('🎯 开始应用网格吸附 - 网格大小: $gridSize');
    debugPrint('🎯 原始属性: $properties');

    if (properties.containsKey('x')) {
      final originalX = properties['x']!;
      final snappedX = (originalX / gridSize).round() * gridSize;
      snappedProperties['x'] = snappedX;
      if (originalX != snappedX) {
        debugPrint('🎯 位置X吸附: $originalX → $snappedX');
      }
    }
    if (properties.containsKey('y')) {
      final originalY = properties['y']!;
      final snappedY = (originalY / gridSize).round() * gridSize;
      snappedProperties['y'] = snappedY;
      if (originalY != snappedY) {
        debugPrint('🎯 位置Y吸附: $originalY → $snappedY');
      }
    }
    if (properties.containsKey('width')) {
      final originalWidth = properties['width']!;
      final snappedWidth = (originalWidth / gridSize).round() * gridSize;
      snappedProperties['width'] = snappedWidth;
      if (originalWidth != snappedWidth) {
        debugPrint('🎯 宽度吸附: $originalWidth → $snappedWidth');
      }
    }
    if (properties.containsKey('height')) {
      final originalHeight = properties['height']!;
      final snappedHeight = (originalHeight / gridSize).round() * gridSize;
      snappedProperties['height'] = snappedHeight;
      if (originalHeight != snappedHeight) {
        debugPrint('🎯 高度吸附: $originalHeight → $snappedHeight');
      }
    }

    debugPrint('🎯 吸附后的属性: $snappedProperties');
    return snappedProperties;
  }

  /// 计算最终元素属性 - 用于Commit阶段
  Map<String, double> calculateFinalElementProperties(Map<String, double> elementProperties) {
    final finalProperties = Map<String, double>.from(elementProperties);

    // 应用网格吸附（如果启用）
    if (controller.state.snapEnabled) {
      final snappedProperties = applyGridSnapToProperties(finalProperties);
      finalProperties.addAll(snappedProperties);
    }

    // 确保最小尺寸
    finalProperties['width'] = math.max(finalProperties['width'] ?? 10.0, 10.0);
    finalProperties['height'] = math.max(finalProperties['height'] ?? 10.0, 10.0);

    return finalProperties;
  }

  /// 根据FreeControlPoints的最终状态计算元素尺寸
  Map<String, double>? calculateResizeFromFreeControlPoints(String elementId, int controlPointIndex) {
    // 使用FreeControlPoints传递的最终计算状态
    if (_freeControlPointsFinalState != null) {
      AppLogger.debug(
        '使用FreeControlPoints最终状态',
        tag: 'Canvas',
        data: _freeControlPointsFinalState,
      );
      return Map<String, double>.from(_freeControlPointsFinalState!);
    }

    // 回退：如果没有最终状态，使用当前元素属性
    AppLogger.warning('未找到FreeControlPoints最终状态，使用当前元素属性作为回退', tag: 'Canvas');
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return null;

    return {
      'x': (element['x'] as num).toDouble(),
      'y': (element['y'] as num).toDouble(),
      'width': (element['width'] as num).toDouble(),
      'height': (element['height'] as num).toDouble(),
    };
  }

  /// 创建撤销操作 - 用于Commit阶段
  void createUndoOperation(String elementId, Map<String, dynamic> oldProperties, Map<String, dynamic> newProperties) {
    // 检查是否有实际变化
    bool hasChanges = false;
    for (final key in newProperties.keys) {
      if (oldProperties[key] != newProperties[key]) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) {
      return; // 没有变化，不需要创建撤销操作
    }

    AppLogger.debug(
      '创建撤销操作',
      tag: 'Canvas',
      data: {
        'elementId': elementId,
        'hasRotationChange': newProperties.containsKey('rotation'),
        'hasSizeChange': newProperties.keys.any((key) => ['x', 'y', 'width', 'height'].contains(key)),
      },
    );

    // 根据变化类型创建对应的撤销操作
    if (newProperties.containsKey('rotation') && oldProperties.containsKey('rotation')) {
      // 旋转操作
      controller.createElementRotationOperation(
        elementIds: [elementId],
        oldRotations: [(oldProperties['rotation'] as num).toDouble()],
        newRotations: [(newProperties['rotation'] as num).toDouble()],
      );
    } else if (newProperties.keys.any((key) => ['x', 'y', 'width', 'height'].contains(key))) {
      // 调整大小/位置操作
      final oldSize = {
        'x': (oldProperties['x'] as num).toDouble(),
        'y': (oldProperties['y'] as num).toDouble(),
        'width': (oldProperties['width'] as num).toDouble(),
        'height': (oldProperties['height'] as num).toDouble(),
      };
      final newSize = {
        'x': (newProperties['x'] as num).toDouble(),
        'y': (newProperties['y'] as num).toDouble(),
        'width': (newProperties['width'] as num).toDouble(),
        'height': (newProperties['height'] as num).toDouble(),
      };

      controller.createElementResizeOperation(
        elementIds: [elementId],
        oldSizes: [oldSize],
        newSizes: [newSize],
      );
    }

    AppLogger.info('撤销操作创建完成', tag: 'Canvas');
  }
}

 