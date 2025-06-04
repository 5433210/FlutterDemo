import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/element_snapshot.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import 'state_change_dispatcher.dart';

/// 拖拽结束信息
class DragEndInfo {
  final Offset finalPosition;
  final Offset totalDelta;

  DragEndInfo({
    required this.finalPosition,
    required this.totalDelta,
  });
}

/// 三阶段拖拽操作管理器
/// 实现 PreDrag → Dragging → PostDrag 的完整拖拽生命周期管理
class DragOperationManager {
  final PracticeEditController _controller;
  final DragStateManager _dragStateManager;
  final StateChangeDispatcher _stateDispatcher;

  /// 当前拖拽阶段
  DragPhase _currentPhase = DragPhase.idle;

  /// 拖拽会话信息
  DragSession? _currentSession;

  /// 拖拽性能监控
  final DragPerformanceMonitor _performanceMonitor = DragPerformanceMonitor();

  /// 预拖拽配置
  final PreDragConfig _preDragConfig = PreDragConfig();

  /// 元素快照管理器
  final ElementSnapshotManager _snapshotManager = ElementSnapshotManager();

  /// 是否已释放
  bool _isDisposed = false;

  DragOperationManager(
    this._controller,
    this._dragStateManager,
    this._stateDispatcher,
  ) {
    _initializeOperationManager();
  }

  /// 获取当前拖拽阶段
  DragPhase get currentPhase => _currentPhase;

  /// 获取当前拖拽会话
  DragSession? get currentSession => _currentSession;

  /// 获取性能监控器
  DragPerformanceMonitor get performanceMonitor => _performanceMonitor;

  /// 取消拖拽操作
  void cancelDragOperation() {
    if (_isDisposed || _currentPhase == DragPhase.idle) {
      return;
    }

    debugPrint('🎯 DragOperationManager: 取消拖拽操作');
    try {
      // 恢复元素到原始位置
      if (_currentSession != null) {
        for (final elementId in _currentSession!.elementIds) {
          final originalPosition =
              _currentSession!.originalPositions[elementId];
          if (originalPosition != null) {
            // 使用批量更新优化性能
            _controller.updateElementProperties(elementId, {
              'x': originalPosition.dx,
              'y': originalPosition.dy,
            });
          }
        }
      }

      // 清理快照（无需等待_resetToIdle）
      _snapshotManager.clearSnapshots();

      // 分发取消事件
      _stateDispatcher.dispatch(StateChangeEvent(
        type: StateChangeType.dragEnd,
        data: {
          'elementIds': _currentSession?.elementIds ?? [],
          'cancelled': true,
        },
      ));
    } catch (e) {
      debugPrint('🎯 DragOperationManager: 拖拽取消处理失败 - $e');
    } finally {
      _resetToIdle();
      _performanceMonitor.endOperation();
    }
  }

  /// 释放资源
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    // 如果正在拖拽，先取消
    if (_currentPhase != DragPhase.idle) {
      cancelDragOperation();
    }

