import 'package:flutter/foundation.dart';

/// 添加元素操作
class AddElementOperation implements UndoableOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  AddElementOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
  });

  @override
  String get description => '添加${element['type']}元素';

  @override
  void execute() {
    addElement(element);
  }

  @override
  void undo() {
    removeElement(element['id'] as String);
  }
}

/// 添加图层操作
class AddLayerOperation implements UndoableOperation {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) addLayer;
  final Function(String) removeLayer;

  AddLayerOperation({
    required this.layer,
    required this.addLayer,
    required this.removeLayer,
  });

  @override
  String get description => '添加图层';

  @override
  void execute() {
    addLayer(layer);
  }

  @override
  void undo() {
    removeLayer(layer['id'] as String);
  }
}

/// 添加页面操作
class AddPageOperation implements UndoableOperation {
  final Map<String, dynamic> page;
  final Function(Map<String, dynamic>) addPage;
  final Function(String) removePage;

  AddPageOperation({
    required this.page,
    required this.addPage,
    required this.removePage,
  });

  @override
  String get description => '添加页面';

  @override
  void execute() {
    addPage(page);
  }

  @override
  void undo() {
    removePage(page['id'] as String);
  }
}

/// 批量操作
class BatchOperation implements UndoableOperation {
  final List<UndoableOperation> operations;
  final String operationDescription;

  BatchOperation({
    required this.operations,
    required this.operationDescription,
  });

  @override
  String get description => operationDescription;

  @override
  void execute() {
    for (final operation in operations) {
      operation.execute();
    }
  }

  @override
  void undo() {
    // 逆序执行撤销
    for (int i = operations.length - 1; i >= 0; i--) {
      operations[i].undo();
    }
  }
}

/// 元素置于顶层操作
class BringElementToFrontOperation extends ElementLayerOperation {
  BringElementToFrontOperation({
    required String elementId,
    required int oldIndex,
    required int newIndex,
    required Function(String, int, int) reorderElement,
  }) : super(
          elementId: elementId,
          oldIndex: oldIndex,
          newIndex: newIndex,
          reorderElement: reorderElement,
        );

  @override
  String get description => '置于顶层';
}

/// 删除元素操作
class DeleteElementOperation implements UndoableOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  DeleteElementOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
  });

  @override
  String get description => '删除${element['type']}元素';

  @override
  void execute() {
    removeElement(element['id'] as String);
  }

  @override
  void undo() {
    addElement(element);
  }
}

/// 删除图层操作
class DeleteLayerOperation implements UndoableOperation {
  final Map<String, dynamic> layer;
  final int layerIndex;
  final List<Map<String, dynamic>> elementsOnLayer;
  final Function(Map<String, dynamic>, int) insertLayer;
  final Function(String) removeLayer;
  final Function(List<Map<String, dynamic>>) addElements;

  DeleteLayerOperation({
    required this.layer,
    required this.layerIndex,
    required this.elementsOnLayer,
    required this.insertLayer,
    required this.removeLayer,
    required this.addElements,
  });

  @override
  String get description => '删除图层';

  @override
  void execute() {
    removeLayer(layer['id'] as String);
  }

  @override
  void undo() {
    insertLayer(layer, layerIndex);

    if (elementsOnLayer.isNotEmpty) {
      addElements(elementsOnLayer);
    }
  }
}

/// 删除页面操作
class DeletePageOperation implements UndoableOperation {
  final Map<String, dynamic> page;
  final int pageIndex;
  final Function(Map<String, dynamic>, int) insertPage;
  final Function(String) removePage;

  DeletePageOperation({
    required this.page,
    required this.pageIndex,
    required this.insertPage,
    required this.removePage,
  });

  @override
  String get description => '删除页面';

  @override
  void execute() {
    removePage(page['id'] as String);
  }

  @override
  void undo() {
    insertPage(page, pageIndex);
  }
}

/// 元素层次操作基类
abstract class ElementLayerOperation implements UndoableOperation {
  final String elementId;
  final int oldIndex;
  final int newIndex;
  final Function(String, int, int) reorderElement;

  ElementLayerOperation({
    required this.elementId,
    required this.oldIndex,
    required this.newIndex,
    required this.reorderElement,
  });

