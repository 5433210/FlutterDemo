// filepath: lib/canvas/interaction/canvas_interaction_engine.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/canvas_state_manager.dart';
import '../core/commands/element_commands.dart';
import '../core/interfaces/element_data.dart';
import '../ui/toolbar/tool_state_manager.dart';
import 'magnetic_alignment_manager.dart';

class CanvasInteractionEngine extends ChangeNotifier {
  static const Duration _throttleDuration = Duration(milliseconds: 16);
  final CanvasStateManager _stateManager;
  final ToolStateManager _toolStateManager;

  final MagneticAlignmentManager _alignmentManager;
  InteractionMode _currentMode = InteractionMode.select;

  InteractionState _interactionState = const InteractionState();
  // 拖拽状态
  bool _isDragging = false;
  bool _isSelectionBoxActive = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;

  final Map<String, Offset> _elementStartPositions = {};

  // 命令缓存
  MoveElementsCommand? _currentMoveCommand;
  // 性能优化
  Timer? _throttleTimer;

  CanvasInteractionEngine(
    this._stateManager,
    this._toolStateManager,
    this._alignmentManager,
  );

  /// 当前交互模式
  InteractionMode get currentMode => _currentMode;

  /// 当前交互状态
  InteractionState get interactionState => _interactionState;

  /// 是否正在拖拽
  bool get isDragging => _isDragging;

  /// 是否正在使用选择框
  bool get isSelectionBoxActive => _isSelectionBoxActive;

  /// 选择框矩形
  Rect? get selectionBoxRect {
    if (!_isSelectionBoxActive ||
        _selectionStart == null ||
        _selectionEnd == null) {
      return null;
    }
    return Rect.fromPoints(_selectionStart!, _selectionEnd!);
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _toolStateManager.removeListener(_handleToolChange);
    _stateManager.removeListener(_handleStateChange);
    _cancelCurrentInteraction();
    super.dispose();
  }

  /// 处理输入事件
  void handleInputEvent(InputEvent event) {
    debugPrint(
        'CanvasInteractionEngine: 处理输入事件 ${event.type} at ${event.position}');

    // 转换为视口坐标
    final transformedPosition = _transformPosition(event.position);
    final transformedEvent = InputEvent(
      type: event.type,
      position: transformedPosition,
      device: event.device,
      pressure: event.pressure,
      pointer: event.pointer,
      modifiers: event.modifiers,
      scrollDelta: event.scrollDelta,
    );

    // 根据当前模式处理事件
    switch (_currentMode) {
      case InteractionMode.select:
        _handleSelectModeInput(transformedEvent);
        break;
      case InteractionMode.pan:
        _handlePanModeInput(transformedEvent);
        break;
      case InteractionMode.zoom:
        _handleZoomModeInput(transformedEvent);
        break;
      case InteractionMode.rotate:
        _handleRotateModeInput(transformedEvent);
        break;
      case InteractionMode.resize:
        _handleResizeModeInput(transformedEvent);
        break;
      default:
        _handleDefaultModeInput(transformedEvent);
        break;
    }

    // 更新交互状态
    _updateInteractionState(transformedEvent);
  }

  /// 初始化交互引擎
  void initialize() {
    // 监听工具状态变化
    _toolStateManager.addListener(_handleToolChange);

    // 监听状态管理器变化
    _stateManager.addListener(_handleStateChange);
  }

  /// 设置交互模式
  void setInteractionMode(InteractionMode mode) {
    if (_currentMode != mode) {
      _cancelCurrentInteraction();
      _currentMode = mode;
      notifyListeners();
    }
  }

  /// 取消当前交互
  void _cancelCurrentInteraction() {
    if (_currentMoveCommand != null) {
      _stateManager.commandManager.undo();
      _currentMoveCommand = null;
    }

    _isDragging = false;
    _isSelectionBoxActive = false;
    _elementStartPositions.clear();
    _selectionStart = null;
    _selectionEnd = null;

    _interactionState = const InteractionState();
    notifyListeners();
  }

  /// 检查元素是否与矩形相交
  bool _elementIntersectsRect(ElementData element, Rect rect) {
    // 简化处理：使用元素边界框
    return element.bounds.overlaps(rect);
  }

  /// 完成拖拽
  void _finishDrag() {
    if (_currentMoveCommand != null) {
      // 提交移动命令
      _stateManager.commandManager.execute(_currentMoveCommand!);
      _currentMoveCommand = null;
      debugPrint('CanvasInteractionEngine: 完成拖拽');
    }

    _isDragging = false;
    _elementStartPositions.clear();
  }