    _performanceMonitor.dispose();
    _snapshotManager.dispose();
    debugPrint('🎯 DragOperationManager: 已释放资源');
  }

  /// 结束拖拽操作
  Future<void> endDragOperation(DragEndInfo endInfo) async {
    if (_isDisposed ||
        _currentPhase == DragPhase.idle ||
        _currentSession == null) {
      return;
    }

    debugPrint('🎯 DragOperationManager: 结束拖拽操作');

    try {
      // 阶段3: PostDrag - 拖拽后处理
      await _executePostDragPhase(endInfo);
    } catch (e) {
      debugPrint('🎯 DragOperationManager: 拖拽结束处理失败 - $e');
    } finally {
      _resetToIdle();
      _performanceMonitor.endOperation();
    }
  }

  /// 获取所有元素快照
  Map<String, ElementSnapshot> getAllSnapshots() {
    return _snapshotManager.getAllSnapshots();
  }

  /// 获取元素的快照
  ElementSnapshot? getSnapshotForElement(String elementId) {
    return _snapshotManager.getSnapshot(elementId);
  }

  /// 开始拖拽操作
  Future<bool> startDragOperation(DragStartInfo startInfo) async {
    if (_isDisposed || _currentPhase != DragPhase.idle) {
      return false;
    }

    debugPrint('🎯 DragOperationManager: 开始拖拽操作');
    _performanceMonitor.startOperation();

    try {
      // 阶段1: PreDrag - 预拖拽准备
      final preDragResult = await _executePreDragPhase(startInfo);
      if (!preDragResult.success) {
        debugPrint(
            '🎯 DragOperationManager: PreDrag阶段失败 - ${preDragResult.reason}');
        return false;
      }

      // 阶段2: Dragging - 活跃拖拽
      _executeDraggingPhase(preDragResult.session!);

      return true;
    } catch (e) {
      debugPrint('🎯 DragOperationManager: 拖拽操作启动失败 - $e');
      _resetToIdle();
      return false;
    }
  }

  /// 更新拖拽操作
  void updateDragOperation(DragUpdateInfo updateInfo) {
    if (_isDisposed ||
        _currentPhase != DragPhase.dragging ||
        _currentSession == null) {
      return;
    }

    _performanceMonitor.recordUpdate();

    try {
      // 更新会话信息
      _currentSession!.updatePosition(updateInfo.currentPosition);
      _currentSession!.updateDelta(updateInfo.delta);

      // 更新快照位置 - 使用ElementSnapshot系统优化性能
      for (final elementId in _currentSession!.elementIds) {
        final newPosition = _currentSession!.originalPositions[elementId]! +
            _currentSession!.totalDelta;
        _snapshotManager.updateSnapshotPosition(elementId, newPosition);
      }

      // 分发拖拽更新事件
      _stateDispatcher.dispatch(StateChangeEvent(
        type: StateChangeType.dragUpdate,
        data: {
          'elementIds': _currentSession!.elementIds,
          'currentPosition': updateInfo.currentPosition,
          'delta': updateInfo.delta,
          'session': _currentSession,
          'hasSnapshots': true, // 指示使用了快照系统
        },
      ));

      // 更新拖拽状态管理器
      _dragStateManager.updateDragOffset(updateInfo.delta);
    } catch (e) {
      debugPrint('🎯 DragOperationManager: 拖拽更新失败 - $e');
    }
  }

  /// 应用最终位置
  Future<void> _applyFinalPositions(DragEndInfo endInfo) async {
    debugPrint('🎯 DragOperationManager: 应用最终位置');
    if (_currentSession == null) return;

    // 创建批量更新操作以提高性能
    final batchUpdates = <String, Map<String, dynamic>>{};

    // 从快照中获取最终位置，而不是从拖拽会话
    for (final elementId in _currentSession!.elementIds) {
      // 从快照获取最终位置
      final snapshot = _snapshotManager.getSnapshot(elementId);
      if (snapshot != null) {
        // 使用快照中的最新位置
        batchUpdates[elementId] = {
          'x': snapshot.properties['x'],
          'y': snapshot.properties['y'],
        };
      } else {
        // 快照不存在时退回到使用会话中的计算位置
        final originalPosition = _currentSession!.originalPositions[elementId];
        if (originalPosition != null) {
          final finalPosition = originalPosition + endInfo.totalDelta;
          batchUpdates[elementId] = {
            'x': finalPosition.dx,
            'y': finalPosition.dy,
          };
        }
      }
    }

    // 批量应用所有更新
    for (final entry in batchUpdates.entries) {
      _controller.updateElementProperties(entry.key, entry.value);
    }

    // 记录性能统计
    final snapshotStats = _snapshotManager.getMemoryStats();
    debugPrint(
        '📊 快照性能: ${snapshotStats['snapshotCount']} 个快照, ${snapshotStats['memoryEstimateKB']} KB');
  }

  /// 应用网格吸附
  void _applyGridSnapping() {
    if (_currentSession == null) return;

    final gridSize = _controller.state.gridSize;

    for (final elementId in _currentSession!.elementIds) {
      final element = _controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isNotEmpty) {
        final x = (element['x'] as num?)?.toDouble() ?? 0.0;
        final y = (element['y'] as num?)?.toDouble() ?? 0.0;

        final snappedX = (x / gridSize).round() * gridSize;
        final snappedY = (y / gridSize).round() * gridSize;

        if (snappedX != x || snappedY != y) {
          _controller.updateElementProperties(elementId, {
            'x': snappedX,
            'y': snappedY,
          });

          debugPrint('🎯 网格吸附: $elementId 从 ($x, $y) 到 ($snappedX, $snappedY)');
        }
      }
    }
  }

  /// 创建撤销/重做操作
  void _createUndoRedoOperation() {
    if (_currentSession == null) return;

    // 这里可以集成撤销/重做系统
    debugPrint('🎯 DragOperationManager: 创建撤销/重做操作');
  }

  /// 执行Dragging阶段
  void _executeDraggingPhase(DragSession session) {
    _currentPhase = DragPhase.dragging;
    _currentSession = session;

    debugPrint('🎯 DragOperationManager: 执行Dragging阶段');

    // 初始化拖拽状态
    _dragStateManager.startDrag(
      elementIds: session.elementIds.toSet(),
      startPosition: session.startPosition,
      elementStartPositions: session.originalPositions,
    );

    // 记录快照统计信息
    final stats = _snapshotManager.getMemoryStats();
    debugPrint(
        '📊 快照统计: ${stats['snapshotCount']}个快照, ${stats['widgetCacheCount']}个缓存组件');
  }

  /// 执行PostDrag阶段
  Future<void> _executePostDragPhase(DragEndInfo endInfo) async {
    _currentPhase = DragPhase.postDrag;

    debugPrint('🎯 DragOperationManager: 执行PostDrag阶段');

    try {
      // 应用最终位置
      await _applyFinalPositions(endInfo);

      // 触发网格吸附
      if (_controller.state.snapEnabled) {
        _applyGridSnapping();
      }

      // 创建撤销/重做操作
      _createUndoRedoOperation();

      // 分发PostDrag事件
      _stateDispatcher.dispatch(StateChangeEvent(
        type: StateChangeType.dragEnd,
        data: {
          'elementIds': _currentSession!.elementIds,
          'finalPosition': endInfo.finalPosition,
          'session': _currentSession,
        },
      ));
      // 结束拖拽状态
      _dragStateManager.endDrag();
    } catch (e) {
      debugPrint('🎯 DragOperationManager: PostDrag阶段异常 - $e');
    }
  }

  /// 执行PreDrag阶段
  Future<PreDragResult> _executePreDragPhase(DragStartInfo startInfo) async {
    _currentPhase = DragPhase.preDrag;

    debugPrint('🎯 DragOperationManager: 执行PreDrag阶段');

    try {
      // 验证拖拽条件
      final validationResult = _validateDragConditions(startInfo);
      if (!validationResult.isValid) {
        return PreDragResult(
          success: false,
          reason: validationResult.reason,
        );
      }

      // 准备拖拽数据
      final sessionData = await _prepareDragData(startInfo);

      // 创建拖拽会话
      final session = DragSession(
        elementIds: startInfo.elementIds,
        startPosition: startInfo.startPosition,
        originalPositions: sessionData.originalPositions,
        startTime: DateTime.now(),
      );

      // 分发PreDrag事件
      _stateDispatcher.dispatch(StateChangeEvent(
        type: StateChangeType.dragStart,
        data: {
          'elementIds': startInfo.elementIds,
          'startPosition': startInfo.startPosition,
          'session': session,
        },
      ));

      return PreDragResult(
        success: true,
        session: session,
      );
    } catch (e) {
      return PreDragResult(
        success: false,
        reason: 'PreDrag阶段异常: $e',
      );
    }
  }

  /// 初始化操作管理器
  void _initializeOperationManager() {
    debugPrint('🎯 DragOperationManager: 初始化完成');
  }

  /// 准备拖拽数据
  Future<DragSessionData> _prepareDragData(DragStartInfo startInfo) async {
    final originalPositions = <String, Offset>{};
    final elementsList = <Map<String, dynamic>>[];

    for (final elementId in startInfo.elementIds) {
      final element = _controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isNotEmpty) {
        final x = (element['x'] as num?)?.toDouble() ?? 0.0;
        final y = (element['y'] as num?)?.toDouble() ?? 0.0;
        originalPositions[elementId] = Offset(x, y);
        elementsList.add(element);
      }
    }

    // 创建元素快照
    await _snapshotManager.createSnapshots(elementsList);
    debugPrint('🎯 DragOperationManager: 已创建 ${elementsList.length} 个元素快照');

    return DragSessionData(
      originalPositions: originalPositions,
    );
  }

  /// 重置到空闲状态
  void _resetToIdle() {
    _currentPhase = DragPhase.idle;
    _currentSession = null;

    // 清理不再需要的快照
    _snapshotManager.clearSnapshots();
  }

  /// 验证拖拽条件
  DragValidationResult _validateDragConditions(DragStartInfo startInfo) {
    // 检查元素是否存在
    if (startInfo.elementIds.isEmpty) {
      return DragValidationResult(false, '没有选中的元素');
    }

    // 检查元素是否锁定
    for (final elementId in startInfo.elementIds) {
      final element = _controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) {
        return DragValidationResult(false, '元素不存在: $elementId');
      }

      final isLocked = element['locked'] as bool? ?? false;
      if (isLocked) {
        return DragValidationResult(false, '元素已锁定: $elementId');
      }

      // 检查图层是否锁定
      final layerId = element['layerId'] as String?;
      if (layerId != null && _controller.state.isLayerLocked(layerId)) {
        return DragValidationResult(false, '图层已锁定: $layerId');
      }
    }

    return DragValidationResult(true, '');
  }
}