  @override
  void execute() {
    reorderElement(elementId, oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderElement(elementId, newIndex, oldIndex);
  }
}

/// 元素属性修改操作
class ElementPropertyOperation implements UndoableOperation {
  final String elementId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(String, Map<String, dynamic>) updateElement;

  ElementPropertyOperation({
    required this.elementId,
    required this.oldProperties,
    required this.newProperties,
    required this.updateElement,
  });

  @override
  String get description => '修改元素属性';

  @override
  void execute() {
    try {
      updateElement(elementId, newProperties);
    } catch (e) {
      debugPrint('【撤销/重做】ElementPropertyOperation.execute: 执行失败: $e');
    }
  }

  @override
  void undo() {
    try {
      updateElement(elementId, oldProperties);
    } catch (e) {
      debugPrint('【撤销/重做】ElementPropertyOperation.undo: 撤销失败: $e');
    }
  }
}

/// 元素旋转操作
class ElementRotationOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<double> oldRotations;
  final List<double> newRotations;
  final Function(String, Map<String, dynamic>) updateElement;

  ElementRotationOperation({
    required this.elementIds,
    required this.oldRotations,
    required this.newRotations,
    required this.updateElement,
  });

  @override
  String get description => '旋转${elementIds.length}个元素';

  @override
  void execute() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], {'rotation': newRotations[i]});
    }
  }

  @override
  void undo() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], {'rotation': oldRotations[i]});
    }
  }
}

/// 元素移动操作
class ElementTranslationOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<Map<String, dynamic>> oldPositions; // 存储原始的x,y位置
  final List<Map<String, dynamic>> newPositions; // 存储新的x,y位置
  final Function(String, Map<String, dynamic>) updateElement;

  ElementTranslationOperation({
    required this.elementIds,
    required this.oldPositions,
    required this.newPositions,
    required this.updateElement,
  });

  @override
  String get description => '移动${elementIds.length}个元素';

  @override
  void execute() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], newPositions[i]);
    }
  }

  @override
  void undo() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], oldPositions[i]);
    }
  }
}

/// 应用格式刷操作
class FormatPainterOperation implements UndoableOperation {
  final List<String> targetElementIds;
  final List<Map<String, dynamic>> oldPropertiesList;
  final List<Map<String, dynamic>> newPropertiesList;
  final Function(String, Map<String, dynamic>) updateElement;

  FormatPainterOperation({
    required this.targetElementIds,
    required this.oldPropertiesList,
    required this.newPropertiesList,
    required this.updateElement,
  });

  @override
  String get description => '应用格式刷到${targetElementIds.length}个元素';

  @override
  void execute() {
    for (int i = 0; i < targetElementIds.length; i++) {
      updateElement(targetElementIds[i], newPropertiesList[i]);
    }
  }

  @override
  void undo() {
    for (int i = 0; i < targetElementIds.length; i++) {
      updateElement(targetElementIds[i], oldPropertiesList[i]);
    }
  }
}

/// 组合元素操作
class GroupElementsOperation implements UndoableOperation {
  final List<Map<String, dynamic>> elements;
  final Map<String, dynamic> groupElement;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;
  final Function(List<String>) removeElements;

  GroupElementsOperation({
    required this.elements,
    required this.groupElement,
    required this.addElement,
    required this.removeElement,
    required this.removeElements,
  });

  @override
  String get description => '组合${elements.length}个元素';

  @override
  void execute() {
    // 添加组合元素
    addElement(groupElement);

    // 移除原始元素
    final elementIds = elements.map((e) => e['id'] as String).toList();
    removeElements(elementIds);
  }

  @override
  void undo() {
    // 移除组合元素
    removeElement(groupElement['id'] as String);

    // 恢复原始元素
    for (final element in elements) {
      addElement(element);
    }
  }
}

/// 元素下移一层操作
class MoveElementDownOperation extends ElementLayerOperation {
  MoveElementDownOperation({
    required String elementId,
    required int oldIndex,
    required int newIndex,
    required Function(String, int, int) reorderElement,
  }) : super(
          elementId: elementId,
          oldIndex: oldIndex,
          newIndex: newIndex,
          reorderElement: reorderElement,
        );

  @override
  String get description => '下移一层';
}

