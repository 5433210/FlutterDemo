import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../components/canvas_ui_components.dart';

/// 画布状态管理 mixin
/// 负责统一管理画布的各种状态，包括拖拽状态、选择状态等
mixin CanvasStateMixin {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;
  
  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;

  // 状态管理
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isRotating = false;
  Map<String, dynamic>? _originalElementProperties;

  // 保存FreeControlPoints的最终状态（用于Commit阶段）
  Map<String, double>? _freeControlPointsFinalState;

  // 拖拽相关状态
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;

  // 拖拽准备状态：使用普通变量避免setState时序问题
  bool _isReadyForDrag = false;

  // 选择框状态管理 - 使用ValueNotifier<SelectionBoxState>替代原来的布尔值
  final ValueNotifier<SelectionBoxState> _selectionBoxNotifier =
      ValueNotifier(SelectionBoxState());

  // 跟踪页面变化，用于自动重置视图
  String? _lastPageKey;
  bool _hasInitializedView = false; // 防止重复初始化视图

  /// 获取拖拽状态
  bool get isDragging => _isDragging;

  /// 获取调整大小状态
  bool get isResizing => _isResizing;

  /// 获取旋转状态
  bool get isRotating => _isRotating;

  /// 获取原始元素属性
  Map<String, dynamic>? get originalElementProperties => _originalElementProperties;

  /// 获取FreeControlPoints最终状态
  Map<String, double>? get freeControlPointsFinalState => _freeControlPointsFinalState;

  /// 获取拖拽开始位置
  Offset get dragStart => _dragStart;

  /// 获取元素开始位置
  Offset get elementStartPosition => _elementStartPosition;

  /// 获取拖拽准备状态
  bool get isReadyForDrag => _isReadyForDrag;

  /// 获取选择框状态通知器
  ValueNotifier<SelectionBoxState> get selectionBoxNotifier => _selectionBoxNotifier;

  /// 获取最后页面键
  String? get lastPageKey => _lastPageKey;

  /// 获取视图初始化状态
  bool get hasInitializedView => _hasInitializedView;

  /// 更新拖拽状态
  void updateDragState({
    bool? isDragging,
    bool? isResizing,
    bool? isRotating,
    Map<String, dynamic>? originalElementProperties,
    Offset? dragStart,
    Offset? elementStartPosition,
    bool? isReadyForDrag,
  }) {
    AppLogger.debug(
      '更新拖拽状态',
      tag: 'Canvas',
      data: {
        'isDragging': isDragging ?? _isDragging,
        'isResizing': isResizing ?? _isResizing,
        'isRotating': isRotating ?? _isRotating,
        'isReadyForDrag': isReadyForDrag ?? _isReadyForDrag,
      },
    );

    if (isDragging != null) _isDragging = isDragging;
    if (isResizing != null) _isResizing = isResizing;
    if (isRotating != null) _isRotating = isRotating;
    if (originalElementProperties != null) _originalElementProperties = originalElementProperties;
    if (dragStart != null) _dragStart = dragStart;
    if (elementStartPosition != null) _elementStartPosition = elementStartPosition;
    if (isReadyForDrag != null) _isReadyForDrag = isReadyForDrag;
  }

  /// 设置FreeControlPoints最终状态
  void setFreeControlPointsFinalState(Map<String, double>? state) {
    AppLogger.debug(
      '设置FreeControlPoints最终状态',
      tag: 'Canvas',
      data: {'state': state != null ? state.toString() : 'null'},
    );
    _freeControlPointsFinalState = state;
  }

  /// 重置拖拽状态
  void resetDragState() {
    AppLogger.debug('重置拖拽状态', tag: 'Canvas');
    
    _isDragging = false;
    _isResizing = false;
    _isRotating = false;
    _originalElementProperties = null;
    _freeControlPointsFinalState = null;
    _dragStart = Offset.zero;
    _elementStartPosition = Offset.zero;
    _isReadyForDrag = false;
  }

  /// 更新页面跟踪状态
  void updatePageTracking(String? pageKey, {bool? hasInitialized}) {
    AppLogger.debug(
      '更新页面跟踪状态',
      tag: 'Canvas',
      data: {
        'oldPageKey': _lastPageKey,
        'newPageKey': pageKey,
        'hasInitialized': hasInitialized ?? _hasInitializedView,
      },
    );

    _lastPageKey = pageKey;
    if (hasInitialized != null) _hasInitializedView = hasInitialized;
  }

  /// 更新选择框状态
  void updateSelectionBoxState(SelectionBoxState state) {
    AppLogger.debug(
      '更新选择框状态',
      tag: 'Canvas',
      data: {
        'isActive': state.isActive,
        'hasStartPoint': state.startPoint != null,
        'hasEndPoint': state.endPoint != null,
      },
    );
    
    _selectionBoxNotifier.value = state;
  }

  /// 清除选择框状态
  void clearSelectionBoxState() {
    AppLogger.debug('清除选择框状态', tag: 'Canvas');
    _selectionBoxNotifier.value = SelectionBoxState();
  }

  /// 调试画布状态
  void debugCanvasState(String context) {
    final panEnabled = !(_isDragging || dragStateManager.isDragging || _isReadyForDrag);
    
    AppLogger.debug(
      '画布状态调试',
      tag: 'Canvas',
      data: {
        'context': context,
        'panEnabled': panEnabled,
        'isDragging': _isDragging,
        'dragManagerDragging': dragStateManager.isDragging,
        'isReadyForDrag': _isReadyForDrag,
        'selectedElementIds': controller.state.selectedElementIds,
        'currentTool': controller.state.currentTool,
      },
    );
  }

  /// 获取当前状态摘要
  Map<String, dynamic> getStateSummary() {
    final summary = {
      'isDragging': _isDragging,
      'isResizing': _isResizing,
      'isRotating': _isRotating,
      'isReadyForDrag': _isReadyForDrag,
      'hasOriginalProperties': _originalElementProperties != null,
      'hasFinalState': _freeControlPointsFinalState != null,
      'dragStart': '$_dragStart',
      'elementStartPosition': '$_elementStartPosition',
      'selectionBoxActive': _selectionBoxNotifier.value.isActive,
      'lastPageKey': _lastPageKey,
      'hasInitializedView': _hasInitializedView,
      'selectedElementsCount': controller.state.selectedElementIds.length,
      'currentTool': controller.state.currentTool,
      'dragManagerDragging': dragStateManager.isDragging,
    };

    AppLogger.debug(
      '获取状态摘要',
      tag: 'Canvas',
      data: summary,
    );

    return summary;
  }

  /// 检查状态一致性
  void validateStateConsistency() {
    final issues = <String>[];

    // 检查拖拽状态一致性
    if (_isDragging && !dragStateManager.isDragging) {
      issues.add('本地拖拽状态与拖拽管理器状态不一致');
    }

    // 检查选择状态一致性
    if (controller.state.selectedElementIds.isEmpty && _isDragging) {
      issues.add('没有选中元素但处于拖拽状态');
    }

    // 检查准备状态逻辑
    if (_isReadyForDrag && _isDragging) {
      issues.add('同时处于准备拖拽和正在拖拽状态');
    }

    if (issues.isNotEmpty) {
      AppLogger.warning(
        '状态一致性检查发现问题',
        tag: 'Canvas',
        data: {'issues': issues},
      );
    } else {
      AppLogger.debug('状态一致性检查通过', tag: 'Canvas');
    }
  }

  /// 释放状态资源
  void disposeStates() {
    AppLogger.debug('释放状态资源', tag: 'Canvas');
    
    _selectionBoxNotifier.dispose();
    resetDragState();
    _lastPageKey = null;
    _hasInitializedView = false;
  }
} 