/// 拖拽性能监控
class DragPerformanceMonitor {
  DateTime? _operationStartTime;
  int _updateCount = 0;
  final List<Duration> _updateIntervals = [];

  void dispose() {
    _updateIntervals.clear();
  }

  void endOperation() {
    if (_operationStartTime != null) {
      final totalDuration = DateTime.now().difference(_operationStartTime!);
      debugPrint(
          '🎯 拖拽性能: 总时长=${totalDuration.inMilliseconds}ms, 更新次数=$_updateCount');
    }
  }

  void recordUpdate() {
    _updateCount++;

    if (_updateIntervals.isNotEmpty) {
      final lastTime = _operationStartTime!.add(_updateIntervals.last);
      _updateIntervals.add(DateTime.now().difference(lastTime));
    } else {
      _updateIntervals.add(DateTime.now().difference(_operationStartTime!));
    }
  }

  void startOperation() {
    _operationStartTime = DateTime.now();
    _updateCount = 0;
    _updateIntervals.clear();
  }
}

/// 拖拽阶段
enum DragPhase {
  idle, // 空闲
  preDrag, // 预拖拽
  dragging, // 拖拽中
  postDrag, // 拖拽后处理
}

/// 拖拽会话
class DragSession {
  final List<String> elementIds;
  final Offset startPosition;
  final Map<String, Offset> originalPositions;
  final DateTime startTime;

