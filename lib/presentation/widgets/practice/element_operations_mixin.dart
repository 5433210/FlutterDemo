import 'dart:math' as math;

import 'package:charasgem/presentation/widgets/practice/custom_operation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../pages/practices/utils/practice_edit_utils.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 元素操作管理 Mixin
/// 负责高级元素操作，如组合/解组、分布、元素变换等
mixin ElementOperationsMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

  /// 对齐指定的元素
  void alignElements(List<String> elementIds, String alignment) {
    if (elementIds.length < 2) return; // 需要至少2个元素才能对齐

    // 获取所有要对齐的元素
    final elements = <Map<String, dynamic>>[];
    for (final id in elementIds) {
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
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['x'] = alignValue;
          }
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
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['x'] = alignValue - width;
          }
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
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['x'] = avgCenter - width / 2;
          }
        }
        break;

      case 'top':
        // 对齐到最上面的元素
        alignValue =
            elements.map((e) => (e['y'] as num).toDouble()).reduce(math.min);
        for (final element in elements) {
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['y'] = alignValue;
          }
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
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['y'] = alignValue - height;
          }
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
          final index = state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            state.currentPageElements[index]['y'] = avgCenter - height / 2;
          }
        }
        break;
    }

    // 保存新位置用于撤销操作
    final newPositions = <String, Map<String, double>>{};
    for (final element in elements) {
      final id = element['id'] as String;
      final index = state.currentPageElements.indexWhere((e) => e['id'] == id);
      if (index >= 0) {
        final currentElement = state.currentPageElements[index];
        newPositions[id] = {
          'x': (currentElement['x'] as num).toDouble(),
          'y': (currentElement['y'] as num).toDouble(),
        };
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

              if (state.selectedElementIds.contains(elementId)) {
                state.selectedElement = state.currentPageElements[index];
              }

              state.hasUnsavedChanges = true;
              notifyListeners();
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
    notifyListeners();
  }

  void checkDisposed();

  /// 创建批量元素调整大小操作（用于撤销/重做）
  void createElementResizeOperation({
    required List<String> elementIds,
    required List<Map<String, dynamic>> oldSizes,
    required List<Map<String, dynamic>> newSizes,
  }) {
    if (elementIds.isEmpty || oldSizes.isEmpty || newSizes.isEmpty) {
      debugPrint('【元素操作】createElementResizeOperation: 没有要更新的元素，跳过');
      return;
    }

    debugPrint('【元素操作】createElementResizeOperation: 创建元素调整大小操作');
    final operation = ResizeElementOperation(
      elementIds: elementIds,
      oldSizes: oldSizes,
      newSizes: newSizes,
      updateElement: (elementId, sizeProps) {
        _updateElementInCurrentPage(elementId, sizeProps);
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 创建批量元素旋转操作（用于撤销/重做）
  void createElementRotationOperation({
    required List<String> elementIds,
    required List<double> oldRotations,
    required List<double> newRotations,
  }) {
    if (elementIds.isEmpty || oldRotations.isEmpty || newRotations.isEmpty) {
      debugPrint('【元素操作】createElementRotationOperation: 没有要更新的元素，跳过');
      return;
    }

    debugPrint('【元素操作】createElementRotationOperation: 创建元素旋转操作');
    final operation = ElementRotationOperation(
      elementIds: elementIds,
      oldRotations: oldRotations,
      newRotations: newRotations,
      updateElement: (elementId, rotationProps) {
        _updateElementInCurrentPage(elementId, rotationProps);
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 创建批量元素平移操作（用于撤销/重做）
  void createElementTranslationOperation({
    required List<String> elementIds,
    required List<Map<String, dynamic>> oldPositions,
    required List<Map<String, dynamic>> newPositions,
  }) {
    if (elementIds.isEmpty || oldPositions.isEmpty || newPositions.isEmpty) {
      debugPrint('【元素操作】createElementTranslationOperation: 没有要更新的元素，跳过');
      return;
    }

    debugPrint('【元素操作】createElementTranslationOperation: 创建元素平移操作');
    final operation = ElementTranslationOperation(
      elementIds: elementIds,
      oldPositions: oldPositions,
      newPositions: newPositions,
      updateElement: (elementId, positionProps) {
        _updateElementInCurrentPage(elementId, positionProps);
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 将多个元素均匀分布
  void distributeElements(List<String> elementIds, String direction) {
    checkDisposed();

    if (elementIds.length < 3) return; // 至少需要3个元素才能分布

    // 获取元素
    final elements = elementIds
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
        final elementIndex = state.currentPageElements
            .indexWhere((e) => e['id'] == element['id']);
        if (elementIndex != -1) {
          state.currentPageElements[elementIndex]['x'] = newX;
        }
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
        final elementIndex = state.currentPageElements
            .indexWhere((e) => e['id'] == element['id']);
        if (elementIndex != -1) {
          state.currentPageElements[elementIndex]['y'] = newY;
        }
      }
    }

    // 记录变更后的状态
    final newState = Map<String, Map<String, dynamic>>.fromEntries(
      elements.map((e) {
        final index = state.currentPageElements
            .indexWhere((elem) => elem['id'] == e['id']);
        return MapEntry(
            e['id'] as String,
            index != -1
                ? Map<String, dynamic>.from(state.currentPageElements[index])
                : Map<String, dynamic>.from(e));
      }),
    );

    // 添加撤销操作
    final operation = _createCustomOperation(
      execute: () {
        // Apply the new state
        for (var entry in newState.entries) {
          final index =
              state.currentPageElements.indexWhere((e) => e['id'] == entry.key);
          if (index != -1) {
            state.currentPageElements[index]['x'] = entry.value['x'];
            state.currentPageElements[index]['y'] = entry.value['y'];
          }
        }
        notifyListeners();
      },
      undo: () {
        // Apply the old state
        for (var entry in oldState.entries) {
          final index =
              state.currentPageElements.indexWhere((e) => e['id'] == entry.key);
          if (index != -1) {
            state.currentPageElements[index]['x'] = entry.value['x'];
            state.currentPageElements[index]['y'] = entry.value['y'];
          }
        }
        notifyListeners();
      },
      description: '均匀分布元素',
    );

    undoRedoManager.addOperation(operation);
    state.hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 进入组编辑模式
  void enterGroupEditMode(String groupId) {
    checkDisposed();
    // 设置当前编辑的组ID
    // state.currentEditingGroupId = groupId;
    // 清除当前选择
    state.selectedElementIds.clear();
    // 通知UI更新
    notifyListeners();
  }

  /// 组合选中的元素
  void groupSelectedElements() {
    if (state.selectedElementIds.length <= 1) return;

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

    if (selectedElements.isEmpty) return;

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

      return {
        ...e,
        'x': x,
        'y': y,
      };
    }).toList();

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
          notifyListeners();
        }
      },
      removeElement: (id) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => e['id'] == id);

          state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeElements: (ids) {
        if (state.currentPageIndex >= 0 &&
            state.currentPageIndex < state.pages.length) {
          final page = state.pages[state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => ids.contains(e['id']));

          state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 切换元素锁定状态
  void toggleElementLock(String elementId) {
    // Implement the logic to toggle element lock state
    final currentPage = state.pages[state.currentPageIndex];
    final elements = List<Map<String, dynamic>>.from(currentPage['elements']);

    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        elements[i]['isLocked'] = !(elements[i]['isLocked'] ?? false);
        break;
      }
    }

    // Update the current page with modified elements
    final updatedPage = {...currentPage, 'elements': elements};
    state.pages[state.currentPageIndex] = updatedPage;
    state.hasUnsavedChanges = true;
    notifyListeners();
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

        notifyListeners();
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
        'id': '${childMap['type']}_${uuid.v4()}', // 生成新ID避免冲突
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
          notifyListeners();
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
          notifyListeners();
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
          notifyListeners();
        }
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 更新元素位置（带吸附功能）
  void updateElementPositionWithSnap(String id, Offset delta) {
    final elementIndex =
        state.currentPageElements.indexWhere((e) => e['id'] == id);
    if (elementIndex < 0) return;

    final element = state.currentPageElements[elementIndex];

    // 当前位置
    double x = (element['x'] as num).toDouble();
    double y = (element['y'] as num).toDouble();

    // 新位置
    double newX = x + delta.dx;
    double newY = y + delta.dy;

    // 更新元素位置（这里应该调用主控制器的方法）
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

      debugPrint('拖拽更新: 元素ID=$id, 缩放因子=$scaleFactor');

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

      // 通知监听器更新UI
      notifyListeners();
    }
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

  /// 在当前页面中更新元素
  void _updateElementInCurrentPage(
      String elementId, Map<String, dynamic> properties) {
    debugPrint('【元素操作】_updateElementInCurrentPage: 开始更新元素');
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;
      final elementIndex = elements.indexWhere((e) => e['id'] == elementId);

      if (elementIndex >= 0) {
        final element = elements[elementIndex] as Map<String, dynamic>;

        // 处理大小更新时的组合控件子元素调整
        if (element['type'] == 'group' &&
            (properties.containsKey('width') ||
                properties.containsKey('height'))) {
          final oldWidth = (element['width'] as num).toDouble();
          final oldHeight = (element['height'] as num).toDouble();

          // 更新元素属性
          properties.forEach((key, value) {
            element[key] = value;
          });

          // 获取新的尺寸
          final newWidth = (element['width'] as num).toDouble();
          final newHeight = (element['height'] as num).toDouble();

          // 计算缩放比例
          final scaleX = oldWidth > 0 ? newWidth / oldWidth : 1.0;
          final scaleY = oldHeight > 0 ? newHeight / oldHeight : 1.0;

          // 获取子元素列表
          final content = element['content'] as Map<String, dynamic>;
          final children = content['children'] as List<dynamic>;

          // 更新每个子元素的位置和大小
          for (int i = 0; i < children.length; i++) {
            final child = children[i] as Map<String, dynamic>;

            // 获取子元素的当前位置和大小
            final childX = (child['x'] as num).toDouble();
            final childY = (child['y'] as num).toDouble();
            final childWidth = (child['width'] as num).toDouble();
            final childHeight = (child['height'] as num).toDouble();

            // 根据组合控件的变形调整子元素
            child['x'] = childX * scaleX;
            child['y'] = childY * scaleY;
            child['width'] = childWidth * scaleX;
            child['height'] = childHeight * scaleY;
          }
        } else {
          // 普通元素，直接更新属性
          properties.forEach((key, value) {
            element[key] = value;
          });
        }

        // 如果是当前选中的元素，更新selectedElement
        if (state.selectedElementIds.contains(elementId)) {
          state.selectedElement = element;
        }

        state.hasUnsavedChanges = true;
        notifyListeners();
        debugPrint('【元素操作】_updateElementInCurrentPage: 更新完成');
      }
    }
  }
}
