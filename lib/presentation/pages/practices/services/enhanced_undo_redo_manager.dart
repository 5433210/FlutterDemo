import 'package:flutter/foundation.dart';

import '../../../widgets/practice/undo_redo_manager.dart';
import '../adapters/property_panel_adapter.dart';

/// 适配器感知的元素添加操作
class AdapterAwareElementAddOperation extends AdapterAwareOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  AdapterAwareElementAddOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
    required Map<String, PropertyPanelAdapter> adapters,
  }) : super(adapters: adapters);

  @override
  Set<String> get affectedElementTypes {
    return {element['type'] as String? ?? 'unknown'};
  }

  @override
  String get description => '添加${element['type']}元素';

  @override
  void execute() {
    if (!isValid) {
      debugPrint('警告: 元素添加操作无效，跳过执行');
      return;
    }

    addElement(element);
  }

  @override
  void undo() {
    removeElement(element['id'] as String);
  }
}

/// 适配器感知的元素删除操作
class AdapterAwareElementDeleteOperation extends AdapterAwareOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  AdapterAwareElementDeleteOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
    required Map<String, PropertyPanelAdapter> adapters,
  }) : super(adapters: adapters);

  @override
  Set<String> get affectedElementTypes {
    return {element['type'] as String? ?? 'unknown'};
  }

  @override
  String get description => '删除${element['type']}元素';

  @override
  void execute() {
    removeElement(element['id'] as String);
  }

  @override
  void undo() {
    if (!isValid) {
      debugPrint('警告: 元素删除撤销操作无效，跳过执行');
      return;
    }

    addElement(element);
  }
}

/// 适配器感知的操作基类
abstract class AdapterAwareOperation implements UndoableOperation {
  /// 操作涉及的适配器映射
  final Map<String, PropertyPanelAdapter> adapters;

  /// 操作发生的时间戳
  final DateTime timestamp;

  AdapterAwareOperation({
    required this.adapters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 获取操作涉及的元素类型
  Set<String> get affectedElementTypes;

  /// 验证操作是否仍然有效
  bool get isValid => _validateOperation();

  /// 验证操作的有效性
  bool _validateOperation() {
    // 检查所需的适配器是否仍然可用
    for (final elementType in affectedElementTypes) {
      if (!adapters.containsKey(elementType)) {
        debugPrint('警告: 操作涉及的元素类型 $elementType 的适配器不可用');
        return false;
      }
    }
    return true;
  }
}

/// 批量属性更新操作
class BatchPropertyUpdateOperation extends AdapterAwareOperation {
  final List<String> elementIds;
  final Map<String, Map<String, dynamic>> oldProperties;
  final Map<String, Map<String, dynamic>> newProperties;
  final Function(String, Map<String, dynamic>) updateElement;

  BatchPropertyUpdateOperation({
    required this.elementIds,
    required this.oldProperties,
    required this.newProperties,
    required this.updateElement,
    required Map<String, PropertyPanelAdapter> adapters,
  }) : super(adapters: adapters);

  @override
  Set<String> get affectedElementTypes {
    return {
      ...oldProperties.values
          .map((props) => props['type'] as String? ?? 'unknown')
    };
  }

  @override
  String get description => '批量更新 ${elementIds.length} 个元素的属性';

  @override
  void execute() {
    if (!isValid) {
      debugPrint('警告: 批量属性更新操作无效，跳过执行');
      return;
    }

    for (final elementId in elementIds) {
      final newProps = newProperties[elementId];
      if (newProps != null) {
        updateElement(elementId, newProps);
      }
    }
  }

  @override
  void undo() {
    if (!isValid) {
      debugPrint('警告: 批量属性更新操作无效，跳过撤销');
      return;
    }

    for (final elementId in elementIds) {
      final oldProps = oldProperties[elementId];
      if (oldProps != null) {
        updateElement(elementId, oldProps);
      }
    }
  }
}

/// 增强的撤销重做管理器
class EnhancedUndoRedoManager extends UndoRedoManager with ChangeNotifier {
  /// 适配器映射
  Map<String, PropertyPanelAdapter> _adapters = {};

  // Internal stacks for enhanced functionality
  final List<UndoableOperation> _enhancedUndoStack = [];
  final List<UndoableOperation> _enhancedRedoStack = [];

  List<UndoableOperation> get redoStack => _enhancedRedoStack;
  // Getters for internal stacks
  List<UndoableOperation> get undoStack => _enhancedUndoStack;

  /// 添加适配器感知的操作
  void addAdapterAwareOperation(AdapterAwareOperation operation) {
    // 验证操作是否有效
    if (!operation.isValid) {
      debugPrint('警告: 跳过无效的适配器感知操作');
      return;
    }

    // 确保操作拥有最新的适配器映射
    operation.adapters.addAll(_adapters);

    addOperation(operation);
  }

  @override
  void addOperation(UndoableOperation operation) {
    _enhancedUndoStack.add(operation);
    _enhancedRedoStack.clear();
    super.addOperation(operation);
    notifyListeners();
  }

  /// 清理无效操作
  void cleanupInvalidOperations() {
    var removedCount = 0;

    // 清理撤销栈中的无效操作
    undoStack.removeWhere((operation) {
      if (operation is AdapterAwareOperation && !operation.isValid) {
        removedCount++;
        return true;
      }
      return false;
    });

    // 清理重做栈中的无效操作
    redoStack.removeWhere((operation) {
      if (operation is AdapterAwareOperation && !operation.isValid) {
        removedCount++;
        return true;
      }
      return false;
    });

    if (removedCount > 0) {
      debugPrint('撤销重做管理器: 已清理 $removedCount 个无效操作');
      notifyListeners();
    }
  }

  /// 创建批量属性更新操作
  BatchPropertyUpdateOperation createBatchPropertyUpdateOperation({
    required List<String> elementIds,
    required Map<String, Map<String, dynamic>> oldProperties,
    required Map<String, Map<String, dynamic>> newProperties,
    required Function(String, Map<String, dynamic>) updateElement,
  }) {
    return BatchPropertyUpdateOperation(
      elementIds: elementIds,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateElement: updateElement,
      adapters: _adapters,
    );
  }

  /// 创建元素添加操作
  AdapterAwareElementAddOperation createElementAddOperation({
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) addElement,
    required Function(String) removeElement,
  }) {
    return AdapterAwareElementAddOperation(
      element: element,
      addElement: addElement,
      removeElement: removeElement,
      adapters: _adapters,
    );
  }

  /// 创建元素删除操作
  AdapterAwareElementDeleteOperation createElementDeleteOperation({
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) addElement,
    required Function(String) removeElement,
  }) {
    return AdapterAwareElementDeleteOperation(
      element: element,
      addElement: addElement,
      removeElement: removeElement,
      adapters: _adapters,
    );
  }

