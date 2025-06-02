// filepath: lib/canvas/interaction/gesture_handler.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../compatibility/canvas_state_adapter.dart';
import '../core/canvas_state_manager.dart';
import '../core/commands/element_commands.dart';
import '../core/interfaces/element_data.dart';
import '../ui/toolbar/tool_state_manager.dart';

/// 画布手势处理器
class CanvasGestureHandler extends ChangeNotifier {
  final dynamic _stateManager;
  final ToolStateManager _toolStateManager;

  GestureState _gestureState = const GestureState();
  bool _isDraggingElements = false;
  MoveElementsCommand? _currentMoveCommand;

  CanvasGestureHandler(this._stateManager, this._toolStateManager) {
    assert(
        _stateManager is CanvasStateManager ||
            _stateManager is CanvasStateManagerAdapter,
        'stateManager must be either CanvasStateManager or CanvasStateManagerAdapter');
  }

  /// 当前手势状态
  GestureState get gestureState => _gestureState;

  /// 是否正在拖拽元素
  bool get isDraggingElements => _isDraggingElements;

  /// 是否正在使用选择框
  bool get isSelectionBoxActive => _gestureState.isSelectionBoxActive;

  /// 选择框矩形
  Rect? get selectionBoxRect => _gestureState.selectionBoxRect;

  @override
  void dispose() {
    _resetGestureState();
    super.dispose();
  }

  /// 处理指针取消事件
  void handlePointerCancel(InputEvent event) {
    debugPrint('Canvas手势处理：指针取消');

    if (_currentMoveCommand != null) {
      _stateManager.commandManager.undo();
      _currentMoveCommand = null;
    }

    _resetGestureState();
    notifyListeners();
  }

  /// 处理指针按下事件
  void handlePointerDown(InputEvent event) {
    debugPrint('Canvas手势处理：指针按下 - 位置: ${event.position}');

    // 根据当前工具决定处理逻辑
    final currentTool = _toolStateManager.currentTool;

    switch (currentTool) {
      case ToolType.select:
        _handleSelectToolDown(event);
        break;
      case ToolType.text:
        _handleTextToolDown(event);
        break;
      case ToolType.image:
        _handleImageToolDown(event);
        break;
      case ToolType.collection:
        _handleCollectionToolDown(event);
        break;
      case ToolType.pan:
        _handlePanToolDown(event);
        break;
      case ToolType.zoom:
        _handleZoomToolDown(event);
        break;
      default:
        _handleDefaultToolDown(event);
        break;
    }

    _updateGestureState(
      isActive: true,
      startPosition: event.position,
      currentPosition: event.position,
    );

    notifyListeners();
  }

  /// 处理指针移动事件
  void handlePointerMove(InputEvent event) {
    if (!_gestureState.isActive) return;

    final delta = event.position - (_gestureState.startPosition ?? Offset.zero);

    if (_isDraggingElements) {
      _handleElementDrag(event, delta);
    } else if (_gestureState.isSelectionBoxActive) {
      _handleSelectionBoxUpdate(event);
    }

    _updateGestureState(currentPosition: event.position);
    notifyListeners();
  }

  /// 处理指针抬起事件
  void handlePointerUp(InputEvent event) {
    debugPrint('Canvas手势处理：指针抬起');

    if (_isDraggingElements) {
      _finalizeDragOperation();
    } else if (_gestureState.isSelectionBoxActive) {
      _finalizeSelectionBox(event);
    }

    _resetGestureState();
    notifyListeners();
  }

  /// 完成拖拽操作
  void _finalizeDragOperation() {
    _isDraggingElements = false;
    _currentMoveCommand = null;
    debugPrint('Canvas手势处理：拖拽操作完成');
  }