  /// 完成选择框
  void _finishSelectionBox() {
    if (!_isSelectionBoxActive) return;

    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);

    // 如果选择框太小，视为点击
    if (rect.width < 5 && rect.height < 5) {
      final newState = _stateManager.selectionState.clearSelection();
      _stateManager.updateSelectionState(newState);
    }

    _isSelectionBoxActive = false;
    _selectionStart = null;
    _selectionEnd = null;

    debugPrint(
        'CanvasInteractionEngine: 完成选择框，选中 ${_stateManager.selectionState.selectedIds.length} 个元素');
    notifyListeners();
  }

  /// 获取矩形内的元素
  List<String> _getElementsInRect(Rect rect) {
    final result = <String>[];
    final elements = _stateManager.elementState.sortedElements;

    for (final element in elements) {
      if (element.visible && _elementIntersectsRect(element, rect)) {
        result.add(element.id);
      }
    }

    return result;
  }

  /// 处理默认模式输入
  void _handleDefaultModeInput(InputEvent event) {
    _handleSelectModeInput(event);
  }

  /// 处理拖拽移动
  void _handleDragMove(InputEvent event) {
    if (!_isDragging || _interactionState.startPosition == null) return;

    // 节流处理，避免过频繁的更新
    _throttleTimer?.cancel();
    _throttleTimer = Timer(_throttleDuration, () {
      _performDragMove(event);
    });
  }

  /// 处理平移模式输入
  void _handlePanModeInput(InputEvent event) {
    switch (event.type) {
      case InputEventType.down:
        // 记录开始位置
        break;
      case InputEventType.move:
        if (_interactionState.startPosition != null) {
          final delta = event.position - _interactionState.startPosition!;
          // TODO: 实现平移功能 - 需要添加viewportState支持
          // _stateManager.viewportState.pan(delta);
          debugPrint('CanvasInteractionEngine: 平移 delta=$delta');
        }
        break;
      case InputEventType.up:
        // 完成平移
        break;
      default:
        break;
    }
  }

  /// 处理缩放模式输入
  void _handleResizeModeInput(InputEvent event) {
    // TODO: 实现缩放交互
  }

  /// 处理旋转模式输入
  void _handleRotateModeInput(InputEvent event) {
    // TODO: 实现旋转交互
  }

  /// 处理选择模式按下
  void _handleSelectDown(InputEvent event) {
    final hitResult = _hitTest(event.position);

    if (hitResult != null) {
      // 点击到元素
      final elementId = hitResult.elementId;
      final isSelected = _stateManager.selectionState.isSelected(elementId);

      if (event.modifiers.contains(LogicalKeyboardKey.controlLeft) ||
          event.modifiers.contains(LogicalKeyboardKey.controlRight)) {
        // Ctrl+点击：切换选择状态
        if (isSelected) {
          final newState =
              _stateManager.selectionState.removeFromSelection(elementId);
          _stateManager.updateSelectionState(newState);
        } else {
          final newState =
              _stateManager.selectionState.addToSelection(elementId);
          _stateManager.updateSelectionState(newState);
        }
      } else if (event.modifiers.contains(LogicalKeyboardKey.shiftLeft) ||
          event.modifiers.contains(LogicalKeyboardKey.shiftRight)) {
        // Shift+点击：添加到选择
        final newState = _stateManager.selectionState.addToSelection(elementId);
        _stateManager.updateSelectionState(newState);
      } else {
        // 普通点击：单选
        if (!isSelected) {
          var newState = _stateManager.selectionState.clearSelection();
          newState = newState.addToSelection(elementId);
          _stateManager.updateSelectionState(newState);
        }
      }

      // 准备开始拖拽
      if (_stateManager.selectionState.hasSelection) {
        _prepareDrag(event.position);
      }
    } else {
      // 点击空白区域
      if (!event.modifiers.contains(LogicalKeyboardKey.controlLeft) &&
          !event.modifiers.contains(LogicalKeyboardKey.controlRight)) {
        _stateManager.selectionState.clearSelection();
      }

      // 开始选择框
      _startSelectionBox(event.position);
    }
  }

  /// 处理选择模式输入
  void _handleSelectModeInput(InputEvent event) {
    switch (event.type) {
      case InputEventType.down:
        _handleSelectDown(event);
        break;
      case InputEventType.move:
        _handleSelectMove(event);
        break;
      case InputEventType.up:
        _handleSelectUp(event);
        break;
      case InputEventType.cancel:
        _cancelCurrentInteraction();
        break;
      default:
        break;
    }
  }

  /// 处理选择模式移动
  void _handleSelectMove(InputEvent event) {
    if (_isDragging) {
      _handleDragMove(event);
    } else if (_isSelectionBoxActive) {
      _updateSelectionBox(event.position);
    }
  }

  /// 处理选择模式抬起
  void _handleSelectUp(InputEvent event) {
    if (_isDragging) {
      _finishDrag();
    } else if (_isSelectionBoxActive) {
      _finishSelectionBox();
    }
  }

  /// 处理状态变化
  void _handleStateChange() {
    // 当状态发生变化时通知监听者
    notifyListeners();
  }

  /// 处理工具变化
  void _handleToolChange() {
    final toolType = _toolStateManager.currentTool;

    switch (toolType) {
      case ToolType.select:
        setInteractionMode(InteractionMode.select);
        break;
      case ToolType.pan:
        setInteractionMode(InteractionMode.pan);
        break;
      case ToolType.zoom:
        setInteractionMode(InteractionMode.zoom);
        break;
      default:
        setInteractionMode(InteractionMode.select);
        break;
    }
  }

  /// 处理缩放模式输入
  void _handleZoomModeInput(InputEvent event) {
    if (event.type == InputEventType.wheel && event.scrollDelta != null) {
      final scaleFactor = 1.0 + (event.scrollDelta! * 0.001);
      // TODO: 实现缩放功能 - 需要添加viewportState支持
      // _stateManager.viewportState.zoom(scaleFactor, event.position);
      debugPrint(
          'CanvasInteractionEngine: 缩放 scaleFactor=$scaleFactor at ${event.position}');
    }
  }

  /// 点击测试
  HitTestResult? _hitTest(Offset position) {
    // 从顶层元素开始检查
    final elements = _stateManager.elementState.sortedElements;

    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      if (_isPointInElement(position, element)) {
        return HitTestResult(
          elementId: element.id,
          position: position,
          element: element,
        );
      }
    }

    return null;
  }

  /// 检查点是否在元素内
  bool _isPointInElement(Offset point, ElementData element) {
    if (!element.visible) return false;

    final bounds = element.bounds;

    // 如果元素有旋转，需要进行旋转变换
    if (element.rotation != 0) {
      final center = bounds.center;
      final rotatedPoint = _rotatePoint(point, center, -element.rotation);
      return bounds.contains(rotatedPoint);
    }

    return bounds.contains(point);
  }

  /// 执行拖拽移动
  void _performDragMove(InputEvent event) {
    final delta = event.position - _interactionState.startPosition!;

    // 如果是第一次移动，创建移动命令
    if (_currentMoveCommand == null) {
      final selectedIds = _stateManager.selectionState.selectedIds.toList();
      final deltas = <String, Offset>{};
      for (final elementId in selectedIds) {
        deltas[elementId] = delta;
      }

      _currentMoveCommand = MoveElementsCommand(
        stateManager: _stateManager,
        elementIds: selectedIds,
        deltas: deltas,
      );
    } else {
      // 更新移动距离
      _currentMoveCommand!.updateDelta(delta);
    }

    // 应用对齐
    final alignedPositions = <String, Offset>{};
    for (final elementId in _stateManager.selectionState.selectedIds) {
      final element = _stateManager.elementState.getElementById(elementId);
      if (element != null) {
        final newPosition = _elementStartPositions[elementId]! + delta;
        final alignResult = _alignmentManager.alignPosition(
          newPosition,
          _stateManager.selectionState.selectedIds
              .where((id) => id != elementId)
              .toList(),
        );
        alignedPositions[elementId] = alignResult.alignedPosition;
      }
    }

    // TODO: 预览移动效果 - previewExecute方法不存在，暂时跳过
    // _currentMoveCommand!.previewExecute(_stateManager, alignedPositions);

    debugPrint('CanvasInteractionEngine: 拖拽移动 delta=$delta');
  }

  /// 准备拖拽
  void _prepareDrag(Offset startPosition) {
    _isDragging = true;
    _elementStartPositions.clear();

    // 记录所有选中元素的初始位置
    for (final elementId in _stateManager.selectionState.selectedIds) {
      final element = _stateManager.elementState.getElementById(elementId);
      if (element != null) {
        _elementStartPositions[elementId] = element.bounds.topLeft;
      }
    }

    debugPrint(
        'CanvasInteractionEngine: 准备拖拽 ${_elementStartPositions.length} 个元素');
  }

  /// 旋转点
  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    return Offset(
      dx * cos - dy * sin + center.dx,
      dx * sin + dy * cos + center.dy,
    );
  }

  /// 开始选择框
  void _startSelectionBox(Offset position) {
    _isSelectionBoxActive = true;
    _selectionStart = position;
    _selectionEnd = position;
    debugPrint('CanvasInteractionEngine: 开始选择框 at $position');
  }

  /// 转换位置到画布坐标
  Offset _transformPosition(Offset screenPosition) {
    // TODO: 实现坐标转换 - 需要添加viewportState支持
    // final viewport = _stateManager.viewportState;
    // return viewport.screenToCanvas(screenPosition);

    // 暂时直接返回屏幕坐标
    return screenPosition;
  }

  /// 更新交互状态
  void _updateInteractionState(InputEvent event) {
    switch (event.type) {
      case InputEventType.down:
        _interactionState = _interactionState.copyWith(
          isActive: true,
          startPosition: event.position,
          currentPosition: event.position,
          device: event.device,
        );
        break;
      case InputEventType.move:
        if (_interactionState.isActive) {
          final delta = event.position - _interactionState.currentPosition;
          _interactionState = _interactionState.copyWith(
            currentPosition: event.position,
            delta: delta,
          );
        }
        break;
      case InputEventType.up:
      case InputEventType.cancel:
        _interactionState = _interactionState.copyWith(
          isActive: false,
          endPosition: event.position,
        );
        break;
      default:
        break;
    }
  }

  /// 更新选择框
  void _updateSelectionBox(Offset position) {
    if (!_isSelectionBoxActive) return;

    _selectionEnd = position;

    // 实时更新选择
    final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    final elementsInBox = _getElementsInRect(rect);

    var newState = _stateManager.selectionState.clearSelection();
    for (final elementId in elementsInBox) {
      newState = newState.addToSelection(elementId);
    }
    _stateManager.updateSelectionState(newState);

    notifyListeners();
  }
}