/// 元素上移一层操作
class MoveElementUpOperation extends ElementLayerOperation {
  MoveElementUpOperation({
    required String elementId,
    required int oldIndex,
    required int newIndex,
    required Function(String, int, int) reorderElement,
  }) : super(
          elementId: elementId,
          oldIndex: oldIndex,
          newIndex: newIndex,
          reorderElement: reorderElement,
        );

  @override
  String get description => '上移一层';
}

/// 粘贴元素操作
class PasteElementOperation implements UndoableOperation {
  final List<Map<String, dynamic>> newElements;
  final Function(List<Map<String, dynamic>>) addElements;
  final Function(List<String>) removeElements;

  PasteElementOperation({
    required this.newElements,
    required this.addElements,
    required this.removeElements,
  });

  @override
  String get description => '粘贴${newElements.length}个元素';

  @override
  void execute() {
    // 添加新元素
    addElements(newElements);
  }

  @override
  void undo() {
    // 移除粘贴的元素
    final elementIds = newElements.map((e) => e['id'] as String).toList();
    removeElements(elementIds);
  }
}

/// 重新排序图层操作
class ReorderLayerOperation implements UndoableOperation {
  final int oldIndex;
  final int newIndex;
  final Function(int, int) reorderLayer;

  ReorderLayerOperation({
    required this.oldIndex,
    required this.newIndex,
    required this.reorderLayer,
  });

  @override
  String get description => '重新排序图层';

  @override
  void execute() {
    reorderLayer(oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderLayer(newIndex, oldIndex);
  }
}

/// 重新排序页面操作
class ReorderPageOperation implements UndoableOperation {
  final int oldIndex;
  final int newIndex;
  final Function(int, int) reorderPage;

  ReorderPageOperation({
    required this.oldIndex,
    required this.newIndex,
    required this.reorderPage,
  });

  @override
  String get description => '重新排序页面';

  @override
  void execute() {
    reorderPage(oldIndex, newIndex);
  }

  @override
  void undo() {
    // 撤销时需要反向处理索引
    reorderPage(newIndex, oldIndex);
  }
}

/// 元素调整大小操作
class ResizeElementOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<Map<String, dynamic>> oldSizes; // 存储原始的宽度、高度
  final List<Map<String, dynamic>> newSizes; // 存储新的宽度、高度
  final Function(String, Map<String, dynamic>) updateElement;

  ResizeElementOperation({
    required this.elementIds,
    required this.oldSizes,
    required this.newSizes,
    required this.updateElement,
  });

  @override
  String get description => '调整${elementIds.length}个元素大小';

  @override
  void execute() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], newSizes[i]);
    }
  }

  @override
  void undo() {
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], oldSizes[i]);
    }
  }
}

/// 元素置于底层操作
class SendElementToBackOperation extends ElementLayerOperation {
  SendElementToBackOperation({
    required String elementId,
    required int oldIndex,
    required int newIndex,
    required Function(String, int, int) reorderElement,
  }) : super(
          elementId: elementId,
          oldIndex: oldIndex,
          newIndex: newIndex,
          reorderElement: reorderElement,
        );

  @override
  String get description => '置于底层';
}

/// 图层锁定/解锁操作
class ToggleLayerLockOperation implements UndoableOperation {
  final String layerId;
  final bool oldLockState;
  final bool newLockState;
  final Function(String, Map<String, dynamic>) updateLayer;

  ToggleLayerLockOperation({
    required this.layerId,
    required this.oldLockState,
    required this.newLockState,
    required this.updateLayer,
  });

  @override
  String get description => newLockState ? '锁定图层' : '解锁图层';

  @override
  void execute() {
    updateLayer(layerId, {'isLocked': newLockState});
  }

  @override
  void undo() {
    updateLayer(layerId, {'isLocked': oldLockState});
  }
}

/// 图层显示/隐藏操作
class ToggleLayerVisibilityOperation implements UndoableOperation {
  final String layerId;
  final bool oldVisibility;
  final bool newVisibility;
  final Function(String, Map<String, dynamic>) updateLayer;

  ToggleLayerVisibilityOperation({
    required this.layerId,
    required this.oldVisibility,
    required this.newVisibility,
    required this.updateLayer,
  });

  @override
  String get description => newVisibility ? '显示图层' : '隐藏图层';

