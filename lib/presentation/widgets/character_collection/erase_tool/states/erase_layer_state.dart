import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_operation.dart';
import '../utils/render_cache.dart';

/// 擦除图层状态
/// 管理擦除操作的状态和缓冲
class EraseLayerState extends ChangeNotifier {
  /// 已完成的擦除操作列表
  final List<EraseOperation> _operations = [];

  /// 当前正在进行的擦除操作
  EraseOperation? _currentOperation;

  /// 图层缓冲
  ui.Image? _buffer;

  /// 是否需要重新生成缓冲
  bool _isDirty = true;

  /// 原始图像
  ui.Image? _originalImage;

  /// 当前状态类型
  EraseStateType _stateType = EraseStateType.idle;

  /// 渲染缓存
  final RenderCache _renderCache = RenderCache();

  /// 显示的轨迹点
  final List<Offset> _displayPoints = [];

  /// 显示的边界区域
  Rect? _dirtyRegion;

  /// 状态锁，防止并发问题
  bool _isUpdating = false;

  /// 获取图层缓冲
  ui.Image? get buffer => _buffer;

  /// 设置图层缓冲
  set buffer(ui.Image? buffer) {
    _buffer = buffer;
    _isDirty = false;
  }

  /// 获取当前操作
  EraseOperation? get currentOperation => _currentOperation;

  /// 获取当前擦除点
  List<Offset> get currentPoints => _currentOperation?.points ?? <Offset>[];

  /// 获取脏区域
  Rect? get dirtyRegion => _dirtyRegion;

  /// 获取显示点
  List<Offset> get displayPoints => List.unmodifiable(_displayPoints);

  /// 是否有当前操作
  bool get hasCurrentOperation => _currentOperation != null;

  /// 是否需要重建缓冲
  bool get isDirty => _isDirty;

  /// 获取所有已完成的操作
  List<EraseOperation> get operations => List.unmodifiable(_operations);

  /// 获取原始图像
  ui.Image? get originalImage => _originalImage;

  /// 设置原始图像
  set originalImage(ui.Image? image) {
    _originalImage = image;
    _isDirty = true;
    notifyListeners();
  }

  /// 获取渲染缓存
  RenderCache get renderCache => _renderCache;

  /// 获取当前状态类型
  EraseStateType get stateType => _stateType;

  /// 添加操作
  void addOperation(EraseOperation operation) {
    _operations.add(operation);
    _isDirty = true;
    notifyListeners();
  }

  /// 添加点到当前操作
  void addPoint(Offset point) {
    if (_currentOperation == null || _isUpdating) return;
    _isUpdating = true;

    try {
      _currentOperation!.addPoint(point);
      _displayPoints.add(point);

      // 更新脏区域
      _updateDirtyRegion(point, _currentOperation!.brushSize);

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 执行重做操作
  void applyRedo(EraseOperation operation) {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      _stateType = EraseStateType.redoing;

      // 添加到操作列表
      _operations.add(operation);

      // 更新渲染缓存
      _renderCache.invalidateCache();
      _isDirty = true;

      // 恢复状态
      _stateType = EraseStateType.idle;

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 执行撤销操作
  void applyUndo(EraseOperation operation) {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      _stateType = EraseStateType.undoing;

      // 从操作列表中移除
      _operations.removeWhere((op) => op.id == operation.id);

      // 更新渲染缓存
      _renderCache.invalidateCache();
      _isDirty = true;

      // 恢复状态
      _stateType = EraseStateType.idle;

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 取消当前操作
  void cancelCurrentOperation() {
    if (_currentOperation == null || _isUpdating) return;
    _isUpdating = true;

    try {
      _currentOperation = null;
      _displayPoints.clear();
      _dirtyRegion = null;
      _stateType = EraseStateType.idle;

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 清除所有操作
  void clearOperations() {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      _operations.clear();
      _currentOperation = null;
      _displayPoints.clear();
      _dirtyRegion = null;
      _renderCache.clearCache();
      _isDirty = true;
      _stateType = EraseStateType.idle;

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 提交当前操作
  EraseOperation? commitCurrentOperation() {
    if (_currentOperation == null || _isUpdating) return null;
    _isUpdating = true;

    try {
      _stateType = EraseStateType.committing;
      final operation = _currentOperation!;

      if (operation.points.length > 1) {
        // 只保存有效的操作
        _operations.add(operation);
        _isDirty = true;

        // 将当前显示点添加到渲染缓存
        _renderCache.addDisplayOperation(operation);
      }

      _currentOperation = null;
      _displayPoints.clear();
      _dirtyRegion = null;
      _stateType = EraseStateType.idle;

      notifyListeners();

      return operation.points.length > 1 ? operation : null;
    } finally {
      _isUpdating = false;
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _buffer?.dispose();
    _renderCache.dispose();
    super.dispose();
  }

  /// 标记图层为脏，需要重新生成缓冲
  void markDirty() {
    _isDirty = true;
    notifyListeners();
  }

  /// 移除最后一个操作
  EraseOperation? removeLastOperation() {
    if (_operations.isEmpty) return null;

    final operation = _operations.removeLast();
    _isDirty = true;
    notifyListeners();

    return operation;
  }

  /// 重置脏区域
  void resetDirtyRegion() {
    _dirtyRegion = null;
  }

  /// 开始新的擦除操作
  void startNewOperation(Offset point, double brushSize) {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      _stateType = EraseStateType.erasing;
      _currentOperation = EraseOperation(
        id: DateTime.now().toString(),
        brushSize: brushSize,
      );

      _currentOperation!.addPoint(point);
      _displayPoints.clear();
      _displayPoints.add(point);

      // 更新脏区域
      _updateDirtyRegion(point, brushSize);

      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// 更新脏区域
  void _updateDirtyRegion(Offset point, double brushSize) {
    final pointRect = Rect.fromCircle(
      center: point,
      radius: brushSize / 2,
    );

    if (_dirtyRegion == null) {
      _dirtyRegion = pointRect;
    } else {
      _dirtyRegion = _dirtyRegion!.expandToInclude(pointRect);
    }
  }
}

/// 擦除状态类型
enum EraseStateType {
  /// 空闲状态
  idle,

  /// 擦除中状态
  erasing,

  /// 提交操作状态
  committing,

  /// 撤销中状态
  undoing,

  /// 重做中状态
  redoing,
}