  /// 创建格式刷操作
  SmartFormatPainterOperation createFormatPainterOperation({
    required List<String> targetElementIds,
    required Map<String, Map<String, dynamic>> oldElementData,
    required Map<String, Map<String, dynamic>> newElementData,
    required Map<String, dynamic> formatData,
    required String sourceElementType,
    required Function(String, Map<String, dynamic>) updateElement,
  }) {
    return SmartFormatPainterOperation(
      targetElementIds: targetElementIds,
      oldElementData: oldElementData,
      newElementData: newElementData,
      formatData: formatData,
      sourceElementType: sourceElementType,
      updateElement: updateElement,
      adapters: _adapters,
    );
  }

  /// 获取操作历史统计信息
  Map<String, dynamic> getOperationStats() {
    final stats = <String, int>{};
    final validOperations = <UndoableOperation>[];
    final invalidOperations = <UndoableOperation>[];

    // 分析操作历史
    for (final operation in undoStack) {
      final operationType = operation.runtimeType.toString();
      stats[operationType] = (stats[operationType] ?? 0) + 1;

      if (operation is AdapterAwareOperation) {
        if (operation.isValid) {
          validOperations.add(operation);
        } else {
          invalidOperations.add(operation);
        }
      } else {
        validOperations.add(operation);
      }
    }

    return {
      'totalOperations': undoStack.length,
      'validOperations': validOperations.length,
      'invalidOperations': invalidOperations.length,
      'operationTypes': stats,
      'canUndo': canUndo,
      'canRedo': canRedo,
    };
  }

  @override
  void redo() {
    // 在执行重做前检查操作有效性
    if (canRedo) {
      final operation = _enhancedRedoStack.last;
      if (operation is AdapterAwareOperation && !operation.isValid) {
        debugPrint('跳过无效的重做操作: ${operation.description}');
        _enhancedRedoStack.removeLast();
        redo(); // 递归尝试下一个操作
        return;
      }
      // Move operation from redo to undo stack
      _enhancedUndoStack.add(_enhancedRedoStack.removeLast());
    }

    super.redo();
    notifyListeners();
  }

  @override
  void undo() {
    // 在执行撤销前检查操作有效性
    if (canUndo) {
      final operation = _enhancedUndoStack.last;
      if (operation is AdapterAwareOperation && !operation.isValid) {
        debugPrint('跳过无效的撤销操作: ${operation.description}');
        _enhancedUndoStack.removeLast();
        undo(); // 递归尝试下一个操作
        return;
      }
      // Move operation from undo to redo stack
      _enhancedRedoStack.add(_enhancedUndoStack.removeLast());
    }

    super.undo();
    notifyListeners();
  }

  /// 更新适配器映射
  void updateAdapters(Map<String, PropertyPanelAdapter> adapters) {
    _adapters = Map.from(adapters);
  }
}

/// 智能格式刷操作
class SmartFormatPainterOperation extends AdapterAwareOperation {
  final List<String> targetElementIds;
  final Map<String, Map<String, dynamic>> oldElementData;
  final Map<String, Map<String, dynamic>> newElementData;
  final Map<String, dynamic> formatData;
  final String sourceElementType;
  final Function(String, Map<String, dynamic>) updateElement;

  SmartFormatPainterOperation({
    required this.targetElementIds,
    required this.oldElementData,
    required this.newElementData,
    required this.formatData,
    required this.sourceElementType,
    required this.updateElement,
    required Map<String, PropertyPanelAdapter> adapters,
  }) : super(adapters: adapters);

  @override
  Set<String> get affectedElementTypes {
    return {
      sourceElementType,
      ...oldElementData.values
          .map((data) => data['type'] as String? ?? 'unknown'),
    };
  }

  @override
  String get description =>
      '应用 $sourceElementType 格式到 ${targetElementIds.length} 个元素';

  @override
  void execute() {
    if (!isValid) {
      debugPrint('警告: 格式刷操作无效，跳过执行');
      return;
    }

    for (final elementId in targetElementIds) {
      final newData = newElementData[elementId];
      if (newData != null) {
        updateElement(elementId, newData);
      }
    }
  }

  @override
  void undo() {
    if (!isValid) {
      debugPrint('警告: 格式刷操作无效，跳过撤销');
      return;
    }

    for (final elementId in targetElementIds) {
      final oldData = oldElementData[elementId];
      if (oldData != null) {
        updateElement(elementId, oldData);
      }
    }
  }
}