  /// 完成选择框操作
  void _finalizeSelectionBox(InputEvent event) {
    final selectionRect = _gestureState.selectionBoxRect;
    if (selectionRect == null) return;

    // 选择框太小时视为点击
    if (selectionRect.width < 5 && selectionRect.height < 5) {
      debugPrint('Canvas手势处理：选择框太小，视为点击');
      return;
    }

    // 选择与选择框相交的元素
    final elements = _stateManager.elementState.elements.values;
    final selectedIds = <String>[];

    for (final element in elements) {
      if (selectionRect.overlaps(element.bounds)) {
        selectedIds.add(element.id);
      }
    }

    // 如果不是多选模式，先清除现有选择
    if (!event.isMultiSelectMode) {
      _stateManager
          .updateSelectionState(_stateManager.selectionState.clearSelection());
    }

    // 选择新元素
    var newSelectionState = _stateManager.selectionState;
    for (final id in selectedIds) {
      newSelectionState = newSelectionState.addToSelection(id);
    }
    _stateManager.updateSelectionState(newSelectionState);

    debugPrint('Canvas手势处理：选择框选择了 ${selectedIds.length} 个元素');
  }

  void _handleCollectionToolDown(InputEvent event) {
    // 创建集字元素的逻辑
    debugPrint('Canvas手势处理：集字工具点击 - 位置: ${event.position}');
    final collectionElement = ElementData(
      id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
      type: 'collection',
      layerId: 'default',
      bounds: Rect.fromLTWH(
          event.position.dx - 50, event.position.dy - 50, 100, 100),
      properties: {
        'characters': '请输入汉字',
        'fontSize': 24.0,
        'fontColor': '#000000',
        'writingMode': 'horizontal-l',
        'letterSpacing': 0.0,
        'lineSpacing': 0.0,
        'textAlign': 'left',
        'verticalAlign': 'top',
      },
    );

    final command = AddElementCommand(
      stateManager: _stateManager,
      element: collectionElement,
    );

    _stateManager.commandManager.execute(command);

    // 选择新创建的元素
    _stateManager.updateSelectionState(
        _stateManager.selectionState.selectSingle(collectionElement.id));
  }

  /// 处理平移工具的指针按下
  /// 处理默认工具的指针按下
  void _handleDefaultToolDown(InputEvent event) {
    // 默认处理逻辑（通常是选择模式）
    _handleSelectToolDown(event);
  }

  /// 处理元素拖拽
  void _handleElementDrag(InputEvent event, Offset delta) {
    final selectedIds = _stateManager.selectionState.selectedIds.toList();

    if (selectedIds.isEmpty) return;

    // 如果还没有创建移动命令，创建一个
    if (_currentMoveCommand == null) {
      final deltas = <String, Offset>{};
      for (final elementId in selectedIds) {
        deltas[elementId] = delta;
      }

      _currentMoveCommand = MoveElementsCommand(
        stateManager: _stateManager,
        elementIds: selectedIds,
        deltas: deltas,
      );
      _stateManager.commandManager.execute(_currentMoveCommand!);
    } else {
      // 更新现有命令的增量
      _currentMoveCommand!.updateDelta(delta);
      // 重新执行命令以更新状态
      _currentMoveCommand!.execute();
    }
  }

  /// 处理元素命中
  void _handleElementHit(InputEvent event, ElementData hitElement) {
    final isSelected = _stateManager.selectionState.isSelected(hitElement.id);

    if (event.isMultiSelectMode) {
      // 多选模式：切换选择状态
      if (isSelected) {
        _stateManager.updateSelectionState(
            _stateManager.selectionState.removeFromSelection(hitElement.id));
      } else {
        _stateManager.updateSelectionState(
            _stateManager.selectionState.addToSelection(hitElement.id));
      }
    } else {
      // 单选模式
      if (!isSelected) {
        // 选择新元素
        _stateManager.updateSelectionState(
            _stateManager.selectionState.selectSingle(hitElement.id));
      }

      // 准备拖拽操作
      _prepareDragOperation();
    }
  }

  /// 处理空白区域命中
  void _handleEmptyAreaHit(InputEvent event) {
    if (!event.isMultiSelectMode) {
      // 非多选模式下清除选择
      _stateManager
          .updateSelectionState(_stateManager.selectionState.clearSelection());
    }

    // 开始选择框操作
    _startSelectionBox(event.position);
  }

