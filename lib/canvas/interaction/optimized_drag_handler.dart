// filepath: lib/canvas/interaction/optimized_drag_handler.dart
/// 优化拖拽处理器 - Phase 2.4 拖拽性能提升
///
/// 职责：
/// 1. 高性能的拖拽操作处理
/// 2. 拖拽预览和视觉反馈优化
/// 3. 批量拖拽操作优化
/// 4. 拖拽过程中的性能监控
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../core/canvas_state_manager.dart';
import 'multi_selection_manager.dart';

/// 拖拽模式
enum DragMode {
  single, // 单个元素拖拽
  multiple, // 多个元素拖拽
  preview, // 预览拖拽（仅显示轮廓）
  ghost, // 幽灵拖拽（半透明）
}

/// 拖拽性能配置
class DragPerformanceConfig {
  final int maxDragElements; // 最大可拖拽元素数量
  final double previewThreshold; // 超过此数量使用预览模式
  final Duration updateInterval; // 更新间隔
  final bool enableGhostMode; // 启用幽灵模式
  final double ghostOpacity; // 幽灵模式透明度
  final bool enableBatching; // 启用批量更新
  final int batchSize; // 批量更新大小

  const DragPerformanceConfig({
    this.maxDragElements = 100,
    this.previewThreshold = 20,
    this.updateInterval = const Duration(milliseconds: 16), // 60fps
    this.enableGhostMode = true,
    this.ghostOpacity = 0.5,
    this.enableBatching = true,
    this.batchSize = 10,
  });
}

/// 拖拽状态
class DragState {
  final bool isDragging;
  final DragMode mode;
  final List<String> elementIds;
  final Offset startPosition;
  final Offset currentPosition;
  final Offset deltaFromStart;
  final Offset deltaFromLast;
  final Duration elapsed;

  const DragState({
    this.isDragging = false,
    this.mode = DragMode.single,
    this.elementIds = const [],
    this.startPosition = Offset.zero,
    this.currentPosition = Offset.zero,
    this.deltaFromStart = Offset.zero,
    this.deltaFromLast = Offset.zero,
    this.elapsed = Duration.zero,
  });

