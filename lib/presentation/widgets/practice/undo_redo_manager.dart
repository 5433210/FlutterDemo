import 'dart:convert';

/// 操作类型枚举
enum OperationType {
  addElement,
  deleteElement,
  updateElement,
  addLayer,
  deleteLayer,
  updateLayer,
  reorderLayer,
  addPage,
  deletePage,
  updatePage,
  group,
  ungroup,
}

/// 操作记录类
class Operation {
  final OperationType type;
  final Map<String, dynamic> data;
  final Map<String, dynamic> previousData;

  Operation({
    required this.type,
    required this.data,
    required this.previousData,
  });

  // 深拷贝操作记录
  Operation copy() {
    return Operation(
      type: type,
      data: json.decode(json.encode(data)),
      previousData: json.decode(json.encode(previousData)),
    );
  }
}

/// 撤销/重做管理器
class UndoRedoManager {
  final List<Operation> _undoStack = [];
  final List<Operation> _redoStack = [];

  // 获取撤销栈
  List<Operation> get undoStack => List.unmodifiable(_undoStack);

  // 获取重做栈
  List<Operation> get redoStack => List.unmodifiable(_redoStack);

  // 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  // 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  // 添加操作记录
  void addOperation(Operation operation) {
    _undoStack.add(operation.copy());
    _redoStack.clear(); // 添加新操作后清空重做栈
  }

  // 撤销操作
  Operation? undo() {
    if (!canUndo) return null;

    final operation = _undoStack.removeLast();
    _redoStack.add(operation.copy());
    return operation;
  }

  // 重做操作
  Operation? redo() {
    if (!canRedo) return null;

    final operation = _redoStack.removeLast();
    _undoStack.add(operation.copy());
    return operation;
  }

  // 清空所有操作记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  // 创建添加元素操作
  static Operation createAddElementOperation(Map<String, dynamic> element) {
    return Operation(
      type: OperationType.addElement,
      data: {'element': element},
      previousData: {},
    );
  }

  // 创建删除元素操作
  static Operation createDeleteElementOperation(
    List<Map<String, dynamic>> elements,
  ) {
    return Operation(
      type: OperationType.deleteElement,
      data: {'elementIds': elements.map((e) => e['id']).toList()},
      previousData: {'elements': elements},
    );
  }

  // 创建更新元素操作
  static Operation createUpdateElementOperation(
    Map<String, dynamic> oldElement,
    Map<String, dynamic> newElement,
  ) {
    return Operation(
      type: OperationType.updateElement,
      data: {'element': newElement},
      previousData: {'element': oldElement},
    );
  }

  // 创建组合操作
  static Operation createGroupOperation(
    List<Map<String, dynamic>> elements,
    Map<String, dynamic> group,
  ) {
    return Operation(
      type: OperationType.group,
      data: {'group': group},
      previousData: {'elements': elements},
    );
  }

  // 创建取消组合操作
  static Operation createUngroupOperation(
    Map<String, dynamic> group,
    List<Map<String, dynamic>> elements,
  ) {
    return Operation(
      type: OperationType.ungroup,
      data: {'elements': elements},
      previousData: {'group': group},
    );
  }
}