  /// 处理图像工具的指针按下
  void _handleImageToolDown(InputEvent event) {
    // 创建图像元素的逻辑
    debugPrint('Canvas手势处理：图像工具点击 - 位置: ${event.position}');
    final imageElement = ElementData(
      id: 'image_${DateTime.now().millisecondsSinceEpoch}',
      type: 'image',
      layerId: 'default',
      bounds: Rect.fromLTWH(
          event.position.dx - 75, event.position.dy - 75, 150, 150),
      properties: {
        'imageUrl': '', // 这里可以弹出文件选择器
        'fit': 'contain',
        'alignment': 'center',
      },
    );

    final command = AddElementCommand(
      stateManager: _stateManager,
      element: imageElement,
    );

    _stateManager.commandManager.execute(command);

    // 选择新创建的元素
    _stateManager.updateSelectionState(
        _stateManager.selectionState.selectSingle(imageElement.id));
  }

  /// 处理平移工具的指针按下
  void _handlePanToolDown(InputEvent event) {
    // 开始画布平移
    debugPrint('Canvas手势处理：平移工具激活 - 位置: ${event.position}');

    // 平移工具不需要创建元素，而是改变画布视图状态
    // 这里暂时使用现有的手势状态，后续可以扩展
    _updateGestureState(
      startPosition: event.position,
    );
  }

  /// 更新选择框
  void _handleSelectionBoxUpdate(InputEvent event) {
    final startPos = _gestureState.startPosition;
    if (startPos == null) return;

    final selectionRect = Rect.fromPoints(startPos, event.position);
    _updateGestureState(selectionBoxRect: selectionRect);
  }

  /// 处理选择工具的指针按下
  void _handleSelectToolDown(InputEvent event) {
    // 执行命中测试
    final hitElements = _performHitTest(event.position);

    if (hitElements.isNotEmpty) {
      _handleElementHit(event, hitElements.first);
    } else {
      _handleEmptyAreaHit(event);
    }
  }

  /// 处理文本工具的指针按下
  void _handleTextToolDown(InputEvent event) {
    // 创建文本元素的逻辑
    debugPrint('Canvas手势处理：文本工具点击 - 位置: ${event.position}');
    final textElement = ElementData(
      id: 'text_${DateTime.now().millisecondsSinceEpoch}',
      type: 'text',
      layerId: 'default',
      bounds: Rect.fromLTWH(
          event.position.dx - 100, event.position.dy - 25, 200, 50),
      properties: {
        'text': '输入文本',
        'fontSize': 16.0,
        'fontColor': '#000000',
        'fontFamily': 'sans-serif',
        'fontWeight': 'normal',
        'fontStyle': 'normal',
        'textAlign': 'left',
        'backgroundColor': 'transparent',
      },
    );

    final command = AddElementCommand(
      stateManager: _stateManager,
      element: textElement,
    );

    _stateManager.commandManager.execute(command);

    // 选择新创建的元素
    _stateManager.updateSelectionState(
        _stateManager.selectionState.selectSingle(textElement.id));
  }

  /// 处理缩放工具的指针按下
  void _handleZoomToolDown(InputEvent event) {
    // 处理画布缩放
    debugPrint('Canvas手势处理：缩放工具激活 - 位置: ${event.position}');

    // 缩放工具可以在点击位置进行缩放
    // 这里暂时记录缩放起始位置，具体缩放逻辑由Canvas组件处理
    _updateGestureState(
      startPosition: event.position,
    );
  }