  DragState copyWith({
    bool? isDragging,
    DragMode? mode,
    List<String>? elementIds,
    Offset? startPosition,
    Offset? currentPosition,
    Offset? deltaFromStart,
    Offset? deltaFromLast,
    Duration? elapsed,
  }) {
    return DragState(
      isDragging: isDragging ?? this.isDragging,
      mode: mode ?? this.mode,
      elementIds: elementIds ?? this.elementIds,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      deltaFromStart: deltaFromStart ?? this.deltaFromStart,
      deltaFromLast: deltaFromLast ?? this.deltaFromLast,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

/// 元素更新信息
class ElementUpdateInfo {
  final String elementId;
  final Offset deltaPosition;
  final DateTime timestamp;

  const ElementUpdateInfo({
    required this.elementId,
    required this.deltaPosition,
    required this.timestamp,
  });
}

/// 优化拖拽处理器
class OptimizedDragHandler extends ChangeNotifier {
  final CanvasStateManager _stateManager;
  final MultiSelectionManager _selectionManager;
  final DragPerformanceConfig _config;

  DragState _dragState = const DragState();
  DateTime _lastUpdateTime = DateTime.now();

  // 性能优化相关
  final Map<String, Rect> _originalBounds = {};
  final Map<String, ui.Image?> _elementPreviews = {};
  bool _usePreviewMode = false;

  // 批量更新队列
  final List<ElementUpdateInfo> _updateQueue = [];

  // 性能监控
  int _dragOperationCount = 0;
  int _totalFramesDropped = 0;
  final List<Duration> _updateDurations = [];

  OptimizedDragHandler(
    this._stateManager,
    this._selectionManager, {
    DragPerformanceConfig? config,
  }) : _config = config ?? const DragPerformanceConfig();

  /// 拖拽的元素数量
  int get dragElementCount => _dragState.elementIds.length;

  /// 当前拖拽状态
  DragState get dragState => _dragState;

  /// 是否正在拖拽
  bool get isDragging => _dragState.isDragging;

  /// 取消拖拽操作
  void cancelDrag() {
    if (!_dragState.isDragging) return;

    // 恢复到原始位置
    _restoreOriginalPositions();

    // 清理资源
    _cleanupDragResources();

    _dragState = const DragState();
    notifyListeners();
  }

  /// 结束拖拽操作
  void endDrag() {
    if (!_dragState.isDragging) return;

    // 应用最终位置
    _applyFinalPosition();

    // 清理资源
    _cleanupDragResources();

    _dragState = const DragState();
    notifyListeners();
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    if (_updateDurations.isEmpty) {
      return {
        'dragOperationCount': _dragOperationCount,
        'totalFramesDropped': _totalFramesDropped,
        'averageUpdateTime': 0,
        'maxUpdateTime': 0,
        'frameDropRate': 0.0,
      };
    }

    final totalMs =
        _updateDurations.fold<int>(0, (sum, d) => sum + d.inMicroseconds) /
            1000;
    final averageMs = totalMs / _updateDurations.length;
    final maxMs = _updateDurations
        .map((d) => d.inMicroseconds / 1000)
        .reduce((a, b) => a > b ? a : b);
    final frameDropRate = _totalFramesDropped / _dragOperationCount;

    return {
      'dragOperationCount': _dragOperationCount,
      'totalFramesDropped': _totalFramesDropped,
      'averageUpdateTime': averageMs,
      'maxUpdateTime': maxMs,
      'frameDropRate': frameDropRate,
      'currentDragElementCount': dragElementCount,
      'isDragging': isDragging,
    };
  }

  /// 重置性能统计
  void resetPerformanceStats() {
    _dragOperationCount = 0;
    _totalFramesDropped = 0;
    _updateDurations.clear();
  }

  /// 开始拖拽操作
  bool startDrag({
    required Offset startPosition,
    List<String>? elementIds,
    DragMode? mode,
  }) {
    final targetElements = elementIds ??
        _selectionManager.selectedElements.map((e) => e.id).toList();

    if (targetElements.isEmpty) {
      return false;
    }

    // 检查元素数量限制
    if (targetElements.length > _config.maxDragElements) {
      debugPrint('Too many elements to drag: ${targetElements.length}');
      return false;
    }

    // 确定拖拽模式
    final dragMode = mode ?? _determineDragMode(targetElements.length);

    // 保存原始位置
    _saveOriginalBounds(targetElements);

    // 根据模式准备预览
    if (dragMode == DragMode.preview || dragMode == DragMode.ghost) {
      _prepareElementPreviews(targetElements);
    }

    _dragState = DragState(
      isDragging: true,
      mode: dragMode,
      elementIds: targetElements,
      startPosition: startPosition,
      currentPosition: startPosition,
      deltaFromStart: Offset.zero,
      deltaFromLast: Offset.zero,
      elapsed: Duration.zero,
    );

    _dragOperationCount++;
    _lastUpdateTime = DateTime.now();

    notifyListeners();
    return true;
  }

  /// 更新拖拽位置
  void updateDrag(Offset currentPosition) {
    if (!_dragState.isDragging) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdateTime);

    // 检查更新频率限制
    if (elapsed < _config.updateInterval) {
      return;
    }

    final deltaFromStart = currentPosition - _dragState.startPosition;
    final deltaFromLast = currentPosition - _dragState.currentPosition;

    _dragState = _dragState.copyWith(
      currentPosition: currentPosition,
      deltaFromStart: deltaFromStart,
      deltaFromLast: deltaFromLast,
      elapsed: now.difference(_lastUpdateTime),
    );

    // 执行实际的拖拽更新
    _performDragUpdate(deltaFromLast);

    _lastUpdateTime = now;
    _recordUpdatePerformance(elapsed);

    notifyListeners();
  }

  /// 应用最终位置
  void _applyFinalPosition() {
    if (_dragState.mode == DragMode.preview ||
        _dragState.mode == DragMode.ghost) {
      // 在预览模式下，需要将预览位置应用到实际元素
      _selectionManager.moveSelectedElements(_dragState.deltaFromStart);
    }
    // 在实时模式下，位置已经在拖拽过程中更新了
  }

  /// 批量更新位置
  void _batchUpdatePositions(Offset delta) {
    // 将更新添加到队列
    for (final id in _dragState.elementIds) {
      _updateQueue.add(ElementUpdateInfo(
        elementId: id,
        deltaPosition: delta,
        timestamp: DateTime.now(),
      ));
    }

    // 处理队列中的更新
    _processBatchUpdates();
  }

  /// 清理拖拽资源
  void _cleanupDragResources() {
    _originalBounds.clear();
    _elementPreviews.clear();
    _updateQueue.clear();
    _usePreviewMode = false;
  }

  /// 确定拖拽模式
  DragMode _determineDragMode(int elementCount) {
    if (elementCount == 1) {
      return DragMode.single;
    } else if (elementCount <= _config.previewThreshold) {
      return _config.enableGhostMode ? DragMode.ghost : DragMode.multiple;
    } else {
      return DragMode.preview;
    }
  }

  /// 直接更新位置
  void _directUpdatePositions(Offset delta) {
    var newElementState = _stateManager.elementState;

    for (final id in _dragState.elementIds) {
      final element = newElementState.getElementById(id);
      if (element != null) {
        final newBounds = element.bounds.translate(delta.dx, delta.dy);
        final updatedElement = element.copyWith(bounds: newBounds);
        newElementState =
            newElementState.updateElement(element.id, updatedElement);
      }
    }

    _stateManager.updateElementState(newElementState);
  }

  /// 执行拖拽更新
  void _performDragUpdate(Offset delta) {
    if (delta == Offset.zero) return;

    switch (_dragState.mode) {
      case DragMode.single:
      case DragMode.multiple:
        _updateElementPositions(delta);
        break;
      case DragMode.preview:
      case DragMode.ghost:
        _updatePreviewPositions(delta);
        break;
    }
  }

  /// 准备元素预览
  void _prepareElementPreviews(List<String> elementIds) {
    if (_dragState.mode != DragMode.preview &&
        _dragState.mode != DragMode.ghost) {
      return;
    }

    // 这里应该实现真正的预览图像生成
    // 为了简化，我们暂时不生成实际的图像
    for (final id in elementIds) {
      _elementPreviews[id] = null; // 占位符
    }
  }

  /// 处理批量更新
  void _processBatchUpdates() {
    if (_updateQueue.isEmpty) return;

    var newElementState = _stateManager.elementState;
    final processedIds = <String>{};

    // 合并相同元素的多个更新
    final mergedUpdates = <String, Offset>{};
    for (final update in _updateQueue) {
      mergedUpdates[update.elementId] =
          (mergedUpdates[update.elementId] ?? Offset.zero) +
              update.deltaPosition;
    }

    // 应用合并后的更新
    for (final entry in mergedUpdates.entries) {
      final element = newElementState.getElementById(entry.key);
      if (element != null) {
        final newBounds =
            element.bounds.translate(entry.value.dx, entry.value.dy);
        final updatedElement = element.copyWith(bounds: newBounds);
        newElementState =
            newElementState.updateElement(element.id, updatedElement);
        processedIds.add(entry.key);
      }
    }

    _stateManager.updateElementState(newElementState);
    _updateQueue.clear();
  }

  /// 记录更新性能
  void _recordUpdatePerformance(Duration updateDuration) {
    _updateDurations.add(updateDuration);

    // 保持最近100次的记录
    if (_updateDurations.length > 100) {
      _updateDurations.removeAt(0);
    }

    // 检测掉帧
    if (updateDuration > const Duration(milliseconds: 32)) {
      // 超过两帧时间
      _totalFramesDropped++;
    }
  }

  /// 恢复原始位置
  void _restoreOriginalPositions() {
    var newElementState = _stateManager.elementState;

    for (final entry in _originalBounds.entries) {
      final element = newElementState.getElementById(entry.key);
      if (element != null) {
        final restoredElement = element.copyWith(bounds: entry.value);
        newElementState =
            newElementState.updateElement(entry.key, restoredElement);
      }
    }

    _stateManager.updateElementState(newElementState);
  }

  /// 保存原始边界
  void _saveOriginalBounds(List<String> elementIds) {
    _originalBounds.clear();
    for (final id in elementIds) {
      final element = _stateManager.elementState.getElementById(id);
      if (element != null) {
        _originalBounds[id] = element.bounds;
      }
    }
  }

  /// 更新元素位置（实时模式）
  void _updateElementPositions(Offset delta) {
    if (_config.enableBatching &&
        _dragState.elementIds.length > _config.batchSize) {
      _batchUpdatePositions(delta);
    } else {
      _directUpdatePositions(delta);
    }
  }

  /// 更新预览位置
  void _updatePreviewPositions(Offset delta) {
    // 在预览模式下，我们只更新预览位置，不更新实际元素
    // 这里应该更新预览图像的位置
    // 为了简化，我们暂时不实现实际的预览更新
  }
}
