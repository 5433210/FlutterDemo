import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_mode.dart';
import '../models/erase_operation.dart';
import '../models/render_types.dart';
import 'erase_tool_controller.dart';
import 'render_manager.dart';

class EraseToolControllerImpl extends EraseToolController {
  /// 最大栈大小
  static const int _maxStackSize = 50;
  final RenderManager _renderManager;
  final Queue<EraseOperation> _undoStack = Queue();

  final Queue<EraseOperation> _redoStack = Queue();
  EraseOperation? _currentOperation;
  double _brushSize;
  EraseMode _mode;
  bool _isErasing = false;
  final bool _isInitialized = false;
  Matrix4? _currentTransform;
  Rect? _viewport;

  Size? _canvasSize;

  EraseToolControllerImpl({
    required RenderManager renderManager,
    double? initialBrushSize,
    EraseMode? initialMode,
  })  : _renderManager = renderManager,
        _brushSize = initialBrushSize ?? 20.0,
        _mode = initialMode ?? EraseMode.normal;

  @override
  double get brushSize => _brushSize;

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  bool get canUndo => _undoStack.isNotEmpty;

  @override
  EraseOperation? get currentOperation => _currentOperation;

  @override
  List<Offset> get currentPoints =>
      _currentOperation?.points.toList() ?? const [];

  @override
  bool get isErasing => _isErasing;

  @override
  EraseMode get mode => _mode;

  @override
  List<EraseOperation> get operations =>
      [..._undoStack, if (_currentOperation != null) _currentOperation!];

  @override
  void applyOperations(Canvas canvas) {
    // 应用已完成的操作
    for (final operation in operations) {
      operation.apply(canvas);
    }

    // 应用当前操作
    _currentOperation?.apply(canvas);
  }

  @override
  void cancelErase() {
    if (!_isErasing) return;
    _currentOperation = null;
    _isErasing = false;
    _renderManager.invalidateLayer(LayerType.preview);
    notifyListeners();
  }

  @override
  void clearAll() {
    _undoStack.clear();
    _redoStack.clear();
    _currentOperation = null;
    _isErasing = false;
    _renderManager.invalidateLayer(LayerType.preview);
    notifyListeners();
  }

  @override
  void continueErase(Offset point) {
    if (!_isErasing || _currentOperation == null) return;

    // 添加点到当前操作
    _currentOperation!.addPoint(point);

    // 更新预览层的脏区域
    final pointBounds = Rect.fromCircle(
      center: point,
      radius: _brushSize / 2,
    );
    _renderManager.setDirtyRegion(LayerType.preview, pointBounds);

    notifyListeners();
  }

  @override
  void dispose() {
    _currentOperation = null;
    _undoStack.clear();
    _redoStack.clear();
    super.dispose();
  }

  @override
  void endErase() {
    if (!_isErasing || _currentOperation == null) return;

    // 优化路径点
    final optimizedOperation = _currentOperation!.optimize();

    // 添加到撤销栈
    _pushToUndoStack(optimizedOperation);

    // 清理当前操作
    _currentOperation = null;
    _isErasing = false;

    // 更新预览层
    _renderManager.invalidateLayer(LayerType.preview);
    notifyListeners();
  }

  @override
  Future<ui.Image?> getResultImage() async {
    if (_canvasSize == null) return null;

    // 获取预览层图像
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 设置初始剪裁区域
    canvas.clipRect(Offset.zero & _canvasSize!);

    // 应用所有操作
    applyOperations(canvas);

    // 获取图像
    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(
      _canvasSize!.width.round(),
      _canvasSize!.height.round(),
    );

    return resultImage;
  }

  /// 使所有图层无效
  void invalidateAllLayers() {
    _renderManager.invalidateLayer(LayerType.original);
    _renderManager.invalidateLayer(LayerType.buffer);
    _renderManager.invalidateLayer(LayerType.preview);
  }

  @override
  void redo() {
    if (!canRedo) return;

    final operation = _redoStack.removeLast();
    _pushToUndoStack(operation);

    // 更新预览层
    _renderManager.invalidateLayer(LayerType.preview);
    notifyListeners();
  }

  @override
  void setBrushSize(double size) {
    if (size == _brushSize) return;
    _brushSize = size.clamp(5.0, 100.0);
    notifyListeners();
  }

  @override
  void setCanvasSize(Size size) {
    if (_canvasSize != size) {
      _canvasSize = size;
      // 通知渲染管理器
      _renderManager.prepare(size);
      invalidateAllLayers();
    }
  }

  @override
  void setMode(EraseMode mode) {
    if (mode == _mode) return;
    _mode = mode;

    // 调整笔刷大小到新模式的范围
    final (min, max) = mode.brushSizeRange;
    _brushSize = _brushSize.clamp(min, max);

    notifyListeners();
  }

  @override
  void startErase(Offset point) {
    if (_isErasing) return;

    // 清除重做栈
    _redoStack.clear();

    // 创建新操作
    _currentOperation = EraseOperation(
      brushSize: _brushSize,
      mode: _mode,
    );
    _currentOperation!.addPoint(point);

    _isErasing = true;

    // 更新预览层的脏区域
    final pointBounds = Rect.fromCircle(
      center: point,
      radius: _brushSize / 2,
    );
    _renderManager.setDirtyRegion(LayerType.preview, pointBounds);

    notifyListeners();
  }

  @override
  void undo() {
    if (!canUndo) return;

    final operation = _undoStack.removeLast();
    _redoStack.add(operation);

    // 更新预览层
    _renderManager.invalidateLayer(LayerType.preview);
    notifyListeners();
  }

  /// 将操作添加到撤销栈
  void _pushToUndoStack(EraseOperation operation) {
    // 尝试与上一个操作合并
    if (_undoStack.isNotEmpty) {
      final lastOperation = _undoStack.last;
      if (lastOperation.canMergeWith(operation)) {
        _undoStack.removeLast();
        _undoStack.add(lastOperation.mergeWith(operation));
        return;
      }
    }

    _undoStack.add(operation);

    // 限制栈大小
    while (_undoStack.length > _maxStackSize) {
      _undoStack.removeFirst();
    }
  }
}
