import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../../../../../widgets/practice/guideline_alignment/guideline_manager.dart';
import '../../../../../widgets/practice/guideline_alignment/guideline_types.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../utils/practice_edit_utils.dart';
import '../../content_render_controller.dart';
import '../../element_change_types.dart';

/// 画布控制点处理器
/// 负责处理控制点相关的逻辑，包括拖拽、缩放、旋转等
mixin CanvasControlPointHandlers {
  // 状态管理
  bool _isResizing = false;

  bool _isRotating = false;

  Map<String, dynamic>? _originalElementProperties;

  Map<String, double>? _freeControlPointsFinalState;

  bool _isReadyForDrag = false;

  bool _isDragging = false;
  // 防止重复创建撤销操作的记录
  final Set<String> _recentUndoOperations = {};

  /// 获取内容渲染控制器（由使用此mixin的类实现）
  ContentRenderController get contentRenderController;

  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;

  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;

  /// 获取FreeControlPoints的最终状态
  Map<String, double>? get freeControlPointsFinalState =>
      _freeControlPointsFinalState;

  bool get isDragging => _isDragging;

  bool get isReadyForDrag => _isReadyForDrag;

  /// 获取状态访问器
  bool get isResizing => _isResizing;
  bool get isRotating => _isRotating;

  /// 获取mounted状态（由使用此mixin的类实现）
  bool get mounted;
  Map<String, dynamic>? get originalElementProperties =>
      _originalElementProperties;

  /// 应用网格吸附到属性
  Map<String, double> applyGridSnapToProperties(
      Map<String, double> properties) {
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
  Map<String, double> calculateFinalElementProperties(
      Map<String, double> elementProperties) {
    final finalProperties = Map<String, double>.from(elementProperties);

    // 应用网格吸附（如果启用）
    if (controller.state.snapEnabled) {
      final snappedProperties = applyGridSnapToProperties(finalProperties);
      finalProperties.addAll(snappedProperties);
    }

    // 确保最小尺寸
    finalProperties['width'] = math.max(finalProperties['width'] ?? 10.0, 10.0);
    finalProperties['height'] =
        math.max(finalProperties['height'] ?? 10.0, 10.0);

    return finalProperties;
  }

  /// 根据FreeControlPoints的最终状态计算元素尺寸
  Map<String, double>? calculateResizeFromFreeControlPoints(
      String elementId, int controlPointIndex) {
    // 使用FreeControlPoints传递的最终计算状态
    if (_freeControlPointsFinalState != null) {
      return Map<String, double>.from(_freeControlPointsFinalState!);
    }

    // 🔧 优化：改为DEBUG级别，避免误导性WARNING
    EditPageLogger.editPageDebug('FreeControlPoints最终状态未设置，使用当前元素状态', data: {
      'elementId': elementId,
      'controlPointIndex': controlPointIndex,
      'fallbackReason': 'final_state_not_provided',
      'optimization': 'use_current_element_state',
    });
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
  void createUndoOperation(String elementId, Map<String, dynamic> oldProperties,
      Map<String, dynamic> newProperties) {
    // 检查是否有实际变化
    bool hasChanges = false;
    for (final key in newProperties.keys) {
      if (oldProperties[key] != newProperties[key]) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) {
      EditPageLogger.canvasDebug('无实际变化，跳过撤销操作创建');
      return; // 没有变化，不需要创建撤销操作
    }

    // 🔧 增强重复检测：基于元素ID和操作类型
    final operationType =
        newProperties.containsKey('rotation') ? 'rotation' : 'resize';
    final operationKey =
        '${elementId}_${operationType}_${DateTime.now().millisecondsSinceEpoch ~/ 200}'; // 200ms内视为同一操作
    if (_recentUndoOperations.contains(operationKey)) {
      EditPageLogger.canvasDebug('🚫 检测到重复撤销操作，已跳过', data: {
        'elementId': elementId,
        'operationType': operationType,
        'operationKey': operationKey,
        'optimization': 'duplicate_undo_prevention',
      });
      return;
    }

    // 记录此次操作，并设置过期时间
    _recentUndoOperations.add(operationKey);
    Timer(const Duration(milliseconds: 500), () {
      _recentUndoOperations.remove(operationKey);
    });

    EditPageLogger.canvasDebug(
      '创建撤销操作',
      data: {
        'elementId': elementId,
        'hasRotationChange': newProperties.containsKey('rotation'),
        'hasSizeChange': newProperties.keys
            .any((key) => ['x', 'y', 'width', 'height'].contains(key)),
        'operationKey': operationKey,
      },
    );

    // 根据变化类型创建对应的撤销操作
    // 检查是否有实际的旋转变化
    bool hasRotationChange = false;
    if (newProperties.containsKey('rotation') &&
        oldProperties.containsKey('rotation')) {
      final oldRotation = (oldProperties['rotation'] as num).toDouble();
      final newRotation = (newProperties['rotation'] as num).toDouble();
      hasRotationChange =
          (oldRotation - newRotation).abs() > 0.001; // 允许微小的浮点误差
    }

    if (hasRotationChange) {
      // 🔧 检查是否为组合元素
      final currentElement = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (currentElement.isNotEmpty && currentElement['type'] == 'group') {
        // 🔧 组合元素旋转：使用组合元素旋转操作
        // 需要获取完整的组合元素状态，不只是修改的属性
        final oldGroupState = Map<String, dynamic>.from(
            _originalElementProperties ?? <String, dynamic>{});
        final newGroupState = Map<String, dynamic>.from(currentElement);

        EditPageLogger.editPageDebug('控制点处理器创建组合元素旋转撤销操作', data: {
          'elementId': elementId,
          'oldRotation': (oldGroupState['rotation'] as num?)?.toDouble() ?? 0.0,
          'newRotation': (newGroupState['rotation'] as num?)?.toDouble() ?? 0.0,
          'oldChildrenCount': ((oldGroupState['content']
                      as Map<String, dynamic>?)?['children'] as List<dynamic>?)
                  ?.length ??
              0,
          'newChildrenCount': ((newGroupState['content']
                      as Map<String, dynamic>?)?['children'] as List<dynamic>?)
                  ?.length ??
              0,
          'operation': 'control_point_group_rotation',
        });

        controller.createGroupElementRotationOperation(
          groupElementId: elementId,
          oldGroupState: oldGroupState,
          newGroupState: newGroupState,
        );
      } else {
        // 🔧 单个元素旋转：使用普通元素旋转操作
        EditPageLogger.editPageDebug('控制点处理器创建单个元素旋转撤销操作', data: {
          'elementId': elementId,
          'oldRotation': (oldProperties['rotation'] as num).toDouble(),
          'newRotation': (newProperties['rotation'] as num).toDouble(),
          'operation': 'control_point_rotation',
        });

        controller.createElementRotationOperation(
          elementIds: [elementId],
          oldRotations: [(oldProperties['rotation'] as num).toDouble()],
          newRotations: [(newProperties['rotation'] as num).toDouble()],
        );
      }
    } else if (newProperties.keys
        .any((key) => ['x', 'y', 'width', 'height'].contains(key))) {
      // 🔧 DEBUG: 控制点调整大小/位置操作
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

      EditPageLogger.editPageDebug('控制点处理器创建pan/resize撤销操作', data: {
        'elementId': elementId,
        'oldSize': oldSize,
        'newSize': newSize,
        'operation': 'control_point_resize',
      });

      controller.createElementResizeOperation(
        elementIds: [elementId],
        oldSizes: [oldSize],
        newSizes: [newSize],
      );
    }
  }

  /// 处理控制点拖拽结束事件 - 实现Commit阶段
  void handleControlPointDragEnd(int controlPointIndex) {
    if (controller.state.selectedElementIds.isEmpty ||
        _originalElementProperties == null) {
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
      //为了避免元素偶尔出现的拖动过程跳出拖动状态的情况（具体原因未知），强制做一次重复的选中元素
      controller.selectElements([elementId]);
      // Phase 3: Commit - 结束拖拽状态管理器并提交最终更改
      dragStateManager.endDrag(shouldCommitChanges: true);

      // 强制内容渲染控制器刷新，确保元素恢复可见性
      contentRenderController.markElementDirty(
          elementId, ElementChangeType.multiple);

      // 处理旋转控制点
      if (_isRotating) {
        // 使用FreeControlPoints传递的最终状态
        if (_freeControlPointsFinalState != null &&
            _freeControlPointsFinalState!.containsKey('rotation')) {
          final finalRotation = _freeControlPointsFinalState!['rotation']!;

          // 应用最终旋转值
          element['rotation'] = finalRotation;

          // 更新Controller中的元素属性（不创建撤销操作，因为这里会统一创建）
          controller.updateElementPropertiesWithoutUndo(elementId, {
            'rotation': finalRotation,
          });
        } else {
          // 回退：如果没有最终状态，保持当前rotation不变
          final currentRotation =
              (element['rotation'] as num?)?.toDouble() ?? 0.0;
          controller.updateElementPropertiesWithoutUndo(elementId, {
            'rotation': currentRotation,
          });
        }

        // 🔧 修复：完全跳过传统路径的后续处理，避免重复元素更新
        // 新的控制点主导架构(handleControlPointDragEndWithState)会负责全部处理
        EditPageLogger.canvasDebug(
          '传统旋转路径跳过 - 全部由新架构处理',
          data: {
            'elementId': elementId,
            'optimization': 'skip_legacy_rotation_completely',
            'reason': '避免与控制点主导架构重复处理',
          },
        );

        _isRotating = false;
        _originalElementProperties = null;
        EditPageLogger.canvasDebug('旋转操作完成', data: {'elementId': elementId});
        return;
        return;
      }

      // 处理调整大小控制点
      if (_isResizing) {
        // 计算resize的最终变化
        final resizeResult =
            calculateResizeFromFreeControlPoints(elementId, controlPointIndex);

        if (resizeResult != null) {
          // 🔧 在Commit阶段应用网格吸附
          final finalResult = calculateFinalElementProperties(resizeResult);

          // 应用resize变化（使用吸附后的最终结果）
          element['x'] = finalResult['x']!;
          element['y'] = finalResult['y']!;
          element['width'] = finalResult['width']!;
          element['height'] = finalResult['height']!;

          // 更新Controller中的元素属性（不创建撤销操作，因为这里会统一创建）
          controller.updateElementPropertiesWithoutUndo(elementId, {
            'x': finalResult['x']!,
            'y': finalResult['y']!,
            'width': finalResult['width']!,
            'height': finalResult['height']!,
          });
        }

        // 🔧 修复：完全跳过传统路径的后续处理，避免重复元素更新
        // 新的控制点主导架构(handleControlPointDragEndWithState)会负责全部处理
        EditPageLogger.canvasDebug(
          '传统控制点路径跳过 - 全部由新架构处理',
          data: {
            'elementId': elementId,
            'optimization': 'skip_legacy_path_completely',
            'reason': '避免与控制点主导架构重复处理',
          },
        );

        // 🚀 直接返回，不执行任何元素更新或状态分发
        _isResizing = false;
        _originalElementProperties = null;
        return;

        // UI更新已由updateElementPropertiesWithoutUndo处理

        _isResizing = false;
        _originalElementProperties = null;
        EditPageLogger.canvasDebug('调整大小操作完成', data: {'elementId': elementId});
      }
    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '控制点拖拽Commit阶段错误',
        error: e,
        stackTrace: stackTrace,
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
        // 🚀 使用智能状态分发器通知错误恢复
        controller.intelligentNotify(
          changeType: 'element_error_recovery',
          eventData: {
            'elementId': elementId,
            'operation': 'control_point_error_recovery',
            'timestamp': DateTime.now().toIso8601String(),
          },
          operation: 'control_point_error_recovery',
          affectedElements: [elementId],
          affectedLayers: ['content'],
          affectedUIComponents: ['canvas'],
        );
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

      // 🚀 优化：避免触发Canvas整体重建
      // 控制点状态更新应该通过分层架构处理，不需要setState
      EditPageLogger.canvasDebug(
        '跳过控制点处理器setState - 使用分层架构',
        data: {
          'optimization': 'avoid_control_point_setstate',
          'reason': '分层架构会自动处理必要的重建',
        },
      );

      // 🔧 修复：移除延迟cancelDrag调用，避免破坏正常拖拽状态
      // 延迟刷新仅用于UI更新，不应影响拖拽状态管理
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          // 标记元素为脏以强制重新渲染
          if (controller.state.selectedElementIds.isNotEmpty) {
            final elementId = controller.state.selectedElementIds.first;
            contentRenderController.markElementDirty(
                elementId, ElementChangeType.multiple);

            // 🔧 移除不必要的cancelDrag调用 - 拖拽状态应由正常流程管理
            // dragStateManager.cancelDrag(); // ❌ 删除：这会破坏正常拖拽状态

            EditPageLogger.canvasDebug(
              '延迟UI刷新完成 - 不影响拖拽状态',
              data: {
                'optimization': 'delayed_ui_refresh_only',
                'reason': '仅UI刷新，拖拽状态由正常流程管理',
              },
            );
          }
        }
      });
    }
  }

  /// 控制点主导架构：处理控制点拖拽结束并接收最终状态
  void handleControlPointDragEndWithState(
      int controlPointIndex, Map<String, double> finalState) {
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

    if (controller.state.selectedElementIds.isEmpty ||
        _originalElementProperties == null) {
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

    // 🔧 修复：在这里统一创建撤销操作，避免重复创建
    if (_originalElementProperties != null) {
      createUndoOperation(elementId, _originalElementProperties!, {
        'x': finalResult['x']!,
        'y': finalResult['y']!,
        'width': finalResult['width']!,
        'height': finalResult['height']!,
        if (finalResult.containsKey('rotation'))
          'rotation': finalResult['rotation']!,
      });
    }

    EditPageLogger.canvasDebug('控制点主导架构处理完成', data: {'elementId': elementId});
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

    // 🔧 DEBUG: 在保存之前先记录当前元素的实际状态
    if (element['type'] == 'group') {
      final content = element['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];

      // 🔧 记录组合元素内部的子元素信息
      EditPageLogger.canvasDebug('拖拽开始时的当前组合元素状态', data: {
        'groupId': element['id'],
        'groupRotation': element['rotation'],
        'childrenCount': children.length,
        'currentChildrenIds': children.map((child) {
          final childMap = child as Map<String, dynamic>;
          return childMap['id'];
        }).toList(),
        'currentChildrenPositions': children.map((child) {
          final childMap = child as Map<String, dynamic>;
          return {
            'id': childMap['id'],
            'x': childMap['x'],
            'y': childMap['y'],
            'rotation': childMap['rotation'],
          };
        }).toList(),
        'operation': 'group_internal_state_debug',
      });

      // 🔧 记录画布上所有元素的ID
      final allCanvasElements = controller.state.currentPageElements;
      EditPageLogger.canvasDebug('画布上的所有元素', data: {
        'totalElements': allCanvasElements.length,
        'allElementIds': allCanvasElements.map((e) => e['id']).toList(),
        'elementTypes':
            allCanvasElements.map((e) => '${e['id']}:${e['type']}').toList(),
        'operation': 'canvas_all_elements_debug',
      });
    }

    // 保存元素的原始属性（深拷贝，确保嵌套对象也被复制）
    _originalElementProperties = PracticeEditUtils.deepCopyElement(element);

    // 🔧 DEBUG: 添加详细的原始状态日志
    if (element['type'] == 'group') {
      final content = element['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];

      EditPageLogger.canvasDebug('保存组合元素原始状态', data: {
        'groupId': element['id'],
        'groupRotation': element['rotation'],
        'childrenCount': children.length,
        'childrenPositions': children.map((child) {
          final childMap = child as Map<String, dynamic>;
          return {
            'id': childMap['id'],
            'x': childMap['x'],
            'y': childMap['y'],
            'rotation': childMap['rotation'],
          };
        }).toList(),
        'operation': 'save_original_group_state',
      });
    }

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

    // 🔧 验证DragStateManager状态是否正确设置
    EditPageLogger.canvasDebug(
      '验证DragStateManager拖拽状态',
      data: {
        'expectedElementIds': allElementIds.toList(),
        'actualDraggingElementIds':
            dragStateManager.draggingElementIds.toList(),
        'isDragging': dragStateManager.isDragging,
        'isDragPreviewActive': dragStateManager.isDragPreviewActive,
        'elementCount': allElementIds.length,
      },
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

  /// 控制点主导架构：处理Live阶段的实时状态更新
  void handleControlPointLiveUpdate(Map<String, double> liveState) {
    if (controller.state.selectedElementIds.isEmpty ||
        _originalElementProperties == null) {
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

    // 🚀 新增：统一处理预览层和参考线层的实时更新
    _generateRealTimeGuidelines(elementId, snappedLiveState);

    // 🚀 新增：对组合元素进行Live阶段的子元素预览更新
    if (originalElement['type'] == 'group') {
      _handleGroupElementLiveUpdate(originalElement, snappedLiveState);
    } else {
      // 普通元素的Live更新
      _handleSingleElementLiveUpdate(
          elementId, originalElement, snappedLiveState);
    }
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

  /// 设置FreeControlPoints的最终状态（由FreeControlPoints调用）
  void setFreeControlPointsFinalState(Map<String, double> finalState) {
    _freeControlPointsFinalState = finalState;
  }

  /// 触发setState（由使用此mixin的类实现）
  void setState(VoidCallback fn);

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
    if (originalElementProperties != null)
      _originalElementProperties = originalElementProperties;
    if (isReadyForDrag != null) _isReadyForDrag = isReadyForDrag;
    // dragStart 和 elementStartPosition 可以被子类使用
  }

  /// 🚀 新增：统一处理参考线生成的方法
  void _generateRealTimeGuidelines(
      String elementId, Map<String, double> currentProperties) {
    EditPageLogger.editPageDebug(
        '🔍 [DEBUG] _generateRealTimeGuidelines 被调用 (来自 handleControlPointLiveUpdate)',
        data: {
          'elementId': elementId,
          'alignmentMode': controller.state.alignmentMode.toString(),
          'position': '(${currentProperties['x']}, ${currentProperties['y']})',
        });

    // 只在参考线对齐模式下生成参考线
    if (controller.state.alignmentMode != AlignmentMode.guideline) {
      EditPageLogger.editPageDebug('🔍 [DEBUG] 跳过实时参考线生成', data: {
        'reason': 'wrong_alignment_mode',
        'alignmentMode': controller.state.alignmentMode.toString(),
      });
      return;
    }

    try {
      // 🔧 关键：确保参考线管理器有最新的元素数据
      // controller.updateGuidelineManagerElements();

      EditPageLogger.editPageDebug('🔍 [DEBUG] GuidelineManager状态检查', data: {
        'enabled': GuidelineManager.instance.enabled,
        'elementsCount': GuidelineManager.instance.elementCount,
        'activeGuidelinesCount':
            GuidelineManager.instance.activeGuidelines.length,
      });

      // 确保GuidelineManager已启用
      if (!GuidelineManager.instance.enabled) {
        EditPageLogger.editPageDebug('GuidelineManager未启用，跳过实时参考线生成');
        return;
      }

      EditPageLogger.editPageDebug('🔍 [DEBUG] 准备调用 generateRealTimeGuidelines',
          data: {
            'elementId': elementId,
            'position':
                '(${currentProperties['x']}, ${currentProperties['y']})',
            'size':
                '${currentProperties['width']}x${currentProperties['height']}',
          });

      // 🚀 新增：使用实时参考线生成方法（显示所有元素的参考线）
      final hasGuidelines =
          GuidelineManager.instance.generateRealTimeGuidelines(
        draggedElementId: elementId,
        draggedPosition:
            Offset(currentProperties['x']!, currentProperties['y']!),
        draggedSize:
            Size(currentProperties['width']!, currentProperties['height']!),
      );

      EditPageLogger.editPageDebug('🔍 [DEBUG] generateRealTimeGuidelines 结果',
          data: {
            'hasGuidelines': hasGuidelines,
          });
      if (hasGuidelines) {
        // 获取生成的参考线 - 🔧 修复：创建可修改的副本，避免不可修改列表错误
        final guidelines =
            List<Guideline>.from(GuidelineManager.instance.activeGuidelines);

        // 通知控制器更新参考线渲染
        // controller.updateActiveGuidelines(guidelines);

        EditPageLogger.editPageDebug('CanvasControlPointHandlers生成实时参考线',
            data: {
              'elementId': elementId,
              'guidelinesCount': guidelines.length,
              'position':
                  '(${currentProperties['x']}, ${currentProperties['y']})',
              'size':
                  '${currentProperties['width']}x${currentProperties['height']}',
              'mode': 'real_time_display_only',
            });
      } else {
        // 没有参考线，清除现有的
        controller.updateActiveGuidelines([]);
      }
    } catch (e) {
      EditPageLogger.editPageDebug('实时参考线生成失败', data: {
        'error': e.toString(),
        'elementId': elementId,
      });
    }
  }

  /// 🚀 新增：处理组合元素的Live阶段更新
  void _handleGroupElementLiveUpdate(
      Map<String, dynamic> groupElement, Map<String, double> liveState) {
    final groupId = groupElement['id'] as String;

    // 🔧 关键修复：Live阶段需要区分"拖拽基准状态"和"当前Live状态"
    // 使用拖拽开始时保存的状态作为变换基准
    final dragStartGroupElement = _originalElementProperties!;
    final baseX = (dragStartGroupElement['x'] as num).toDouble();
    final baseY = (dragStartGroupElement['y'] as num).toDouble();
    final baseWidth = (dragStartGroupElement['width'] as num).toDouble();
    final baseHeight = (dragStartGroupElement['height'] as num).toDouble();
    final baseRotation =
        (dragStartGroupElement['rotation'] as num?)?.toDouble() ?? 0.0;

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
    if (dragStateManager.isDragging &&
        dragStateManager.isElementDragging(groupId)) {
      dragStateManager.updateElementPreviewProperties(
          groupId, groupPreviewProperties);

      // 🔧 修复：确保更新所有子元素的预览（使用拖拽基准状态的子元素）
      final content = dragStartGroupElement['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];

      if (children.isNotEmpty) {
        // 计算相对于拖拽开始时的变换增量
        final scaleX = baseWidth != 0 ? newWidth / baseWidth : 1.0;
        final scaleY = baseHeight != 0 ? newHeight / baseHeight : 1.0;
        final rotationDelta = newRotation - baseRotation;

        // 为每个子元素更新预览
        for (int i = 0; i < children.length; i++) {
          final childMap = children[i] as Map<String, dynamic>;
          final childId = childMap['id'] as String;

          // 🔧 修复：检查子元素是否在DragStateManager中
          if (dragStateManager.isElementDragging(childId)) {
            // 🔧 关键修复：获取拖拽开始时的子元素状态作为变换基准
            final dragStartContent =
                dragStartGroupElement['content'] as Map<String, dynamic>?;
            final dragStartChildren =
                dragStartContent?['children'] as List<dynamic>? ?? [];

            // 找到对应的拖拽开始时的子元素状态
            final dragStartChild = dragStartChildren.firstWhere(
              (child) => (child as Map<String, dynamic>)['id'] == childId,
              orElse: () => childMap, // 回退到当前子元素
            ) as Map<String, dynamic>;

            // 🔧 修复：子元素只需要应用组合元素的旋转变化量，不需要叠加当前旋转角度
            final transformedChild = _transformChildElement(
              dragStartChild,
              baseWidth,
              baseHeight,
              scaleX,
              scaleY,
              rotationDelta, // 只使用旋转变化量，不叠加当前角度
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

            dragStateManager.updateElementPreviewProperties(
                childId, childPreviewProperties);
          }
        }
      }
    }
  }

  /// 🚀 新增：处理组合元素的变换（包括子元素变换）
  void _handleGroupElementTransform(Map<String, dynamic> groupElement,
      Map<String, double> newGroupProperties) {
    final groupId = groupElement['id'] as String;

    // 获取原始组合元素属性
    final originalX = (groupElement['x'] as num).toDouble();
    final originalY = (groupElement['y'] as num).toDouble();
    final originalWidth = (groupElement['width'] as num).toDouble();
    final originalHeight = (groupElement['height'] as num).toDouble();
    final originalRotation =
        (groupElement['rotation'] as num?)?.toDouble() ?? 0.0;

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
    final isOnlyTranslation =
        (scaleX == 1.0 && scaleY == 1.0 && rotationDelta == 0.0);
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

      // 1. 通过controller正确更新组合元素本身的属性（不创建撤销操作）
      controller.updateElementPropertiesWithoutUndo(groupId, {
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
        final updatedGroupElement =
            controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == groupId,
          orElse: () => <String, dynamic>{},
        );

        if (updatedGroupElement.isNotEmpty) {
          final updatedContent =
              updatedGroupElement['content'] as Map<String, dynamic>?;
          final updatedChildren =
              updatedContent?['children'] as List<dynamic>? ?? [];

          for (int i = 0; i < updatedChildren.length; i++) {
            final child = updatedChildren[i] as Map<String, dynamic>;
            final childId = child['id'] as String;

            // 🔧 关键修复：获取子元素的原始状态（拖拽开始时的状态）作为变换基准
            final originalChildren = (groupElement['content']
                        as Map<String, dynamic>?)
                    ?.cast<String, dynamic>()['children'] as List<dynamic>? ??
                [];
            final originalChild = originalChildren.firstWhere(
              (c) => (c as Map<String, dynamic>)['id'] == childId,
              orElse: () => child, // 回退到当前子元素
            ) as Map<String, dynamic>;

            // 使用原始子元素状态进行变换
            final transformedChild = _transformChildElement(
              originalChild, // 使用原始子元素状态
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
      // UI更新已由markElementDirty处理，无需重复调用

      EditPageLogger.canvasDebug('组合元素变换完成', data: {
        'groupId': groupId,
        'childrenCount': children.length,
      });
    } catch (e, stackTrace) {
      EditPageLogger.editPageError('组合元素变换错误',
          error: e, stackTrace: stackTrace, data: {'groupId': groupId});
    }
  }

  /// 🚀 新增：处理单个元素的Live阶段更新
  void _handleSingleElementLiveUpdate(
      String elementId,
      Map<String, dynamic> originalElement,
      Map<String, double> snappedLiveState) {
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
    if (dragStateManager.isDragging &&
        dragStateManager.isElementDragging(elementId)) {
      dragStateManager.updateElementPreviewProperties(
          elementId, livePreviewProperties);
    }
  }

  /// 🚀 新增：处理单个元素的变换
  void _handleSingleElementTransform(String elementId,
      Map<String, dynamic> originalElement, Map<String, double> finalResult) {
    _updateSingleElement(elementId, finalResult);

    // 🔧 修复：避免重复创建撤销操作
    // 撤销操作将在handleControlPointDragEndWithState的调用者处统一创建
    // 这里只负责更新元素属性，不创建撤销操作
    EditPageLogger.canvasDebug(
      '单个元素变换完成 - 撤销操作将由调用者创建',
      data: {
        'elementId': elementId,
        'finalResult': finalResult,
        'optimization': 'avoid_duplicate_undo_operation',
      },
    );
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

    // 🔧 DEBUG: 调试子元素旋转计算
    EditPageLogger.canvasDebug('子元素旋转计算', data: {
      'childId': child['id'],
      'childOriginalRotation': childRotation,
      'groupRotationDelta': rotationDelta,
      'finalChildRotation': finalRotation,
      'operation': 'child_transform_debug'
    });

    final result = {
      'x': finalX,
      'y': finalY,
      'width': math.max(scaledWidth, 1.0), // 确保最小尺寸
      'height': math.max(scaledHeight, 1.0),
      'rotation': finalRotation,
    };

    return result;
  }

  /// 🚀 新增：更新单个元素的属性
  void _updateSingleElement(String elementId, Map<String, double> properties) {
    // 构建更新属性
    final updateProperties = <String, dynamic>{};
    properties.forEach((key, value) {
      updateProperties[key] = value;
    });

    // 更新元素属性（不创建撤销操作，因为控制点处理器会统一创建）
    controller.updateElementPropertiesWithoutUndo(elementId, updateProperties);
  }
}
