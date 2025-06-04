import 'dart:async';

import 'package:flutter/material.dart';

/// 拖拽配置类
class DragConfig {
  /// 批量更新延迟时间（默认16ms = 60FPS）
  static const Duration batchUpdateDelay = Duration(milliseconds: 16);

  /// 拖拽开始阈值（像素）
  static const double dragStartThreshold = 5.0;

  /// 是否启用拖拽预览层
  static bool enableDragPreview = true;

  /// 是否启用批量更新
  static bool enableBatchUpdate = true;

  /// 拖拽预览透明度
  static double dragPreviewOpacity = 0.7;

  /// 调试模式
  static bool debugMode = false;
}

/// 拖拽状态管理器
///
/// 负责独立管理拖拽状态，分离拖拽预览和实际数据提交，
/// 实现拖拽过程中的批量位置更新和性能优化
class DragStateManager extends ChangeNotifier {
  static const Duration _batchUpdateDelay = Duration(milliseconds: 16); // 60FPS
  // 拖拽状态相关
  bool _isDragging = false;
  bool _isDragPreviewActive = false;

  Set<String> _draggingElementIds = <String>{};
  // 拖拽起始位置
  Offset _dragStartPosition = Offset.zero;

  Offset _currentDragOffset = Offset.zero;

  // 元素起始位置缓存
  final Map<String, Offset> _elementStartPositions = <String, Offset>{};

  // 实时拖拽位置（用于预览层）
  final Map<String, Offset> _previewPositions = <String, Offset>{};
  // 批量更新相关
  Timer? _batchUpdateTimer;
  final Map<String, Map<String, dynamic>> _pendingUpdates =
      <String, Map<String, dynamic>>{};

  // 回调函数
  Function(String elementId, Map<String, dynamic> properties)? _onElementUpdate;
  Function(Map<String, Map<String, dynamic>> batchUpdates)? _onBatchUpdate;

  Offset get currentDragOffset => _currentDragOffset;
  Set<String> get draggingElementIds => Set.unmodifiable(_draggingElementIds);
  Offset get dragStartPosition => _dragStartPosition;
  Map<String, Offset> get elementStartPositions =>
      Map.unmodifiable(_elementStartPositions);
  // Getters
  bool get isDragging => _isDragging;
  bool get isDragPreviewActive => _isDragPreviewActive;
  Map<String, Offset> get previewPositions =>
      Map.unmodifiable(_previewPositions);

  /// 取消拖拽操作
  void cancelDrag() {
    debugPrint('❌ DragStateManager.cancelDrag() - 取消拖拽');
    endDrag(shouldCommitChanges: false);
  }

  @override
  void dispose() {
    debugPrint('🗑️ DragStateManager.dispose() - 释放资源');
    _batchUpdateTimer?.cancel();
    super.dispose();
  }

  /// 结束拖拽操作
  void endDrag({bool shouldCommitChanges = true}) {
    debugPrint('🔥 DragStateManager.endDrag() - 结束拖拽');
    debugPrint('   提交更改: $shouldCommitChanges');

    // 取消批量更新定时器
    _batchUpdateTimer?.cancel();

    if (shouldCommitChanges) {
      // 最终提交所有更改
      _commitFinalPositions();
    }

    // 重置状态
    _isDragging = false;
    _isDragPreviewActive = false;
    _draggingElementIds.clear();
    _dragStartPosition = Offset.zero;
    _currentDragOffset = Offset.zero;
    _elementStartPositions.clear();
    _previewPositions.clear();
    _pendingUpdates.clear();

    notifyListeners();
  }

  /// 获取拖拽统计信息
  Map<String, dynamic> getDragStatistics() {
    return {
      'isDragging': _isDragging,
      'draggingElementCount': _draggingElementIds.length,
      'currentOffset': _currentDragOffset,
      'hasPendingUpdates': _pendingUpdates.isNotEmpty,
      'pendingUpdateCount': _pendingUpdates.length,
    };
  }

