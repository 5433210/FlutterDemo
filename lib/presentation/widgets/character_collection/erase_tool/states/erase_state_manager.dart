import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_operation.dart';
import '../utils/render_cache.dart';
import '../utils/undo_manager.dart';
import 'erase_layer_state.dart';

/// 擦除状态更新事件
class EraseStateEvent {
  /// 事件类型
  final EraseStateType type;

  /// 相关操作
  final EraseOperation? operation;

  /// 相关点
  final List<Offset>? points;

  /// 构造函数
  EraseStateEvent({
    required this.type,
    this.operation,
    this.points,
  });
}

/// 擦除状态管理器
/// 负责协调各组件的状态，确保状态同步
class EraseStateManager {
  /// 图层状态
  final EraseLayerState _layerState;

  /// 撤销管理器
  final UndoManager _undoManager;

  /// 渲染缓存
  final RenderCache _renderCache;

  /// 状态事件流控制器
  final StreamController<EraseStateEvent> _stateEventController =
      StreamController<EraseStateEvent>.broadcast();

  /// 构造函数
  EraseStateManager({
    EraseLayerState? layerState,
    UndoManager? undoManager,
    RenderCache? renderCache,
  })  : _layerState = layerState ?? EraseLayerState(),
        _undoManager = undoManager ?? UndoManager(),
        _renderCache = renderCache ?? RenderCache() {
    // 设置状态同步
    _setupStateSynchronization();
  }

  /// 获取图层状态
  EraseLayerState get layerState => _layerState;

  /// 获取渲染缓存
  RenderCache get renderCache => _renderCache;

  /// 获取状态事件流
  Stream<EraseStateEvent> get stateEvents => _stateEventController.stream;

  /// 获取撤销管理器
  UndoManager get undoManager => _undoManager;

  /// 取消擦除操作
  void cancelErase() {
    _layerState.cancelCurrentOperation();
  }

  /// 清除所有
  void clearAll() {
    _undoManager.clear();
    _layerState.clearOperations();
    _renderCache.clearCache();
  }

  /// 继续擦除操作
  void continueErase(Offset point) {
    _layerState.addPoint(point);
  }

  /// 释放资源
  void dispose() {
    _stateEventController.close();
    _layerState.dispose();
    _renderCache.dispose();
    _undoManager.removeStateChangeListener(_handleUndoManagerStateChange);
  }

  /// 结束擦除操作
  void endErase() {
    final operation = _layerState.commitCurrentOperation();
    if (operation != null) {
      _undoManager.push(operation);
      _undoManager.tryMergeLastOperations();
    }
  }

  /// 重做操作
  void redo() {
    _undoManager.redo();
  }

  /// 开始擦除操作
  void startErase(Offset point, double brushSize) {
    _layerState.startNewOperation(point, brushSize);
  }

  /// 撤销操作
  void undo() {
    _undoManager.undo();
  }

  /// 更新图层状态
  Future<void> updateLayerState(ui.Image originalImage) async {
    // 更新渲染缓存
    if (_renderCache.isDirty) {
      await _renderCache.updateStaticCache(originalImage);

      // 更新图层状态的缓冲
      _layerState.buffer = _renderCache.staticCache;
    }
  }

  /// 处理图层状态变化
  void _handleLayerStateChange() {
    // 同步缓存状态
    if (_layerState.isDirty) {
      _renderCache.invalidateCache();
    }

    // 通知状态事件
    _stateEventController.add(EraseStateEvent(
      type: _layerState.stateType,
      points: _layerState.displayPoints,
    ));
  }

  /// 处理撤销管理器状态变化
  void _handleUndoManagerStateChange(EraseOperation operation, bool isUndo) {
    if (isUndo) {
      _layerState.applyUndo(operation);

      // 通知状态事件
      _stateEventController.add(EraseStateEvent(
        type: EraseStateType.undoing,
        operation: operation,
      ));
    } else {
      _layerState.applyRedo(operation);

      // 通知状态事件
      _stateEventController.add(EraseStateEvent(
        type: EraseStateType.redoing,
        operation: operation,
      ));
    }
  }

  /// 设置状态同步
  void _setupStateSynchronization() {
    // 监听撤销管理器状态变化
    _undoManager.addStateChangeListener(_handleUndoManagerStateChange);

    // 监听图层状态变化
    _layerState.addListener(_handleLayerStateChange);
  }
}
