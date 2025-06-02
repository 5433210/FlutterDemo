/// 批量编辑实用工具 - Phase 2.2
///
/// 提供高效的批量元素编辑功能
library;

import 'package:flutter/foundation.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';
import './property_panel_controller.dart';

/// 最大值函数
double max(double a, double b) => a > b ? a : b;

/// 最小值函数
double min(double a, double b) => a < b ? a : b;

/// 批量编辑管理器
class BatchEditManager extends ChangeNotifier {
  final PropertyPanelController _controller;
  final CanvasStateManager _stateManager;

  /// 批量编辑历史
  final List<BatchEditRecord> _history = [];

  /// 当前批量操作
  BatchEditRecord? _currentOperation;

  /// 是否正在执行批量操作
  bool _isBatchOperationActive = false;

  BatchEditManager({
    required PropertyPanelController controller,
    required CanvasStateManager stateManager,
  })  : _controller = controller,
        _stateManager = stateManager;

  /// 获取批量编辑历史
  List<BatchEditRecord> get history => List.unmodifiable(_history);

  /// 是否正在执行批量操作
  bool get isBatchOperationActive => _isBatchOperationActive;

  /// 对齐元素
  void alignElements(List<String> elementIds, String alignment) {
    if (elementIds.length < 2) return;

    // 记录操作
    final operation = BatchEditRecord(
      targetIds: List.from(elementIds),
      operationType: BatchOperationType.align,
      parameters: {'alignment': alignment},
      timestamp: DateTime.now(),
    );

    _beginBatchOperation(operation);

    // 获取元素列表
    final elements = _getElementsFromIds(elementIds);
    if (elements.isEmpty) {
      _endBatchOperation();
      return;
    }

    // 计算对齐位置
    late double alignPosition;
    switch (alignment) {
      case 'left':
        alignPosition = elements.map((e) => e.bounds.left).reduce(min);
        for (final element in elements) {
          _updateElementTransform(element.id, {'x': alignPosition});
        }
        break;
      case 'center':
        final avgCenter =
            elements.map((e) => e.bounds.center.dx).reduce((a, b) => a + b) /
                elements.length;
        for (final element in elements) {
          final offset = avgCenter - element.bounds.center.dx;
          _updateElementTransform(
              element.id, {'x': element.bounds.left + offset});
        }
        break;
      case 'right':
        alignPosition = elements.map((e) => e.bounds.right).reduce(max);
        for (final element in elements) {
          _updateElementTransform(
              element.id, {'x': alignPosition - element.bounds.width});
        }
        break;
      case 'top':
        alignPosition = elements.map((e) => e.bounds.top).reduce(min);
        for (final element in elements) {
          _updateElementTransform(element.id, {'y': alignPosition});
        }
        break;
      case 'middle':
        final avgMiddle =
            elements.map((e) => e.bounds.center.dy).reduce((a, b) => a + b) /
                elements.length;
        for (final element in elements) {
          final offset = avgMiddle - element.bounds.center.dy;
          _updateElementTransform(
              element.id, {'y': element.bounds.top + offset});
        }
        break;
      case 'bottom':
        alignPosition = elements.map((e) => e.bounds.bottom).reduce(max);
        for (final element in elements) {
          _updateElementTransform(
              element.id, {'y': alignPosition - element.bounds.height});
        }
        break;
    }

    _endBatchOperation();
  }