  Offset _currentPosition;
  Offset _totalDelta = Offset.zero;

  DragSession({
    required this.elementIds,
    required this.startPosition,
    required this.originalPositions,
    required this.startTime,
  }) : _currentPosition = startPosition;

  Offset get currentPosition => _currentPosition;
  Duration get duration => DateTime.now().difference(startTime);

  Offset get totalDelta => _totalDelta;

  void updateDelta(Offset delta) {
    _currentPosition = _currentPosition + delta;
    _totalDelta = _currentPosition - startPosition;
  }

  void updatePosition(Offset newPosition) {
    _currentPosition = newPosition;
    _totalDelta = newPosition - startPosition;
  }
}

/// 拖拽会话数据
class DragSessionData {
  final Map<String, Offset> originalPositions;

  DragSessionData({
    required this.originalPositions,
  });
}

/// 拖拽开始信息
class DragStartInfo {
  final List<String> elementIds;
  final Offset startPosition;

  DragStartInfo({
    required this.elementIds,
    required this.startPosition,
  });
}

/// 拖拽更新信息
class DragUpdateInfo {
  final Offset currentPosition;
  final Offset delta;

  DragUpdateInfo({
    required this.currentPosition,
    required this.delta,
  });
}

/// 拖拽验证结果
class DragValidationResult {
  final bool isValid;
  final String reason;

  DragValidationResult(this.isValid, this.reason);
}

/// 预拖拽配置
class PreDragConfig {
  final Duration validationTimeout;
  final bool enablePreValidation;
  final bool enableDataPreparation;

  PreDragConfig({
    this.validationTimeout = const Duration(milliseconds: 100),
    this.enablePreValidation = true,
    this.enableDataPreparation = true,
  });
}

/// 预拖拽结果
class PreDragResult {
  final bool success;
  final String? reason;
  final DragSession? session;

  PreDragResult({
    required this.success,
    this.reason,
    this.session,
  });
}