  /// 获取元素的预览位置
  Offset? getElementPreviewPosition(String elementId) {
    return _previewPositions[elementId];
  }

  /// 获取元素的起始位置
  Offset? getElementStartPosition(String elementId) {
    return _elementStartPositions[elementId];
  }

  /// 检查元素是否正在被拖拽
  bool isElementDragging(String elementId) {
    return _draggingElementIds.contains(elementId);
  }

  /// 设置更新回调
  void setUpdateCallbacks({
    Function(String elementId, Map<String, dynamic> properties)?
        onElementUpdate,
    Function(Map<String, Map<String, dynamic>> batchUpdates)? onBatchUpdate,
  }) {
    _onElementUpdate = onElementUpdate;
    _onBatchUpdate = onBatchUpdate;
  }

  /// 开始拖拽操作
  void startDrag({
    required Set<String> elementIds,
    required Offset startPosition,
    required Map<String, Offset> elementStartPositions,
  }) {
    debugPrint('🔥 DragStateManager.startDrag() - 开始拖拽');
    debugPrint('   拖拽元素: $elementIds');
    debugPrint('   起始位置: $startPosition');

    _isDragging = true;
    _isDragPreviewActive = true;
    _draggingElementIds = Set.from(elementIds);
    _dragStartPosition = startPosition;
    _currentDragOffset = Offset.zero;

    // 缓存元素起始位置
    _elementStartPositions.clear();
    _elementStartPositions.addAll(elementStartPositions);

    // 初始化预览位置为起始位置
    _previewPositions.clear();
    for (final elementId in elementIds) {
      final startPos = elementStartPositions[elementId];
      if (startPos != null) {
        _previewPositions[elementId] = startPos;
      }
    }

    notifyListeners();
  }

  /// 更新拖拽偏移量
  void updateDragOffset(Offset newOffset) {
    if (!_isDragging) return;

    _currentDragOffset = newOffset;

    // 更新预览位置
    _updatePreviewPositions();

    // 批量更新实际位置（通过定时器实现节流）
    _scheduleBatchUpdate();

    notifyListeners();
  }

  /// 提交最终位置
  void _commitFinalPositions() {
    if (_previewPositions.isEmpty) return;

    debugPrint('💾 DragStateManager.commitFinalPositions() - 提交最终位置');

    final finalUpdates = <String, Map<String, dynamic>>{};

    for (final entry in _previewPositions.entries) {
      finalUpdates[entry.key] = {
        'x': entry.value.dx,
        'y': entry.value.dy,
      };
    }

    if (finalUpdates.isNotEmpty && _onBatchUpdate != null) {
      _onBatchUpdate!(finalUpdates);
    }
  }

  /// 处理批量更新
  void _processBatchUpdate() {
    if (_pendingUpdates.isNotEmpty && _onBatchUpdate != null) {
      final batchData = Map<String, Map<String, dynamic>>.from(_pendingUpdates);
      _pendingUpdates.clear();

      debugPrint('📦 DragStateManager.batchUpdate() - 批量更新元素位置');
      debugPrint('   更新元素数量: ${batchData.length}');

      _onBatchUpdate!(batchData);
    }
  }

  /// 调度批量更新
  void _scheduleBatchUpdate() {
    // 取消之前的定时器
    _batchUpdateTimer?.cancel();

    // 准备批量更新数据
    for (final elementId in _draggingElementIds) {
      final previewPos = _previewPositions[elementId];
      if (previewPos != null) {
        _pendingUpdates[elementId] = {
          'x': previewPos.dx,
          'y': previewPos.dy,
        };
      }
    }

    // 设置新的定时器进行批量更新
    _batchUpdateTimer = Timer(_batchUpdateDelay, _processBatchUpdate);
  }

  /// 更新预览位置
  void _updatePreviewPositions() {
    for (final elementId in _draggingElementIds) {
      final startPos = _elementStartPositions[elementId];
      if (startPos != null) {
        _previewPositions[elementId] = startPos + _currentDragOffset;
      }
    }
  }
}