/// 点击测试结果
class HitTestResult {
  final String elementId;
  final Offset position;
  final ElementData element;

  const HitTestResult({
    required this.elementId,
    required this.position,
    required this.element,
  });
}

/// 输入设备类型
enum InputDevice {
  mouse,
  touch,
  pen,
  unknown,
}

/// 输入事件
class InputEvent {
  final InputEventType type;
  final Offset position;
  final InputDevice device;
  final double pressure;
  final int pointer;
  final Set<LogicalKeyboardKey> modifiers;
  final double? scrollDelta;

  const InputEvent({
    required this.type,
    required this.position,
    required this.device,
    this.pressure = 1.0,
    this.pointer = 0,
    this.modifiers = const {},
    this.scrollDelta,
  });
}

/// 输入事件类型
enum InputEventType {
  down,
  move,
  up,
  cancel,
  wheel,
  keyDown,
  keyUp,
}

/// 交互模式
enum InteractionMode {
  select,
  draw,
  text,
  pan,
  zoom,
  rotate,
  resize,
}

/// 交互状态
class InteractionState {
  final bool isActive;
  final Offset? startPosition;
  final Offset currentPosition;
  final Offset? endPosition;
  final Offset delta;
  final InputDevice device;
  final Map<String, dynamic> additionalData;

  const InteractionState({
    this.isActive = false,
    this.startPosition,
    this.currentPosition = Offset.zero,
    this.endPosition,
    this.delta = Offset.zero,
    this.device = InputDevice.unknown,
    this.additionalData = const {},
  });

  InteractionState copyWith({
    bool? isActive,
    Offset? startPosition,
    Offset? currentPosition,
    Offset? endPosition,
    Offset? delta,
    InputDevice? device,
    Map<String, dynamic>? additionalData,
  }) {
    return InteractionState(
      isActive: isActive ?? this.isActive,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      endPosition: endPosition ?? this.endPosition,
      delta: delta ?? this.delta,
      device: device ?? this.device,
      additionalData: additionalData ?? Map.from(this.additionalData),
    );
  }
}
