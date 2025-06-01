// filepath: lib/canvas/core/canvas_state_manager.dart

import 'package:flutter/foundation.dart';

import '../state/element_state.dart';
import '../state/selection_state.dart';
import 'commands/command_manager.dart';
import 'interfaces/element_data.dart';

/// 画布状态管理器 - 集中管理所有画布状态
class CanvasStateManager extends ChangeNotifier {
  ElementState _elementState = const ElementState();
  SelectionState _selectionState = const SelectionState();

  late final CommandManager _commandManager;

  CanvasStateManager() {
    _commandManager = CommandManager(
      onStateChanged: () => notifyListeners(),
    );
  }

  /// 检查是否可以重做
  bool get canRedo => _commandManager.canRedo;

  /// 检查是否可以撤销
  bool get canUndo => _commandManager.canUndo;

  /// 命令管理器
  CommandManager get commandManager => _commandManager;

  /// 元素状态
  ElementState get elementState => _elementState;

  /// 获取选中的元素数据列表
  List<ElementData> get selectedElements {
    return _selectionState.selectedIds
        .map((id) => _elementState.getElementById(id))
        .where((element) => element != null)
        .cast<ElementData>()
        .toList();
  }

  /// 选择状态
  SelectionState get selectionState => _selectionState;

  /// 清除所有状态
  void clear() {
    _elementState = const ElementState();
    _selectionState = const SelectionState();
    _commandManager.clear();
    notifyListeners();
  }

  /// 重做操作
  bool redo() => _commandManager.redo();

  /// 撤销操作
  bool undo() => _commandManager.undo();

  /// 更新元素状态
  void updateElementState(ElementState newState) {
    _elementState = newState;
    notifyListeners();
  }

  /// 更新选择状态
  void updateSelectionState(SelectionState newState) {
    _selectionState = newState;
    notifyListeners();
  }

  /// 同时更新多个状态
  void updateStates({
    ElementState? elementState,
    SelectionState? selectionState,
  }) {
    bool hasChanges = false;

    if (elementState != null) {
      _elementState = elementState;
      hasChanges = true;
    }

    if (selectionState != null) {
      _selectionState = selectionState;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }
}
