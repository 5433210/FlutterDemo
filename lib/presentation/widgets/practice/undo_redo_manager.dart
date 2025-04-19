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
    updateElement(elementId, newProperties);
  }

  @override
  void undo() {
    updateElement(elementId, oldProperties);
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
    // 执行操作
    operation.execute();

    // 添加到撤销栈
    _undoStack.add(operation);

    // 清空重做栈
    _redoStack.clear();

    // 如果超过最大栈大小，移除最早的操作
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
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
