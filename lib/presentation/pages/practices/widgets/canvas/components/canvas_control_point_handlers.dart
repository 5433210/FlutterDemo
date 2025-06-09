import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../widgets/practice/batch_update_options.dart';
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
    EditPageLogger.canvasDebug(
      '控制点拖拽开始',
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

    // 🔧 修复：如果是组合元素，需要把所有子元素也添加到DragStateManager
    final allElementIds = <String>{elementId};
    final allElementPositions = <String, Offset>{elementId: elementPosition};
    final allElementProperties = <String, Map<String, dynamic>>{
      elementId: Map<String, dynamic>.from(element)
    };

    if (element['type'] == 'group') {
      final content = element['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];
      
      final groupX = (element['x'] as num).toDouble();
      final groupY = (element['y'] as num).toDouble();
      
      for (final child in children) {
        final childMap = child as Map<String, dynamic>;
        final childId = childMap['id'] as String;
        
        // 🔧 修复：子元素坐标是相对于组合的，需要转换为绝对坐标
        final childRelativeX = (childMap['x'] as num).toDouble();
        final childRelativeY = (childMap['y'] as num).toDouble();
        final childAbsoluteX = groupX + childRelativeX;
        final childAbsoluteY = groupY + childRelativeY;
        
        allElementIds.add(childId);
        allElementPositions[childId] = Offset(childAbsoluteX, childAbsoluteY);
        
        // 🔧 为子元素创建临时的绝对坐标版本供DragStateManager使用
        final childWithAbsoluteCoords = Map<String, dynamic>.from(childMap);
        childWithAbsoluteCoords['x'] = childAbsoluteX;
        childWithAbsoluteCoords['y'] = childAbsoluteY;
        allElementProperties[childId] = childWithAbsoluteCoords;
      }
      
      EditPageLogger.canvasDebug('组合元素处理完成', data: {
        'childrenCount': children.length,
        'totalElements': allElementIds.length
      });
    }

    // 使用统一的DragStateManager处理
    dragStateManager.startDrag(
      elementIds: allElementIds,
      startPosition: elementPosition,
      elementStartPositions: allElementPositions,
      elementStartProperties: allElementProperties,
    );

    EditPageLogger.canvasDebug(
      '控制点拖拽预览阶段完成',
      data: {
        'elementId': elementId,
        'totalElements': allElementIds.length,
        'isRotating': _isRotating,
        'isResizing': _isResizing,
      },
    );
  }

  /// 处理控制点更新 - 实现Live阶段
  void handleControlPointUpdate(int controlPointIndex, Offset delta) {
    if (controller.state.selectedElementIds.isEmpty) {
      return;
    }

    // 在Live阶段，主要关注性能监控
    if (dragStateManager.isDragging) {
      dragStateManager.updatePerformanceStatsOnly();
    }
  }

  /// 处理控制点拖拽结束事件 - 实现Commit阶段
  void handleControlPointDragEnd(int controlPointIndex) {
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
        // 使用FreeControlPoints传递的最终状态
        if (_freeControlPointsFinalState != null &&
            _freeControlPointsFinalState!.containsKey('rotation')) {
          final finalRotation = _freeControlPointsFinalState!['rotation']!;

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
        EditPageLogger.canvasDebug('旋转操作完成', data: {'elementId': elementId});
        return;
      }

      // 处理调整大小控制点
      if (_isResizing) {
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
        EditPageLogger.canvasDebug('调整大小操作完成', data: {'elementId': elementId});
      }
    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '控制点拖拽Commit阶段错误',
        error: e,
        data: {
          'elementId': elementId,
          'controlPointIndex': controlPointIndex,
        },
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
  }

  /// 控制点主导架构：处理控制点拖拽结束并接收最终状态
  void handleControlPointDragEndWithState(int controlPointIndex, Map<String, double> finalState) {
    // 特殊处理：-2表示Live阶段的实时更新，-1表示平移操作
    if (controlPointIndex == -2) {
      handleControlPointLiveUpdate(finalState);
      return;
    }

    EditPageLogger.canvasDebug(
      '控制点主导架构处理',
      data: {
        'controlPointIndex': controlPointIndex,
        'hasOriginalProperties': _originalElementProperties != null,
      },
    );

    if (controller.state.selectedElementIds.isEmpty || _originalElementProperties == null) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 🔧 关键修复：使用拖拽开始时保存的原始元素状态
    // 而不是重新从页面获取（那可能是过时的状态）
    final originalElement = _originalElementProperties!;

    // 🔧 在Commit阶段应用网格吸附
    final finalResult = calculateFinalElementProperties(finalState);

    // 🚀 新增：检查是否为组合元素，如果是则处理子元素变换
    if (originalElement['type'] == 'group') {
      _handleGroupElementTransform(originalElement, finalResult);
    } else {
      // 普通元素处理
      _handleSingleElementTransform(elementId, originalElement, finalResult);
    }

    EditPageLogger.canvasDebug('控制点主导架构处理完成', data: {'elementId': elementId});
  }

  /// 🚀 新增：处理组合元素的变换（包括子元素变换）
  void _handleGroupElementTransform(Map<String, dynamic> groupElement, Map<String, double> newGroupProperties) {
    final groupId = groupElement['id'] as String;
    
    // 获取原始组合元素属性
    final originalX = (groupElement['x'] as num).toDouble();
    final originalY = (groupElement['y'] as num).toDouble();
    final originalWidth = (groupElement['width'] as num).toDouble();
    final originalHeight = (groupElement['height'] as num).toDouble();
    final originalRotation = (groupElement['rotation'] as num?)?.toDouble() ?? 0.0;
    
    // 获取新的组合元素属性
    final newX = newGroupProperties['x'] ?? originalX;
    final newY = newGroupProperties['y'] ?? originalY;
    final newWidth = newGroupProperties['width'] ?? originalWidth;
    final newHeight = newGroupProperties['height'] ?? originalHeight;
    final newRotation = newGroupProperties['rotation'] ?? originalRotation;
    
    // 计算变换参数
    final scaleX = originalWidth != 0 ? newWidth / originalWidth : 1.0;
    final scaleY = originalHeight != 0 ? newHeight / originalHeight : 1.0;
    final rotationDelta = newRotation - originalRotation;
    
    // 检查变换类型
    final isOnlyTranslation = (scaleX == 1.0 && scaleY == 1.0 && rotationDelta == 0.0);
    final hasScaling = (scaleX != 1.0 || scaleY != 1.0);
    
    EditPageLogger.canvasDebug('组合元素变换分析', data: {
      'groupId': groupId,
      'isOnlyTranslation': isOnlyTranslation,
      'hasScaling': hasScaling,
      'scaleX': scaleX,
      'scaleY': scaleY,
      'rotationDelta': rotationDelta,
    });
    
    // 🔧 修复：确保从正确的路径获取子元素
    final content = groupElement['content'] as Map<String, dynamic>?;
    List<dynamic> children = [];
    
    if (content != null) {
      children = content['children'] as List<dynamic>? ?? [];
    } else {
      // 回退：直接从根级获取children
      children = groupElement['children'] as List<dynamic>? ?? [];
    }
    
    if (children.isEmpty) {
      _updateSingleElement(groupId, newGroupProperties);
      return;
    }
    
    try {
      // 🔧 关键修复：正确更新组合元素和子元素
      
      // 1. 通过controller正确更新组合元素本身的属性
      controller.updateElementProperties(groupId, {
        'x': newX,
        'y': newY,
        'width': newWidth,
        'height': newHeight,
        'rotation': newRotation,
      });
      
      // 2. 根据变换类型处理子元素
      if (isOnlyTranslation) {
        // 纯平移：子元素相对位置完全不变
        EditPageLogger.canvasDebug('纯平移变换：子元素相对位置保持不变');
        // 子元素不需要任何更新，因为它们的相对位置没有变化
      } else {
        // 🔧 修复：包含缩放或复合变换时，都需要调整子元素
        EditPageLogger.canvasDebug('包含缩放变换：调整子元素', data: {
          'childrenCount': children.length,
          'scaleX': scaleX,
          'scaleY': scaleY,
        });
        
        // 🔧 关键修复：重新获取更新后的组合元素，确保子元素更新能保存
        final updatedGroupElement = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == groupId,
          orElse: () => <String, dynamic>{},
        );
        
        if (updatedGroupElement.isNotEmpty) {
          final updatedContent = updatedGroupElement['content'] as Map<String, dynamic>?;
          final updatedChildren = updatedContent?['children'] as List<dynamic>? ?? [];
          
          for (int i = 0; i < updatedChildren.length; i++) {
            final child = updatedChildren[i] as Map<String, dynamic>;
            final childId = child['id'] as String;
            
            // 🔧 关键修复：使用完整的子元素变换方法处理所有情况
            final transformedChild = _transformChildElement(
              child,
              originalWidth, // 使用原始组合尺寸
              originalHeight,
              scaleX,
              scaleY,
              rotationDelta,
            );
           
            // 直接更新子元素的属性（这会修改实际的数据结构）
            child['x'] = transformedChild['x'];
            child['y'] = transformedChild['y'];
            child['width'] = transformedChild['width'];
            child['height'] = transformedChild['height'];
            child['rotation'] = transformedChild['rotation'];
          }
          
          // 🔧 强制标记为未保存状态，确保变更被保存
          controller.state.hasUnsavedChanges = true;
        }
      }
      
      // 3. 撤销操作已由controller.updateElementProperties自动创建
      
      // 4. 更新选中元素的状态（如果当前选中的是组合元素）
      if (controller.state.selectedElementIds.contains(groupId)) {
        // 重新获取更新后的组合元素状态
        final updatedElement = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == groupId,
          orElse: () => <String, dynamic>{},
        );
        if (updatedElement.isNotEmpty) {
          controller.state.selectedElement = updatedElement;
        }
      }
      
      // 5. 触发UI更新（hasUnsavedChanges已由updateElementProperties设置）
      controller.notifyListeners();
      
      EditPageLogger.canvasDebug('组合元素变换完成', data: {
        'groupId': groupId,
        'childrenCount': children.length,
      });
    } catch (e, stackTrace) {
      EditPageLogger.editPageError('组合元素变换错误', error: e, data: {'groupId': groupId});
    }
  }

  /// 🚀 新增：变换单个子元素（完整版，用于Live预览）
  Map<String, dynamic> _transformChildElement(
    Map<String, dynamic> child,
    double originalGroupWidth,
    double originalGroupHeight,
    double scaleX,
    double scaleY,
    double rotationDelta,
  ) {
    // 获取子元素原始属性（相对于组合的坐标）
    final childX = (child['x'] as num).toDouble();
    final childY = (child['y'] as num).toDouble();
    final childWidth = (child['width'] as num).toDouble();
    final childHeight = (child['height'] as num).toDouble();
    final childRotation = (child['rotation'] as num?)?.toDouble() ?? 0.0;
    
    // 计算子元素中心相对于组合中心的原始偏移（相对坐标）
    final originalGroupCenterX = originalGroupWidth / 2;
    final originalGroupCenterY = originalGroupHeight / 2;
    final originalChildCenterX = childX + childWidth / 2;
    final originalChildCenterY = childY + childHeight / 2;
    final relativeX = originalChildCenterX - originalGroupCenterX;
    final relativeY = originalChildCenterY - originalGroupCenterY;
    
    // Step 1: 先应用旋转变换（如果有旋转变化）
    double rotatedRelativeX = relativeX;
    double rotatedRelativeY = relativeY;
    
    if (rotationDelta != 0) {
      // 将角度转换为弧度
      final rotationRad = rotationDelta * (3.14159265359 / 180);
      final cos = math.cos(rotationRad);
      final sin = math.sin(rotationRad);
      
      // 绕组合中心旋转子元素的相对位置
      rotatedRelativeX = relativeX * cos - relativeY * sin;
      rotatedRelativeY = relativeX * sin + relativeY * cos;
    }
    
    // Step 2: 再应用缩放变换到位置和尺寸
    final scaledWidth = childWidth * scaleX;
    final scaledHeight = childHeight * scaleY;
    
    // 缩放旋转后的相对位置
    final scaledRelativeX = rotatedRelativeX * scaleX;
    final scaledRelativeY = rotatedRelativeY * scaleY;
    
    // 计算缩放后的组合中心
    final scaledGroupCenterX = originalGroupCenterX * scaleX;
    final scaledGroupCenterY = originalGroupCenterY * scaleY;
    
    // 计算子元素的新中心位置（相对坐标）
    final finalChildCenterX = scaledGroupCenterX + scaledRelativeX;
    final finalChildCenterY = scaledGroupCenterY + scaledRelativeY;
    
    // 转换回左上角位置（相对坐标）
    final finalX = finalChildCenterX - scaledWidth / 2;
    final finalY = finalChildCenterY - scaledHeight / 2;
    final finalRotation = childRotation + rotationDelta;
    
    final result = {
      'x': finalX,
      'y': finalY,
      'width': math.max(scaledWidth, 1.0), // 确保最小尺寸
      'height': math.max(scaledHeight, 1.0),
      'rotation': finalRotation,
    };
    
    return result;
  }

  /// 🚀 新增：处理单个元素的变换
  void _handleSingleElementTransform(String elementId, Map<String, dynamic> originalElement, Map<String, double> finalResult) {
    _updateSingleElement(elementId, finalResult);
    
    // 创建撤销操作
    if (_originalElementProperties != null) {
      createUndoOperation(elementId, _originalElementProperties!, {
        'x': finalResult['x']!,
        'y': finalResult['y']!,
        'width': finalResult['width']!,
        'height': finalResult['height']!,
        if (finalResult.containsKey('rotation')) 'rotation': finalResult['rotation']!,
      });
    }
  }

  /// 🚀 新增：更新单个元素的属性
  void _updateSingleElement(String elementId, Map<String, double> properties) {
    // 构建更新属性
    final updateProperties = <String, dynamic>{};
    properties.forEach((key, value) {
      updateProperties[key] = value;
    });
    
    // 更新元素属性
    controller.updateElementProperties(elementId, updateProperties);
  }

  /// 控制点主导架构：处理Live阶段的实时状态更新
  void handleControlPointLiveUpdate(Map<String, double> liveState) {
    if (controller.state.selectedElementIds.isEmpty || _originalElementProperties == null) {
      return;
    }

    final elementId = controller.state.selectedElementIds.first;

    // 🔧 关键修复：使用拖拽开始时保存的原始状态作为基准
    // 而不是重新从页面获取，这样确保每次变换都是基于正确的起始点
    final originalElement = _originalElementProperties!;

    // 🔧 在Live阶段应用网格吸附
    final snappedLiveState = controller.state.snapEnabled 
        ? applyGridSnapToProperties(liveState)
        : liveState;

    // 🚀 新增：对组合元素进行Live阶段的子元素预览更新
    if (originalElement['type'] == 'group') {
      _handleGroupElementLiveUpdate(originalElement, snappedLiveState);
    } else {
      // 普通元素的Live更新
      _handleSingleElementLiveUpdate(elementId, originalElement, snappedLiveState);
    }
  }

  /// 🚀 新增：处理组合元素的Live阶段更新
  void _handleGroupElementLiveUpdate(Map<String, dynamic> groupElement, Map<String, double> liveState) {
    final groupId = groupElement['id'] as String;
    
    // 🔧 关键修复：Live阶段需要区分"拖拽基准状态"和"当前Live状态"
    // 使用拖拽开始时保存的状态作为变换基准
    final dragStartGroupElement = _originalElementProperties!;
    final baseX = (dragStartGroupElement['x'] as num).toDouble();
    final baseY = (dragStartGroupElement['y'] as num).toDouble();
    final baseWidth = (dragStartGroupElement['width'] as num).toDouble();
    final baseHeight = (dragStartGroupElement['height'] as num).toDouble();
    final baseRotation = (dragStartGroupElement['rotation'] as num?)?.toDouble() ?? 0.0;
    
    // 构建组合元素的预览属性
    final newX = liveState['x'] ?? baseX;
    final newY = liveState['y'] ?? baseY;
    final newWidth = liveState['width'] ?? baseWidth;
    final newHeight = liveState['height'] ?? baseHeight;
    final newRotation = liveState['rotation'] ?? baseRotation;
    
    final groupPreviewProperties = Map<String, dynamic>.from(groupElement);
    groupPreviewProperties.addAll({
      'x': newX,
      'y': newY,
      'width': newWidth,
      'height': newHeight,
      'rotation': newRotation,
    });

    // 实时更新DragStateManager，让DragPreviewLayer跟随控制点
    if (dragStateManager.isDragging && dragStateManager.isElementDragging(groupId)) {
      dragStateManager.updateElementPreviewProperties(groupId, groupPreviewProperties);
      
      // 🔧 修复：确保更新所有子元素的预览（使用拖拽基准状态的子元素）
      final content = dragStartGroupElement['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];
      
      if (children.isNotEmpty) {
        // 计算相对于拖拽开始时的变换增量
        final scaleX = baseWidth != 0 ? newWidth / baseWidth : 1.0;
        final scaleY = baseHeight != 0 ? newHeight / baseHeight : 1.0;
        final rotationDelta = newRotation - baseRotation;
        
        // 🔧 按照用户建议：叠加组合元素当前的旋转角度
        // 获取组合元素当前的实际旋转角度（包括之前所有操作的累积）
        final currentGroupElement = controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == groupId,
          orElse: () => dragStartGroupElement,
        );
        final currentGroupRotation = (currentGroupElement['rotation'] as num?)?.toDouble() ?? 0.0;
        final totalRotationForChild = rotationDelta + currentGroupRotation;
        
        // 为每个子元素更新预览
        for (int i = 0; i < children.length; i++) {
          final childMap = children[i] as Map<String, dynamic>;
          final childId = childMap['id'] as String;
          
          // 🔧 修复：检查子元素是否在DragStateManager中
          if (dragStateManager.isElementDragging(childId)) {
            // 🔧 关键修复：获取拖拽开始时的子元素状态作为变换基准
            final dragStartContent = dragStartGroupElement['content'] as Map<String, dynamic>?;
            final dragStartChildren = dragStartContent?['children'] as List<dynamic>? ?? [];
            
            // 找到对应的拖拽开始时的子元素状态
            final dragStartChild = dragStartChildren.firstWhere(
              (child) => (child as Map<String, dynamic>)['id'] == childId,
              orElse: () => childMap, // 回退到当前子元素
            ) as Map<String, dynamic>;
            
            // 🔧 按照用户建议：使用叠加了组合元素当前旋转角度的总旋转
            final transformedChild = _transformChildElement(
              dragStartChild,
              baseWidth,
              baseHeight,
              scaleX,
              scaleY,
              totalRotationForChild, // 使用叠加后的总旋转角度
            );
           
           // 4. 将变换后的相对坐标转换为绝对坐标
           final transformedAbsoluteX = newX + transformedChild['x']!;
           final transformedAbsoluteY = newY + transformedChild['y']!;
           
           // 5. 构建完整的子元素预览属性（使用绝对坐标）
           final childPreviewProperties = Map<String, dynamic>.from(childMap);
           childPreviewProperties.addAll({
             'x': transformedAbsoluteX,
             'y': transformedAbsoluteY,
             'width': transformedChild['width']!,
             'height': transformedChild['height']!,
             'rotation': transformedChild['rotation']!,
           });
           
           dragStateManager.updateElementPreviewProperties(childId, childPreviewProperties);
         }
        }
      }
    }
  }

  /// 🚀 新增：处理单个元素的Live阶段更新
  void _handleSingleElementLiveUpdate(String elementId, Map<String, dynamic> originalElement, Map<String, double> snappedLiveState) {
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
    }
  }

  /// 应用网格吸附到属性
  Map<String, double> applyGridSnapToProperties(Map<String, double> properties) {
    if (!controller.state.snapEnabled) {
      return properties;
    }

    final gridSize = controller.state.gridSize;
    final snappedProperties = <String, double>{};

    if (properties.containsKey('x')) {
      final originalX = properties['x']!;
      final snappedX = (originalX / gridSize).round() * gridSize;
      snappedProperties['x'] = snappedX;
    }
    if (properties.containsKey('y')) {
      final originalY = properties['y']!;
      final snappedY = (originalY / gridSize).round() * gridSize;
      snappedProperties['y'] = snappedY;
    }
    if (properties.containsKey('width')) {
      final originalWidth = properties['width']!;
      final snappedWidth = (originalWidth / gridSize).round() * gridSize;
      snappedProperties['width'] = snappedWidth;
    }
    if (properties.containsKey('height')) {
      final originalHeight = properties['height']!;
      final snappedHeight = (originalHeight / gridSize).round() * gridSize;
      snappedProperties['height'] = snappedHeight;
    }

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
      return Map<String, double>.from(_freeControlPointsFinalState!);
    }

    // 回退：如果没有最终状态，使用当前元素属性
    EditPageLogger.editPageWarning('未找到FreeControlPoints最终状态，使用回退方案');
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

    EditPageLogger.canvasDebug(
      '创建撤销操作',
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
  }

  /// 获取FreeControlPoints的最终状态
  Map<String, double>? get freeControlPointsFinalState => _freeControlPointsFinalState;

  /// 设置FreeControlPoints的最终状态（由FreeControlPoints调用）
  void setFreeControlPointsFinalState(Map<String, double> finalState) {
    _freeControlPointsFinalState = finalState;
  }
}

 