  /// 执行命中测试
  List<ElementData> _performHitTest(Offset position) {
    final elements = _stateManager.elementState.elements.values.toList();
    final hitElements = <ElementData>[];

    // 从顶层到底层检查（逆序）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      if (element.bounds.contains(position)) {
        hitElements.add(element);
      }
    }

    return hitElements;
  }

  /// 准备拖拽操作
  void _prepareDragOperation() {
    _isDraggingElements = true;

    // 记录所有选中元素的初始位置
    final startPositions = <String, Offset>{};
    for (final elementId in _stateManager.selectionState.selectedIds) {
      final element = _stateManager.elementState.getElementById(elementId);
      if (element != null) {
        startPositions[elementId] = element.bounds.topLeft;
      }
    }

    _updateGestureState(
      selectedElementIds: _stateManager.selectionState.selectedIds.toList(),
      elementStartPositions: startPositions,
    );
  }

  /// 重置手势状态
  void _resetGestureState() {
    _gestureState = const GestureState();
    _isDraggingElements = false;
    _currentMoveCommand = null;
  }

  /// 开始选择框操作
  void _startSelectionBox(Offset startPosition) {
    _updateGestureState(
      isSelectionBoxActive: true,
      selectionBoxRect: Rect.fromPoints(startPosition, startPosition),
    );
  }

  /// 更新手势状态
  void _updateGestureState({
    bool? isActive,
    Offset? startPosition,
    Offset? currentPosition,
    List<String>? selectedElementIds,
    Map<String, Offset>? elementStartPositions,
    bool? isSelectionBoxActive,
    Rect? selectionBoxRect,
  }) {
    _gestureState = _gestureState.copyWith(
      isActive: isActive,
      startPosition: startPosition,
      currentPosition: currentPosition,
      selectedElementIds: selectedElementIds,
      elementStartPositions: elementStartPositions,
      isSelectionBoxActive: isSelectionBoxActive,
      selectionBoxRect: selectionBoxRect,
    );
  }
}

/// 手势状态
class GestureState {
  final bool isActive;
  final Offset? startPosition;
  final Offset? currentPosition;
  final List<String> selectedElementIds;
  final Map<String, Offset> elementStartPositions;
  final bool isSelectionBoxActive;
  final Rect? selectionBoxRect;

  const GestureState({
    this.isActive = false,
    this.startPosition,
    this.currentPosition,
    this.selectedElementIds = const [],
    this.elementStartPositions = const {},
    this.isSelectionBoxActive = false,
    this.selectionBoxRect,
  });

  GestureState copyWith({
    bool? isActive,
    Offset? startPosition,
    Offset? currentPosition,
    List<String>? selectedElementIds,
    Map<String, Offset>? elementStartPositions,
    bool? isSelectionBoxActive,
    Rect? selectionBoxRect,
  }) {
    return GestureState(
      isActive: isActive ?? this.isActive,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      selectedElementIds: selectedElementIds ?? this.selectedElementIds,
      elementStartPositions:
          elementStartPositions ?? this.elementStartPositions,
      isSelectionBoxActive: isSelectionBoxActive ?? this.isSelectionBoxActive,
      selectionBoxRect: selectionBoxRect ?? this.selectionBoxRect,
    );
  }
}

/// 输入设备类型
enum InputDevice { mouse, touch, pen, unknown }

/// 输入事件模型
class InputEvent {
  final InputEventType type;
  final Offset position;
  final InputDevice device;
  final double pressure;
  final int pointer;
  final Set<LogicalKeyboardKey> modifiers;
  final DateTime timestamp;
  InputEvent({
    required this.type,
    required this.position,
    this.device = InputDevice.unknown,
    this.pressure = 1.0,
    this.pointer = 0,
    this.modifiers = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 是否按下Ctrl键
  bool get isCtrlPressed =>
      modifiers.contains(LogicalKeyboardKey.controlLeft) ||
      modifiers.contains(LogicalKeyboardKey.controlRight);

  /// 是否多选模式
  bool get isMultiSelectMode => isCtrlPressed || isShiftPressed;

  /// 是否按下Shift键
  bool get isShiftPressed =>
      modifiers.contains(LogicalKeyboardKey.shiftLeft) ||
      modifiers.contains(LogicalKeyboardKey.shiftRight);
}

/// 输入事件类型
enum InputEventType { down, move, up, cancel }