  @override
  void execute() {
    updateLayer(layerId, {'isVisible': newVisibility});
  }

  @override
  void undo() {
    updateLayer(layerId, {'isVisible': oldVisibility});
  }
}

/// 可撤销操作接口
abstract class UndoableOperation {
  /// 操作描述
  String get description;

  /// 执行操作
  void execute();

  /// 撤销操作
  void undo();
}

/// 撤销/重做管理器
class UndoRedoManager {
  // 撤销栈
  final List<UndoableOperation> _undoStack = [];

  // 重做栈
  final List<UndoableOperation> _redoStack = [];

  // 最大栈大小
  final int _maxStackSize;

  // 状态变化回调
  final VoidCallback? onStateChanged;

  /// 构造函数
  UndoRedoManager({
    int maxStackSize = 100,
    this.onStateChanged,
  }) : _maxStackSize = maxStackSize;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 添加操作
  void addOperation(UndoableOperation operation) {
    debugPrint('【撤销/重做】UndoRedoManager.addOperation: 开始添加操作');
    debugPrint(
        '【撤销/重做】UndoRedoManager.addOperation: 操作类型=${operation.runtimeType}, 描述=${operation.description}');

    try {
      // 执行操作
      operation.execute();

      // 添加到撤销栈
      _undoStack.add(operation);

      // 清空重做栈
      _redoStack.clear();

      // 如果超过最大栈大小，移除最早的操作
      if (_undoStack.length > _maxStackSize) {
        _undoStack.removeAt(0);
        debugPrint('【撤销/重做】UndoRedoManager.addOperation: 撤销栈超过最大大小，已移除最早的操作');
      }

      // 通知状态变化
      if (onStateChanged != null) {
        onStateChanged!();
      }
    } catch (e) {
      debugPrint('【撤销/重做】UndoRedoManager.addOperation: 添加操作失败: $e');
    }
  }

  /// 清空历史
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  /// 重做操作
  void redo() {
    if (!canRedo) return;

    // 从重做栈中取出最后一个操作
    final operation = _redoStack.removeLast();

    // 执行操作
    operation.execute();

    // 添加到撤销栈
    _undoStack.add(operation);

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  /// 撤销操作
  void undo() {
    if (!canUndo) return;

    // 从撤销栈中取出最后一个操作
    final operation = _undoStack.removeLast();

    // 撤销操作
    operation.undo();

    // 添加到重做栈
    _redoStack.add(operation);

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }
}

/// 取消组合元素操作
class UngroupElementOperation implements UndoableOperation {
  final Map<String, dynamic> groupElement;
  final List<Map<String, dynamic>> childElements;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;
  final Function(List<Map<String, dynamic>>) addElements;

  UngroupElementOperation({
    required this.groupElement,
    required this.childElements,
    required this.addElement,
    required this.removeElement,
    required this.addElements,
  });

  @override
  String get description => '取消组合元素';

  @override
  void execute() {
    // 移除组合元素
    removeElement(groupElement['id'] as String);

    // 添加子元素
    addElements(childElements);
  }

  @override
  void undo() {
    // 添加组合元素
    addElement(groupElement);

    // 移除子元素
    for (final element in childElements) {
      removeElement(element['id'] as String);
    }
  }
}

/// 更新图层属性操作
class UpdateLayerPropertyOperation implements UndoableOperation {
  final String layerId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(String, Map<String, dynamic>) updateLayer;

  UpdateLayerPropertyOperation({
    required this.layerId,
    required this.oldProperties,
    required this.newProperties,
    required this.updateLayer,
  });

  @override
  String get description => '修改图层属性';

  @override
  void execute() {
    updateLayer(layerId, newProperties);
  }

  @override
  void undo() {
    updateLayer(layerId, oldProperties);
  }
}

/// 更新页面属性操作
class UpdatePagePropertyOperation implements UndoableOperation {
  final int pageIndex;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(int, Map<String, dynamic>) updatePage;

  UpdatePagePropertyOperation({
    required this.pageIndex,
    required this.oldProperties,
    required this.newProperties,
    required this.updatePage,
  });

  @override
  String get description => '修改页面属性';

  @override
  void execute() {
    updatePage(pageIndex, newProperties);
  }

  @override
  void undo() {
    updatePage(pageIndex, oldProperties);
  }
}