  /// 分布元素
  void distributeElements(List<String> elementIds, String direction) {
    if (elementIds.length < 3) return;

    // 记录操作
    final operation = BatchEditRecord(
      targetIds: List.from(elementIds),
      operationType: BatchOperationType.distribute,
      parameters: {'direction': direction},
      timestamp: DateTime.now(),
    );

    _beginBatchOperation(operation);

    // 获取元素列表
    final elements = _getElementsFromIds(elementIds);
    if (elements.isEmpty) {
      _endBatchOperation();
      return;
    }

    switch (direction) {
      case 'horizontal':
        // 水平分布
        final sortedElements = List<ElementData>.from(elements)
          ..sort((a, b) => a.bounds.left.compareTo(b.bounds.left));

        final firstElement = sortedElements.first;
        final lastElement = sortedElements.last;
        final totalWidth = lastElement.bounds.right - firstElement.bounds.left;
        final totalSpace = totalWidth -
            elements.fold<double>(
                0, (sum, element) => sum + element.bounds.width);
        final spacing = totalSpace / (elements.length - 1);

        double currentX = firstElement.bounds.left;
        for (int i = 0; i < sortedElements.length; i++) {
          final element = sortedElements[i];
          if (i == 0 || i == sortedElements.length - 1) continue; // 保持首尾位置

          currentX += elements[i - 1].bounds.width + spacing;
          _updateElementTransform(element.id, {'x': currentX});
        }
        break;

      case 'vertical':
        // 垂直分布
        final sortedElements = List<ElementData>.from(elements)
          ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

        final firstElement = sortedElements.first;
        final lastElement = sortedElements.last;
        final totalHeight = lastElement.bounds.bottom - firstElement.bounds.top;
        final totalSpace = totalHeight -
            elements.fold<double>(
                0, (sum, element) => sum + element.bounds.height);
        final spacing = totalSpace / (elements.length - 1);

        double currentY = firstElement.bounds.top;
        for (int i = 0; i < sortedElements.length; i++) {
          final element = sortedElements[i];
          if (i == 0 || i == sortedElements.length - 1) continue; // 保持首尾位置

          currentY += elements[i - 1].bounds.height + spacing;
          _updateElementTransform(element.id, {'y': currentY});
        }
        break;
    }

    _endBatchOperation();
  }

  /// 设置多个元素的属性
  void setBatchProperty(
      List<String> elementIds, String property, dynamic value) {
    if (elementIds.isEmpty) return;

    final operation = BatchEditRecord(
      targetIds: List.from(elementIds),
      operationType: BatchOperationType.setProperty,
      parameters: {property: value},
      timestamp: DateTime.now(),
    );

    _beginBatchOperation(operation);

    for (final id in elementIds) {
      _controller.updateElementProperties(id, {property: value});
    }

    _endBatchOperation();
  }

  /// 开始批量操作
  void _beginBatchOperation(BatchEditRecord operation) {
    _currentOperation = operation;
    _isBatchOperationActive = true;
    notifyListeners();
  }

  /// 结束批量操作
  void _endBatchOperation() {
    if (_currentOperation != null) {
      _history.add(_currentOperation!);

      // 限制历史记录大小
      if (_history.length > 50) {
        _history.removeAt(0);
      }
    }

    _currentOperation = null;
    _isBatchOperationActive = false;
    notifyListeners();
  }

  /// 根据ID获取元素列表
  List<ElementData> _getElementsFromIds(List<String> ids) {
    return ids
        .map((id) => _stateManager.elementState.getElementById(id))
        .where((element) => element != null)
        .cast<ElementData>()
        .toList();
  }

  /// 更新元素变换属性
  void _updateElementTransform(
      String elementId, Map<String, dynamic> transform) {
    final element = _stateManager.elementState.getElementById(elementId);
    if (element == null) return;

    final newBounds = element.bounds;
    double? x = transform['x'] as double?;
    double? y = transform['y'] as double?;

    if (x != null || y != null) {
      final updatedElement = element.copyWith(
        bounds: newBounds.translate(
          x != null ? x - newBounds.left : 0,
          y != null ? y - newBounds.top : 0,
        ),
      );

      final updatedState =
          _stateManager.elementState.updateElement(elementId, updatedElement);
      _stateManager.updateElementState(updatedState);
    }
  }
}

/// 批量编辑记录
class BatchEditRecord {
  final List<String> targetIds;
  final BatchOperationType operationType;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const BatchEditRecord({
    required this.targetIds,
    required this.operationType,
    required this.parameters,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'BatchEditRecord(operation: $operationType, targets: ${targetIds.length}, parameters: $parameters)';
  }
}

/// 批量编辑操作类型
enum BatchOperationType {
  /// 设置属性值
  setProperty,

  /// 变换（移动、缩放、旋转）
  transform,

  /// 对齐
  align,

  /// 分布
  distribute,

  /// 层级调整
  reorder,

  /// 组合
  group,

  /// 解组
  ungroup,

  /// 删除
  delete,
}
