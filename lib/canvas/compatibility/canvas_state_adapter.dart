// filepath: lib/canvas/compatibility/canvas_state_adapter.dart
// 兼容适配器 - 提供临时过渡层解决类型兼容问题

import 'package:flutter/foundation.dart';

import '../core/canvas_state_manager.dart';
import '../core/commands/command_manager.dart';
import '../core/interfaces/element_data.dart';
import '../core/interfaces/layer_data.dart';
import '../state/element_state.dart';
import '../state/selection_state.dart';

/// 兼容适配器
///
/// 为使用旧版 CanvasStateManager 的代码提供一个兼容层
/// 避免因类型不匹配导致的编译错误
class CanvasStateManagerAdapter extends ChangeNotifier {
  final CanvasStateManager _stateManager;

  CanvasStateManagerAdapter(this._stateManager) {
    // 添加监听器，当原状态管理器变化时通知这个适配器的监听器
    _stateManager.addListener(_notifyListeners);
  }

  // 基本属性和方法
  bool get canRedo => _stateManager.commandManager.canRedo;

  bool get canUndo => _stateManager.commandManager.canUndo;

  CommandManager get commandManager => _stateManager.commandManager;

  dynamic get elementState => _stateManager.elementState;

  /// 获取所有可选择的元素
  List<ElementData> get selectableElements {
    // 直接使用状态管理器的方法
    return _stateManager.elementState.sortedElements.where((element) {
      // 检查元素本身是否可见且未锁定
      if (!element.visible || element.locked) return false;

      // 检查元素所在图层是否可见且未锁定
      final layer = _stateManager.layerState.getLayerById(element.layerId);
      return layer != null && layer.visible && !layer.locked;
    }).toList();
  }

  List<ElementData> get selectedElements => _stateManager.selectedElements;

  dynamic get selectionState => _stateManager.selectionState;

  /// 获取底层的CanvasStateManager实例（供需要直接访问的代码使用）
  CanvasStateManager get underlying => _stateManager;

  /// 获取所有可见的元素
  List<ElementData> get visibleElements {
    // 直接使用状态管理器的方法
    return _stateManager.elementState.sortedElements.where((element) {
      // 检查元素本身是否可见
      if (!element.visible) return false;

      // 检查元素所在图层是否可见
      final layer = _stateManager.layerState.getLayerById(element.layerId);
      return layer != null && layer.visible;
    }).toList();
  }

  /// 添加元素到选择
  void addElementToSelection(String elementId) {
    _stateManager.addElementToSelection(elementId);
  }

  void clear() {
    // Clear the entire state manager
    _stateManager.clear();
  }

  /// 清除选择状态
  void clearSelection() {
    // 使用状态管理器的选择清除方法
    _stateManager
        .updateSelectionState(_stateManager.selectionState.clearSelection());
  }

  // 重写 ChangeNotifier 方法
  @override
  void dispose() {
    _stateManager.removeListener(_notifyListeners);
    super.dispose();
  }

  /// 获取元素数据
  ElementData? getElementById(String id) {
    return _stateManager.elementState.getElementById(id);
  }

  /// 获取指定图层上的所有元素
  List<ElementData> getElementsByLayerId(String layerId) {
    return _stateManager.getElementsByLayerId(layerId);
  }

  /// 获取图层数据
  LayerData? getLayerById(String id) {
    return _stateManager.getLayerById(id);
  }

  /// 判断元素是否可选择（考虑图层锁定和可见性）
  bool isElementSelectable(String elementId) {
    return _stateManager.isElementSelectable(elementId);
  }

  /// 判断元素是否可见（考虑图层可见性）
  bool isElementVisible(String elementId) {
    final element = getElementById(elementId);
    if (element == null || !element.visible) return false;

    // 检查元素所在图层是否可见
    final layer = getLayerById(element.layerId);
    return layer != null && layer.visible;
  }

  bool redo() => _stateManager.redo();

  /// 选择单个元素
  void selectElement(String elementId) {
    // 使用状态管理器的选择替换方法
    _stateManager.updateSelectionState(
        _stateManager.selectionState.replaceSelection(elementId));
  }

  bool undo() => _stateManager.undo();

  void updateElementState(dynamic newState) {
    // Note: Direct state updates are not supported in the new architecture
    // Consider using specific commands instead
    // This is kept for backward compatibility but should be migrated
    if (newState is ElementState) {
      _stateManager.updateElementState(newState);
    }
  }

  void updateSelectionState(dynamic newState) {
    // Note: Direct state updates are not supported in the new architecture
    // Consider using specific commands instead
    // This is kept for backward compatibility but should be migrated
    if (newState is SelectionState) {
      _stateManager.updateSelectionState(newState);
    }
  }

  void updateStates({dynamic elementState, dynamic selectionState}) {
    if (elementState != null && elementState is ElementState) {
      _stateManager.updateElementState(elementState);
    }
    if (selectionState != null && selectionState is SelectionState) {
      _stateManager.updateSelectionState(selectionState);
    }
  }

  // 辅助方法
  void _notifyListeners() {
    notifyListeners();
  }
}
