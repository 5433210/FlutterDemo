import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../pages/practices/utils/practice_edit_utils.dart';
import 'custom_operation.dart';
import 'guideline_alignment/guideline_manager.dart' hide EditPageLogger;
import 'guideline_alignment/guideline_types.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';
import 'throttled_notification_mixin.dart'; // 包含所有节流混入
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 元素操作管理 Mixin
/// 负责高级元素操作，如组合/解组、分布、元素变换等
/// 🔧 性能优化：完全集成智能状态分发架构，避免全局UI重建
mixin ElementOperationsMixin on ChangeNotifier
    implements
        IntelligentNotificationMixin,
        ThrottledNotificationMixin,
        DragOptimizedNotificationMixin {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

  /// 对齐指定的元素
  void alignElements(List<String> elementIds, String alignment) {
    if (elementIds.length < 2) return; // 需要至少2个元素才能对齐

    // 🔒 过滤掉锁定的元素
    final operableElementIds = _filterOperableElements(elementIds);
    if (operableElementIds.length < 2) {
      EditPageLogger.controllerWarning('没有足够的未锁定元素进行对齐操作');
      return;
    }

    // 获取所有要对齐的元素
    final elements = <Map<String, dynamic>>[];
    for (final id in operableElementIds) {
      final element = state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        elements.add(element);
      }
    }

    if (elements.length < 2) return;

    // 保存原始位置用于撤销操作
    final originalPositions = <String, Map<String, double>>{};
    for (final element in elements) {
      final id = element['id'] as String;
      originalPositions[id] = {
        'x': (element['x'] as num).toDouble(),
        'y': (element['y'] as num).toDouble(),
      };
    }

    // 计算对齐位置
    double alignValue = 0;

    switch (alignment) {
      case 'left':
        // 对齐到最左边的元素
        alignValue =
            elements.map((e) => (e['x'] as num).toDouble()).reduce(math.min);
        for (final element in elements) {
          _updateElementInCurrentPage(
              element['id'] as String, {'x': alignValue});
        }
        break;

      case 'right':
        // 对齐到最右边
        alignValue = elements
            .map((e) =>
                (e['x'] as num).toDouble() + (e['width'] as num).toDouble())
            .reduce(math.max);
        for (final element in elements) {
          final width = (element['width'] as num).toDouble();
          _updateElementInCurrentPage(
              element['id'] as String, {'x': alignValue - width});
        }
        break;

      case 'centerH':
        // 水平居中对齐
        final centerValues = elements.map((e) =>
            (e['x'] as num).toDouble() + (e['width'] as num).toDouble() / 2);
        final avgCenter =
            centerValues.reduce((a, b) => a + b) / centerValues.length;

        for (final element in elements) {
          final width = (element['width'] as num).toDouble();
          _updateElementInCurrentPage(
              element['id'] as String, {'x': avgCenter - width / 2});
        }
        break;

      case 'top':
        // 对齐到最上面的元素
        alignValue =
            elements.map((e) => (e['y'] as num).toDouble()).reduce(math.min);
        for (final element in elements) {
          _updateElementInCurrentPage(
              element['id'] as String, {'y': alignValue});
        }
        break;

      case 'bottom':
        // 对齐到最下面
        alignValue = elements
            .map((e) =>
                (e['y'] as num).toDouble() + (e['height'] as num).toDouble())
            .reduce(math.max);
        for (final element in elements) {
          final height = (element['height'] as num).toDouble();
          _updateElementInCurrentPage(
              element['id'] as String, {'y': alignValue - height});
        }
        break;

      case 'centerV':
        // 垂直居中对齐
        final centerValues = elements.map((e) =>
            (e['y'] as num).toDouble() + (e['height'] as num).toDouble() / 2);
        final avgCenter =
            centerValues.reduce((a, b) => a + b) / centerValues.length;

        for (final element in elements) {
          final height = (element['height'] as num).toDouble();
          _updateElementInCurrentPage(
              element['id'] as String, {'y': avgCenter - height / 2});
        }
        break;
    }

    // 保存新位置用于撤销操作
    final newPositions = <String, Map<String, double>>{};
    if (state.currentPage != null &&
        state.currentPage!.containsKey('elements')) {
      final pageElements = state.currentPage!['elements'] as List<dynamic>;
      for (final element in elements) {
        final id = element['id'] as String;
        final index = pageElements.indexWhere((e) => e['id'] == id);
        if (index >= 0) {
          final currentElement = pageElements[index] as Map<String, dynamic>;
          newPositions[id] = {
            'x': (currentElement['x'] as num).toDouble(),
            'y': (currentElement['y'] as num).toDouble(),
          };
        }
      }
    }

    // 创建撤销操作
    final operations = <UndoableOperation>[];
    for (final id in elementIds) {
      if (originalPositions.containsKey(id) && newPositions.containsKey(id)) {
        operations.add(ElementTranslationOperation(
          elementIds: [id],
          oldPositions: [originalPositions[id]!],
          newPositions: [newPositions[id]!],
          updateElement: (elementId, positionProps) {
            final index = state.currentPageElements
                .indexWhere((e) => e['id'] == elementId);
            if (index >= 0) {
              positionProps.forEach((key, value) {
                state.currentPageElements[index][key] = value;
              });

              _undoRedoIntelligentNotify(
                elementId: elementId,
                operation: 'undo_redo_align',
              );
            }
          },
        ));
      }
    }

    if (operations.isNotEmpty) {
      final batchOperation = BatchOperation(
        operations: operations,
        operationDescription: '对齐${operations.length}个元素',
      );
      undoRedoManager.addOperation(batchOperation);
    }

    state.hasUnsavedChanges = true;

    // 🚀 使用分层架构通知元素对齐完成
    intelligentNotify(
      changeType: 'element_align_elements',
      operation: 'align_elements',
      eventData: {
        'alignmentType': alignment,
        'elementCount': operableElementIds.length,
      },
      affectedElements: elementIds,
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['canvas'],
    );
  }

  @override
  void checkDisposed();

  void clearActiveGuidelines();

  /// 创建批量元素调整大小操作（用于撤销/重做）
  void createElementResizeOperation({
    required List<String> elementIds,
    required List<Map<String, dynamic>> oldSizes,
    required List<Map<String, dynamic>> newSizes,
  }) {
    if (elementIds.isEmpty || oldSizes.isEmpty || newSizes.isEmpty) {
      EditPageLogger.controllerDebug(
        '没有要更新的元素，跳过调整大小操作',
        data: {
          'elementIds': elementIds,
          'operation': 'create_resize_operation_skip',
        },
      );
      return;
    }

    EditPageLogger.controllerDebug(
      '创建元素调整大小操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'create_resize_operation',
      },
    );

    final operation = ResizeElementOperation(
      elementIds: elementIds,
      oldSizes: oldSizes,
      newSizes: newSizes,
      updateElement: (elementId, sizeProps) {
        _updateElementInCurrentPage(elementId, sizeProps);
      },
    );

    // 不立即执行，因为状态已经在控制点处理器中更新了
    undoRedoManager.addOperation(operation, executeImmediately: false);
  }

  /// 创建批量元素旋转操作（用于撤销/重做）
  void createElementRotationOperation({
    required List<String> elementIds,
    required List<double> oldRotations,
    required List<double> newRotations,
  }) {
    if (elementIds.isEmpty || oldRotations.isEmpty || newRotations.isEmpty) {
      EditPageLogger.controllerDebug(
        '没有要更新的元素，跳过旋转操作',
        data: {
          'elementIds': elementIds,
          'operation': 'create_rotation_operation_skip',
        },
      );
      return;
    }

    EditPageLogger.controllerDebug(
      '创建元素旋转操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'create_rotation_operation',
      },
    );

    final operation = ElementRotationOperation(
      elementIds: elementIds,
      oldRotations: oldRotations,
      newRotations: newRotations,
      updateElement: (elementId, rotationProps) {
        _updateElementInCurrentPage(elementId, rotationProps);
      },
    );

    // 不立即执行，因为状态已经在控制点处理器中更新了
    undoRedoManager.addOperation(operation, executeImmediately: false);
  }

  /// 创建批量元素平移操作（用于撤销/重做）
  void createElementTranslationOperation({
    required List<String> elementIds,
    required List<Map<String, dynamic>> oldPositions,
    required List<Map<String, dynamic>> newPositions,
  }) {
    if (elementIds.isEmpty || oldPositions.isEmpty || newPositions.isEmpty) {
      EditPageLogger.controllerDebug(
        '没有要更新的元素，跳过平移操作',
        data: {
          'elementIds': elementIds,
          'operation': 'create_translation_operation_skip',
        },
      );
      return;
    }

    EditPageLogger.controllerDebug(
      '创建元素平移操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'create_translation_operation',
      },
    );

    final operation = ElementTranslationOperation(
      elementIds: elementIds,
      oldPositions: oldPositions,
      newPositions: newPositions,
      updateElement: (elementId, positionProps) {
        _updateElementInCurrentPage(elementId, positionProps);
      },
    );

    // 不立即执行，因为状态已经在控制点处理器中更新了
    undoRedoManager.addOperation(operation, executeImmediately: false);
  }

  /// 创建组合元素旋转操作 - 保存子元素的完整状态
  void createGroupElementRotationOperation({
    required String groupElementId,
    required Map<String, dynamic> oldGroupState,
    required Map<String, dynamic> newGroupState,
  }) {
    EditPageLogger.editPageDebug('创建组合元素旋转操作', data: {
      'groupElementId': groupElementId,
      'oldRotation': oldGroupState['rotation'],
      'newRotation': newGroupState['rotation'],
      'operation': 'create_group_rotation_operation',
    });

    final operation = GroupElementRotationOperation(
      groupElementId: groupElementId,
      oldGroupState: Map<String, dynamic>.from(oldGroupState),
      newGroupState: Map<String, dynamic>.from(newGroupState),
      updateElement: (id, properties) {
        _updateElementInCurrentPage(id, properties);
      },
    );

    // 不立即执行，因为状态已经在控制点处理器中更新了
    undoRedoManager.addOperation(operation, executeImmediately: false);
  }

  /// 将多个元素均匀分布
  void distributeElements(List<String> elementIds, String direction) {
    checkDisposed();

    if (elementIds.length < 3) return; // 至少需要3个元素才能分布

    // 🔒 过滤掉锁定的元素
    final operableElementIds = _filterOperableElements(elementIds);
    if (operableElementIds.length < 3) {
      EditPageLogger.controllerWarning('没有足够的未锁定元素进行分布');
      return;
    }

    // 获取元素
    final elements = operableElementIds
        .map((id) => state.currentPageElements.firstWhere((e) => e['id'] == id,
            orElse: () => <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();

    if (elements.length < 3) return;

    // 记录变更前的状态
    final oldState = Map<String, Map<String, dynamic>>.fromEntries(
      elements.map(
          (e) => MapEntry(e['id'] as String, Map<String, dynamic>.from(e))),
    );

    if (direction == 'horizontal') {
      // 按X坐标排序
      elements.sort((a, b) => (a['x'] as num).compareTo(b['x'] as num));

      // 获取第一个和最后一个元素的位置
      final firstX = elements.first['x'] as num;
      final lastX = elements.last['x'] as num;

      // 计算间距
      final totalSpacing = lastX - firstX;
      final step = totalSpacing / (elements.length - 1);

      // 分布元素
      for (int i = 1; i < elements.length - 1; i++) {
        final element = elements[i];
        final newX = firstX + (step * i);

        // 更新元素位置
        _updateElementInCurrentPage(element['id'] as String, {'x': newX});
      }
    } else if (direction == 'vertical') {
      // 按Y坐标排序
      elements.sort((a, b) => (a['y'] as num).compareTo(b['y'] as num));

      // 获取第一个和最后一个元素的位置
      final firstY = elements.first['y'] as num;
      final lastY = elements.last['y'] as num;

      // 计算间距
      final totalSpacing = lastY - firstY;
      final step = totalSpacing / (elements.length - 1);

      // 分布元素
      for (int i = 1; i < elements.length - 1; i++) {
        final element = elements[i];
        final newY = firstY + (step * i);

        // 更新元素位置
        _updateElementInCurrentPage(element['id'] as String, {'y': newY});
      }
    }

    // 记录变更后的状态
    final newState = <String, Map<String, dynamic>>{};
    if (state.currentPage != null &&
        state.currentPage!.containsKey('elements')) {
      final pageElements = state.currentPage!['elements'] as List<dynamic>;
      for (final element in elements) {
        final id = element['id'] as String;
        final index = pageElements.indexWhere((elem) => elem['id'] == id);
        if (index != -1) {
          newState[id] = Map<String, dynamic>.from(
              pageElements[index] as Map<String, dynamic>);
        } else {
          newState[id] = Map<String, dynamic>.from(element);
        }
      }
    }

    // 添加撤销操作
    final operation = _createCustomOperation(
      execute: () {
        // Apply the new state
        for (var entry in newState.entries) {
          _updateElementInCurrentPage(entry.key, {
            'x': entry.value['x'],
            'y': entry.value['y'],
          });
        }
        // 使用智能通知系统
        intelligentNotify(
          changeType: 'element_redo_distribute',
          operation: 'redo_distribute',
          eventData: {
            'elementIds': newState.keys.toList(),
          },
          affectedElements: newState.keys.toList(),
          affectedLayers: ['content', 'interaction'],
          affectedUIComponents: ['canvas'],
        );
      },
      undo: () {
        // Apply the old state
        for (var entry in oldState.entries) {
          _updateElementInCurrentPage(entry.key, {
            'x': entry.value['x'],
            'y': entry.value['y'],
          });
        }
        // 使用智能通知系统
        intelligentNotify(
          changeType: 'element_undo_distribute',
          operation: 'undo_distribute',
          eventData: {
            'elementIds': oldState.keys.toList(),
          },
          affectedElements: oldState.keys.toList(),
          affectedLayers: ['content', 'interaction'],
          affectedUIComponents: ['canvas'],
        );
      },
      description: '均匀分布元素',
    );

    undoRedoManager.addOperation(operation);
    state.hasUnsavedChanges = true;

    // 🚀 使用分层架构通知元素分布完成
    intelligentNotify(
      changeType: 'element_distribute_elements',
      operation: 'distribute_elements',
      eventData: {
        'direction': direction,
        'elementCount': elements.length,
      },
      affectedElements: elements.map((e) => e['id'] as String).toList(),
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['canvas'],
    );
  }

  /// 进入组编辑模式
  void enterGroupEditMode(String groupId) {
    checkDisposed();
    // 设置当前编辑的组ID
    // state.currentEditingGroupId = groupId;
    // 清除当前选择
    state.selectedElementIds.clear();

    // 🚀 使用分层架构通知选择变化
    intelligentNotify(
      changeType: 'element_selection_change',
      operation: 'enter_group_edit_mode',
      eventData: {
        'selectedIds': state.selectedElementIds,
        'operation': 'enter_group_edit_mode',
        'groupId': groupId,
      },
      affectedElements: state.selectedElementIds,
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['canvas'],
    );
  }

  /// 组合选中的元素
  void groupSelectedElements() {
    EditPageLogger.editPageDebug('🔧 Group操作开始', data: {
      'selectedElementIds': state.selectedElementIds,
      'selectedCount': state.selectedElementIds.length,
      'operation': 'group_start',
    });

    if (state.selectedElementIds.length <= 1) {
      EditPageLogger.editPageDebug('🔧 Group操作跳过：选中元素不足', data: {
        'selectedCount': state.selectedElementIds.length,
        'operation': 'group_skip_insufficient_elements',
      });
      return;
    }

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;

    // 收集要组合的元素
    final selectedElements = <Map<String, dynamic>>[];
    for (final id in state.selectedElementIds) {
      final element = elements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        selectedElements.add(Map<String, dynamic>.from(element));
      }
    }

    EditPageLogger.editPageDebug('🔧 Group操作：收集到元素', data: {
      'selectedElementIds': state.selectedElementIds,
      'foundElementsCount': selectedElements.length,
      'foundElementIds': selectedElements.map((e) => e['id']).toList(),
      'operation': 'group_collect_elements',
    });

    if (selectedElements.isEmpty) {
      EditPageLogger.editPageDebug('🔧 Group操作失败：没有找到有效元素', data: {
        'selectedElementIds': state.selectedElementIds,
        'operation': 'group_no_valid_elements',
      });
      return;
    }

    // 计算组合元素的边界
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in selectedElements) {
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x + width);
      maxY = math.max(maxY, y + height);
    }

    // 创建相对于组边界的子元素
    final groupChildren = selectedElements.map((e) {
      final x = (e['x'] as num).toDouble() - minX;
      final y = (e['y'] as num).toDouble() - minY;

      final childElement = {
        ...e,
        'x': x,
        'y': y,
      };

      EditPageLogger.editPageDebug('🔧 Group操作：创建子元素', data: {
        'originalId': e['id'],
        'childId': childElement['id'],
        'originalPos': {'x': e['x'], 'y': e['y']},
        'relativePos': {'x': x, 'y': y},
        'operation': 'group_create_child',
      });

      return childElement;
    }).toList();

    EditPageLogger.editPageDebug('🔧 Group操作：所有子元素ID', data: {
      'childrenIds': groupChildren.map((e) => e['id']).toList(),
      'childrenCount': groupChildren.length,
      'operation': 'group_children_created',
    });

    // 创建组合元素
    final groupElement = {
      'id': 'group_${uuid.v4()}',
      'type': 'group',
      'x': minX,
      'y': minY,
      'width': maxX - minX,
      'height': maxY - minY,
      'rotation': 0.0,
      'layerId': selectedElements.first['layerId'],
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '组合元素',
      'content': {
        'children': groupChildren,
      },
    };

    EditPageLogger.editPageDebug('🔧 Group操作：组合元素创建', data: {
      'groupId': groupElement['id'],
      'groupBounds': {
        'x': minX,
        'y': minY,
        'width': maxX - minX,
        'height': maxY - minY
      },
      'childrenInGroup':
          groupElement['content']['children'].map((e) => e['id']).toList(),
      'operation': 'group_element_created',
    });

    final operation = GroupElementsOperation(
      elements: selectedElements,
      groupElement: groupElement,
      addElement: (e) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.add(e);

          // 选中新的组合元素
          state.selectedElementIds = [e['id'] as String];
          state.selectedElement = e;

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知组合元素添加
          intelligentNotify(
            changeType: 'element_add_group_element',
            operation: 'add_group_element',
            eventData: {
              'elementId': e['id'],
              'selectedIds': state.selectedElementIds,
            },
            affectedElements: [e['id'] as String],
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
      removeElement: (id) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => e['id'] == id);

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知元素移除
          intelligentNotify(
            changeType: 'element_remove_element',
            operation: 'remove_element',
            eventData: {
              'elementId': id,
            },
            affectedElements: [id],
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
      removeElements: (ids) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => ids.contains(e['id']));

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知批量元素移除
          intelligentNotify(
            changeType: 'element_remove_elements',
            operation: 'remove_elements',
            eventData: {
              'elementIds': ids,
            },
            affectedElements: ids,
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
    );

    EditPageLogger.editPageDebug('🔧 Group操作：创建撤销操作', data: {
      'groupElementId': groupElement['id'],
      'originalElementsCount': selectedElements.length,
      'originalElementIds': selectedElements.map((e) => e['id']).toList(),
      'operation': 'group_create_undo_operation',
    });

    undoRedoManager.addOperation(operation);

    EditPageLogger.editPageDebug('🔧 Group操作完成', data: {
      'groupElementId': groupElement['id'],
      'operation': 'group_completed',
    });
  }

  /// 切换元素锁定状态
  void toggleElementLock(String elementId) {
    // Implement the logic to toggle element lock state
    final currentPage = state.pages[state.currentPageIndex];
    final elements = List<Map<String, dynamic>>.from(currentPage['elements']);

    bool isNowLocked = false;
    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        isNowLocked = !(elements[i]['isLocked'] ?? false);
        elements[i]['isLocked'] = isNowLocked;
        break;
      }
    }

    // Update the current page with modified elements
    final updatedPage = {...currentPage, 'elements': elements};
    state.pages[state.currentPageIndex] = updatedPage;
    state.hasUnsavedChanges = true;

    // 🚀 使用分层架构通知元素锁定状态变化
    intelligentNotify(
      changeType: 'element_toggle_element_lock',
      operation: 'toggle_element_lock',
      eventData: {
        'elementId': elementId,
        'isLocked': isNowLocked,
      },
      affectedElements: [elementId],
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['canvas'],
    );
  }

  /// 解组元素
  void ungroupElements(String groupId) {
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;
      final index = elements.indexWhere((e) => e['id'] == groupId);

      if (index >= 0 && elements[index]['type'] == 'group') {
        final group = elements[index] as Map<String, dynamic>;
        final content = group['content'] as Map<String, dynamic>;
        final groupChildren = content['children'] as List<dynamic>;

        // 获取组合元素坐标
        final groupX = (group['x'] as num).toDouble();
        final groupY = (group['y'] as num).toDouble();

        // 删除组
        elements.removeAt(index);

        // 添加组中的所有元素（调整为全局坐标）
        final newElementIds = <String>[];
        for (final childElement in groupChildren) {
          // Use PracticeEditUtils for deep copying to maintain consistency
          final child = PracticeEditUtils.deepCopyElement(
              childElement as Map<String, dynamic>);

          // 计算全局坐标
          final childX = (child['x'] as num).toDouble() + groupX;
          final childY = (child['y'] as num).toDouble() + groupY;

          // 创建新元素
          final newElement = {
            ...child,
            'x': childX,
            'y': childY,
          };

          elements.add(newElement);
          newElementIds.add(newElement['id'] as String);
        }

        // 更新选中的元素
        state.selectedElementIds = newElementIds;
        state.selectedElement = null;
        state.hasUnsavedChanges = true;

        // 🚀 使用分层架构通知解组操作完成
        intelligentNotify(
          changeType: 'element_ungroup_elements',
          operation: 'ungroup_elements',
          eventData: {
            'groupId': groupId,
            'newElementIds': newElementIds,
            'selectedIds': state.selectedElementIds,
          },
          affectedElements: newElementIds,
          affectedLayers: ['content', 'interaction'],
          affectedUIComponents: ['canvas'],
        );
      }
    }
  }

  /// 取消组合选中的元素
  void ungroupSelectedElement() {
    if (state.selectedElementIds.length != 1) {
      return;
    }

    // Check if the selected element is a group
    if (state.selectedElement == null ||
        state.selectedElement!['type'] != 'group') {
      return;
    }

    final groupElement = Map<String, dynamic>.from(state.selectedElement!);
    final content = groupElement['content'] as Map<String, dynamic>;
    final children = content['children'] as List<dynamic>;

    if (children.isEmpty) return;

    // 转换子元素的坐标为全局坐标
    final groupX = (groupElement['x'] as num).toDouble();
    final groupY = (groupElement['y'] as num).toDouble();

    final childElements = children.map((child) {
      final childMap = Map<String, dynamic>.from(child as Map<String, dynamic>);
      final x = (childMap['x'] as num).toDouble() + groupX;
      final y = (childMap['y'] as num).toDouble() + groupY;

      return {
        ...childMap,
        'x': x,
        'y': y,
      };
    }).toList();

    final operation = UngroupElementOperation(
      groupElement: groupElement,
      childElements: childElements,
      addElement: (e) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.add(e);

          // 选中组合元素
          state.selectedElementIds = [e['id'] as String];
          state.selectedElement = e;

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知解组添加元素
          intelligentNotify(
            changeType: 'element_ungroup_add_element',
            operation: 'ungroup_add_element',
            eventData: {
              'elementId': e['id'],
              'selectedIds': state.selectedElementIds,
            },
            affectedElements: [e['id'] as String],
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
      removeElement: (id) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => e['id'] == id);

          // 如果是当前选中的元素，清除选择
          if (state.selectedElementIds.contains(id)) {
            state.selectedElementIds.clear();
            state.selectedElement = null;
          }

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知解组移除元素
          intelligentNotify(
            changeType: 'element_ungroup_remove_element',
            operation: 'ungroup_remove_element',
            eventData: {
              'elementId': id,
              'selectedIds': state.selectedElementIds,
            },
            affectedElements: [id],
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
      addElements: (elements) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final pageElements = page['elements'] as List<dynamic>;
          pageElements.addAll(elements);

          // 选中所有子元素
          state.selectedElementIds =
              elements.map((e) => e['id'] as String).toList();
          state.selectedElement = null; // 多选时不显示单个元素的属性

          state.hasUnsavedChanges = true;

          // 🚀 使用分层架构通知解组批量添加元素
          intelligentNotify(
            changeType: 'element_ungroup_add_elements',
            operation: 'ungroup_add_elements',
            eventData: {
              'elementIds': elements.map((e) => e['id'] as String).toList(),
              'selectedIds': state.selectedElementIds,
            },
            affectedElements: elements.map((e) => e['id'] as String).toList(),
            affectedLayers: ['content', 'interaction'],
            affectedUIComponents: ['canvas'],
          );
        }
      },
    );

    undoRedoManager.addOperation(operation);
  }

  // 抽象方法声明，需要在实现类中定义
  void updateActiveGuidelines(List<Guideline> guidelines);

  /// 更新元素位置（带吸附功能）
  void updateElementPositionWithSnap(String id, Offset delta) {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('elements')) {
      return;
    }

    final elements = state.currentPage!['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);
    if (elementIndex < 0) return;

    final element = elements[elementIndex] as Map<String, dynamic>;

    // 当前位置
    double x = (element['x'] as num).toDouble();
    double y = (element['y'] as num).toDouble();

    // 新位置
    double newX = x + delta.dx;
    double newY = y + delta.dy;

    // 更新元素位置
    _updateElementInCurrentPage(id, {'x': newX, 'y': newY});
  }

  /// 更新元素属性 - 拖动过程中使用，使用平滑吸附
  void updateElementPropertiesDuringDragWithSmooth(
      String id, Map<String, dynamic> properties,
      {double scaleFactor = 1.0}) {
    if (state.currentPageIndex >= state.pages.length) return;

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      final element = elements[elementIndex] as Map<String, dynamic>;

      EditPageLogger.controllerDebug(
        '拖拽更新元素属性',
        data: {
          'elementId': id,
          'scaleFactor': scaleFactor,
          'operation': 'drag_update',
        },
      );

      // 🔧 新增：参考线对齐检测 (单选拖拽时)
      if (state.alignmentMode == AlignmentMode.guideline &&
          state.selectedElementIds.length == 1 &&
          properties.containsKey('x') &&
          properties.containsKey('y')) {
        final alignedProperties =
            _applyGuidelineAlignmentForDrag(id, properties);
        if (alignedProperties != null) {
          properties = alignedProperties;
          EditPageLogger.controllerDebug('单选拖拽参考线对齐生效', data: {
            'elementId': id,
            'alignedPosition': '${properties['x']}, ${properties['y']}',
          });
        }
      }

      // 确保大小不小于最小值
      if (properties.containsKey('width')) {
        double width = (properties['width'] as num).toDouble();
        properties['width'] = math.max(width, 10.0);
      }
      if (properties.containsKey('height')) {
        double height = (properties['height'] as num).toDouble();
        properties['height'] = math.max(height, 10.0);
      }

      // 直接更新元素属性，不记录撤销/重做
      properties.forEach((key, value) {
        if (key == 'content' && element.containsKey('content')) {
          // 对于content对象，合并而不是替换
          final content = element['content'] as Map<String, dynamic>;
          final newContent = value as Map<String, dynamic>;
          newContent.forEach((contentKey, contentValue) {
            content[contentKey] = contentValue;
          });
        } else {
          element[key] = value;
        }
      });

      // 如果是当前选中的元素，更新selectedElement
      if (state.selectedElementIds.contains(id)) {
        state.selectedElement = element;
      }

      // 🚀 性能重大优化：使用分层架构精确更新
      // 只重建Content和DragPreview层，避免全局Canvas重建
      intelligentNotify(
        changeType: 'element_drag_update',
        operation: 'drag_element_update',
        eventData: {
          'elementIds': [id],
          'properties': properties.keys.toList(),
        },
        affectedElements: [id],
        affectedLayers: ['content', 'interaction'],
        affectedUIComponents: ['canvas'],
      );
    }
  }

  /// 应用参考线对齐到拖拽元素
  /// 返回对齐后的属性，如果没有对齐则返回null
  Map<String, dynamic>? _applyGuidelineAlignmentForDrag(
      String elementId, Map<String, dynamic> properties) {
    if (state.alignmentMode != AlignmentMode.guideline) {
      return null;
    }

    final element = state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return null;

    // 获取当前位置和尺寸
    final currentX = (properties['x'] as num?)?.toDouble() ??
        (element['x'] as num).toDouble();
    final currentY = (properties['y'] as num?)?.toDouble() ??
        (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    final currentBounds = Rect.fromLTWH(currentX, currentY, width, height);

    final alignmentResult = GuidelineManager.instance.detectAlignment(
      elementId: elementId,
      currentPosition: currentBounds.topLeft,
      elementSize: currentBounds.size,
    );

    if (alignmentResult != null && alignmentResult['hasAlignment'] == true) {
      // 计算对齐后的位置
      final alignedPosition = alignmentResult['position'] as Offset;

      // 更新活动参考线用于渲染
      final guidelines = alignmentResult['guidelines'] as List<Guideline>;
      updateActiveGuidelines(guidelines);

      EditPageLogger.controllerDebug('拖拽参考线对齐生效', data: {
        'elementId': elementId,
        'originalPosition': '$currentX, $currentY',
        'alignedPosition': '${alignedPosition.dx}, ${alignedPosition.dy}',
        'guidelinesCount': guidelines.length,
      });

      // 返回更新后的属性
      final alignedProperties = Map<String, dynamic>.from(properties);
      alignedProperties['x'] = alignedPosition.dx;
      alignedProperties['y'] = alignedPosition.dy;
      return alignedProperties;
    } else {
      // 🔧 修复：拖拽过程中不清空参考线，让用户能看到所有可能的对齐目标
      // 参考线只在拖拽结束时清空，而不是在每次对齐检查失败时清空
      EditPageLogger.controllerDebug('拖拽参考线对齐未生效，保持现有参考线显示', data: {
        'elementId': elementId,
        'currentPosition': '$currentX, $currentY',
        'reason': 'no_alignment_found_but_preserving_guidelines_during_drag',
      });
      return null;
    }
  }

  /// 检查元素是否可以被操作（未锁定）
  bool _canOperateElement(String elementId) {
    // 查找元素
    final element = state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return false;

    // 检查元素本身是否锁定
    final isElementLocked = element['locked'] as bool? ?? false;
    if (isElementLocked) {
      EditPageLogger.controllerDebug('元素已锁定，跳过操作',
          data: {'elementId': elementId});
      return false;
    }

    // 检查元素所在图层是否锁定
    final layerId = element['layerId'] as String?;
    if (layerId != null) {
      final layer = state.layers.firstWhere(
        (l) => l['id'] == layerId,
        orElse: () => <String, dynamic>{},
      );
      final isLayerLocked = layer['isLocked'] as bool? ?? false;
      if (isLayerLocked) {
        EditPageLogger.controllerDebug(
          '图层已锁定，跳过元素操作',
          data: {
            'layerId': layerId,
            'elementId': elementId,
            'operation': 'lock_check',
          },
        );
        return false;
      }
    }

    return true;
  }

  /// 创建自定义操作
  UndoableOperation _createCustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required String description,
  }) {
    return CustomOperation(
      execute: execute,
      undo: undo,
      description: description,
    );
  }

  /// 过滤出可以操作的元素ID列表
  List<String> _filterOperableElements(List<String> elementIds) {
    final operableIds = elementIds.where(_canOperateElement).toList();

    if (operableIds.length != elementIds.length) {
      final lockedCount = elementIds.length - operableIds.length;
      EditPageLogger.controllerWarning(
        '跳过锁定元素',
        data: {
          'totalElements': elementIds.length,
          'lockedCount': lockedCount,
          'operableCount': operableIds.length,
          'operation': 'filter_locked_elements',
        },
      );
    }

    return operableIds;
  }

  /// 撤销/重做操作专用的更新方法
  /// 用于撤销操作的回调函数中，确保UI正确更新
  void _undoRedoIntelligentNotify({
    required String elementId,
    required String operation,
  }) {
    // 更新选中元素状态
    if (state.selectedElementIds.contains(elementId)) {
      final index =
          state.currentPageElements.indexWhere((e) => e['id'] == elementId);
      if (index >= 0) {
        state.selectedElement = state.currentPageElements[index];
      }
    }

    state.hasUnsavedChanges = true;

    // 🚀 使用新的智能通知架构
    intelligentNotify(
      changeType: 'element_undo_redo',
      operation: operation,
      eventData: {
        'elementId': elementId,
        'operation': operation,
        'source': 'undo_redo',
        'timestamp': DateTime.now().toIso8601String(),
      },
      affectedElements: [elementId],
      affectedLayers: ['content', 'interaction'],
      affectedUIComponents: ['property_panel', 'canvas'],
    );
  }

  /// 辅助方法：正确更新当前页面中的元素
  void _updateElementInCurrentPage(
      String elementId, Map<String, dynamic> properties) {
    EditPageLogger.controllerInfo(
      '🔧 DEBUG: _updateElementInCurrentPage 开始执行',
      data: {
        'elementId': elementId,
        'properties': properties.keys.toList(),
        'operation': 'updateElement_debug',
      },
    );

    if (state.currentPage == null ||
        !state.currentPage!.containsKey('elements')) {
      EditPageLogger.controllerError(
        '🔧 DEBUG: 当前页面无效',
        data: {
          'elementId': elementId,
          'operation': 'updateElement_failed_debug',
        },
      );
      return;
    }

    final elements = state.currentPage!['elements'] as List<dynamic>;
    final index = elements.indexWhere((e) => e['id'] == elementId);
    if (index >= 0) {
      final element = elements[index] as Map<String, dynamic>;

      EditPageLogger.controllerInfo(
        '🔧 DEBUG: 找到元素，开始更新属性',
        data: {
          'elementId': elementId,
          'elementIndex': index,
          'oldProperties': {
            'x': element['x'],
            'y': element['y'],
            'width': element['width'],
            'height': element['height'],
          },
          'newProperties': properties,
          'operation': 'updateElement_found_debug',
        },
      );

      // 🔧 修复：对于组合元素的完整状态更新，直接替换整个元素
      if (element['type'] == 'group' && properties.containsKey('content')) {
        EditPageLogger.controllerInfo(
          '🔧 检测到组合元素完整状态更新',
          data: {
            'groupElementId': elementId,
            'isCompleteStateUpdate': true,
            'operation': 'group_complete_state_update',
          },
        );

        // 完整替换元素状态
        elements[index] = Map<String, dynamic>.from(properties);
      } else {
        // 逐个更新属性
        properties.forEach((key, value) {
          element[key] = value;
        });
      }

      // 更新选中元素的状态
      if (state.selectedElementIds.contains(elementId)) {
        state.selectedElement = elements[index] as Map<String, dynamic>;
        EditPageLogger.controllerInfo(
          '🔧 DEBUG: 更新选中元素状态',
          data: {
            'elementId': elementId,
            'operation': 'updateSelected_debug',
          },
        );
      }

      state.hasUnsavedChanges = true;

      // 🔧 关键修复：强制重新渲染
      // 通过修改元素的一个内部属性，确保缓存失效
      final currentElement = elements[index] as Map<String, dynamic>;
      currentElement['_forceRender'] = DateTime.now().millisecondsSinceEpoch;

      // 特别处理组合元素，清除其缓存
      if (currentElement['type'] == 'group') {
        // 强制设置一个变化的内部标识
        final content =
            currentElement['content'] as Map<String, dynamic>? ?? {};
        content['_cacheKey'] = DateTime.now().millisecondsSinceEpoch;
        currentElement['content'] = content;
      }

      EditPageLogger.controllerInfo(
        '🔧 DEBUG: 强制元素重新渲染',
        data: {
          'elementId': elementId,
          'forceRender': currentElement['_forceRender'],
          'isGroup': currentElement['type'] == 'group',
          'operation': 'force_rerender_debug',
        },
      );

      EditPageLogger.controllerInfo(
        '🔧 性能优化：使用分层架构更新UI',
        data: {
          'elementId': elementId,
          'operation': 'layer_architecture_update',
        },
      );

      // 🚀 使用分层架构进行精确更新
      intelligentNotify(
        changeType: 'element_update_element_properties',
        operation: 'update_element_properties',
        eventData: {
          'elementIds': [elementId],
          'properties': properties.keys.toList(),
        },
        affectedElements: [elementId],
        affectedLayers: ['content', 'interaction'],
        affectedUIComponents: ['canvas'],
      );

      EditPageLogger.controllerInfo(
        '🔧 DEBUG: _updateElementInCurrentPage 执行完成',
        data: {
          'elementId': elementId,
          'operation': 'updateElement_complete_debug',
        },
      );
    } else {
      EditPageLogger.controllerError(
        '🔧 DEBUG: 未找到要更新的元素',
        data: {
          'elementId': elementId,
          'totalElements': elements.length,
          'operation': 'updateElement_notfound_debug',
        },
      );
    }
  }
}
