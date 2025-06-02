// filepath: lib/canvas/core/canvas_state_manager.dart

import 'package:flutter/foundation.dart';

import '../state/element_state.dart';
import '../state/layer_state.dart';
import '../state/selection_state.dart';
import 'commands/command_manager.dart';
import 'interfaces/element_data.dart';
import 'interfaces/layer_data.dart';

/// 画布状态管理器 - 集中管理所有画布状态
class CanvasStateManager extends ChangeNotifier {
  ElementState _elementState = const ElementState();
  LayerState _layerState = const LayerState();
  SelectionState _selectionState = const SelectionState();
  String? _selectedLayerId;

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

  /// 图层状态
  LayerState get layerState => _layerState;

  /// 获取可选择的元素 (可见且未锁定)
  List<ElementData> get selectableElements {
    return _elementState.sortedElements.where((ElementData element) {
      // 检查元素本身是否可见且未锁定
      if (!element.visible || element.locked) return false;

      // 检查元素所在图层是否可见且未锁定
      final layer = _layerState.getLayerById(element.layerId);
      return layer != null && layer.visible && !layer.locked;
    }).toList();
  }

  /// 获取选中的元素数据列表
  List<ElementData> get selectedElements {
    return _selectionState.selectedIds
        .map((id) => _elementState.getElementById(id))
        .where((ElementData? element) => element != null)
        .cast<ElementData>()
        .toList();
  }

  /// 当前选中的图层ID
  String? get selectedLayerId => _selectedLayerId;

  /// 选择状态
  SelectionState get selectionState => _selectionState;

  /// 获取可见的元素
  List<ElementData> get visibleElements {
    return _elementState.sortedElements.where((ElementData element) {
      // 检查元素本身是否可见
      if (!element.visible) return false;

      // 检查元素所在图层是否可见
      final layer = _layerState.getLayerById(element.layerId);
      return layer != null && layer.visible;
    }).toList();
  }

  /// 添加元素
  void addElement(ElementData element) {
    _elementState = _elementState.addElement(element);
    notifyListeners();
  }

  /// 添加多个元素到选择 - 需检查图层约束
  void addElementsToSelection(Iterable<String> elementIds) {
    // 过滤出可选择的元素
    final selectableIds = elementIds.where(isElementSelectable);
    if (selectableIds.isNotEmpty) {
      _selectionState = _selectionState.addAllToSelection(selectableIds);
      notifyListeners();
    }
  }

  /// 添加元素到指定图层
  void addElementToLayer(ElementData element, String layerId) {
    final layer = _layerState.getLayerById(layerId);
    if (layer == null) return;

    // 确保元素有正确的图层ID
    final updatedElement = element.copyWith(layerId: layerId);

    // 添加元素
    _elementState = _elementState.addElement(updatedElement);
    notifyListeners();
  }

  /// 添加元素到选择 - 需检查图层约束
  void addElementToSelection(String elementId) {
    // 检查元素是否可选择（考虑图层约束）
    if (isElementSelectable(elementId)) {
      _selectionState = _selectionState.addToSelection(elementId);
      notifyListeners();
    }
  }

  /// 清除所有状态
  void clear() {
    _elementState = const ElementState();
    _layerState = const LayerState();
    _selectionState = const SelectionState();
    _selectedLayerId = null;
    _commandManager.clear();
    notifyListeners();
  }

  /// 清除选择
  void clearSelection() {
    _selectionState = _selectionState.clearSelection();
    notifyListeners();
  }

  /// 在指定图层上创建新元素
  void createElementOnLayer(ElementData element, String? layerId) {
    // 如果未指定图层ID，使用当前选中的图层
    final targetLayerId = layerId ?? _selectedLayerId;

    // 确认有有效的目标图层
    if (targetLayerId == null) return;

    final layer = _layerState.getLayerById(targetLayerId);
    if (layer == null) return;

    // 使用指定的图层ID创建元素
    final elementWithLayerId = element.copyWith(layerId: targetLayerId);
    _elementState = _elementState.addElement(elementWithLayerId);

    notifyListeners();
  }

  /// 创建新图层
  void createLayer(LayerData layer) {
    _layerState = _layerState.addLayer(layer);
    notifyListeners();
  }

  /// 删除图层
  void deleteLayer(String layerId) {
    if (layerId == _selectedLayerId) {
      _selectedLayerId = null;
    }
    _layerState = _layerState.removeLayer(layerId);
    notifyListeners();
  }

  /// 取消选择指定元素
  void deselectElement(String elementId) {
    _selectionState = _selectionState.removeFromSelection(elementId);
    notifyListeners();
  }

  /// 获取指定图层ID的所有元素
  List<ElementData> getElementsByLayerId(String layerId) {
    return _elementState.sortedElements
        .where((ElementData element) => element.layerId == layerId)
        .toList();
  }

  /// 获取图层数据
  LayerData? getLayerById(String layerId) {
    return _layerState.getLayerById(layerId);
  }

  /// 检查元素是否可选择
  bool isElementSelectable(String elementId) {
    final element = _elementState.getElementById(elementId);
    if (element == null) return false;

    // 元素必须可见且未锁定
    if (!element.visible || element.locked) return false;

    // 元素所在图层必须可见且未锁定
    final layer = _layerState.getLayerById(element.layerId);
    return layer != null && layer.visible && !layer.locked;
  }

  /// 将元素移动到另一个图层
  void moveElementToLayer(String elementId, String targetLayerId) {
    final element = _elementState.getElementById(elementId);
    final targetLayer = _layerState.getLayerById(targetLayerId);

    if (element != null && targetLayer != null) {
      final updatedElement = element.copyWith(layerId: targetLayerId);
      _elementState = _elementState.updateElement(elementId, updatedElement);
      notifyListeners();
    }
  }

  /// 重做操作
  bool redo() => _commandManager.redo();

  /// 删除元素
  void removeElement(String elementId) {
    _elementState = _elementState.removeElement(elementId);
    // 同时从选择中移除
    _selectionState = _selectionState.removeFromSelection(elementId);
    notifyListeners();
  }

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    _layerState = _layerState.reorderLayers(oldIndex, newIndex);
    notifyListeners();
  }

  /// 选择指定图层上的所有元素（需满足可选择条件）
  void selectAllElementsOnLayer(String layerId) {
    final layer = _layerState.getLayerById(layerId);
    if (layer == null) return;

    // 如果图层被锁定或不可见，则不选择任何元素
    if (!layer.visible || layer.locked) {
      _selectionState = const SelectionState();
      notifyListeners();
      return;
    }

    // 获取图层上的所有可选择元素
    final selectableIds = _elementState.sortedElements
        .where((element) =>
            element.layerId == layerId && element.visible && !element.locked)
        .map((element) => element.id)
        .toList();

    if (selectableIds.isNotEmpty) {
      _selectionState =
          _selectionState.replaceSelectionWithMultiple(selectableIds);
      notifyListeners();
    }
  }

  /// 选择元素 - 需检查图层约束
  void selectElement(String elementId) {
    // 检查元素是否可选择（考虑图层约束）
    if (isElementSelectable(elementId)) {
      _selectionState = _selectionState.replaceSelection(elementId);
      notifyListeners();
    }
  }

  /// 选择多个元素 - 需检查图层约束
  void selectElements(Iterable<String> elementIds) {
    // 过滤出可选择的元素
    final selectableIds = elementIds.where(isElementSelectable);
    if (selectableIds.isNotEmpty) {
      _selectionState =
          _selectionState.replaceSelectionWithMultiple(selectableIds);
      notifyListeners();
    }
  }

  /// 选择图层
  void selectLayer(String? layerId) {
    if (_selectedLayerId != layerId) {
      _selectedLayerId = layerId;

      // 清除现有元素选择
      _selectionState = const SelectionState();

      // 如果选择了一个有效图层，可以选择性地高亮显示该图层上的元素
      // 这里我们选择不自动选择元素，以便用户可以单独管理图层

      notifyListeners();
    }
  }

  /// 切换图层锁定状态
  void toggleLayerLock(String layerId, bool locked) {
    final layer = _layerState.getLayerById(layerId);
    if (layer != null) {
      // 更新图层锁定状态
      _layerState = _layerState.updateLayerProperties(
        layerId,
        {'locked': locked},
      );

      // 更新图层上的所有元素锁定状态
      final layerElements = getElementsByLayerId(layerId);
      ElementState newElementState = _elementState;

      for (final element in layerElements) {
        newElementState = newElementState.updateElement(
            element.id, element.copyWith(locked: locked));
      }

      _elementState = newElementState;

      // 如果锁定了图层，清除该图层上已选择的元素
      if (locked) {
        final selectedIds = _selectionState.selectedIds;
        final layerElementIds = layerElements.map((e) => e.id).toSet();
        final remainingSelectedIds = selectedIds.difference(layerElementIds);

        if (remainingSelectedIds.length != selectedIds.length) {
          _selectionState = SelectionState(selectedIds: remainingSelectedIds);
        }
      }

      notifyListeners();
    }
  }

  /// 切换图层可见性
  void toggleLayerVisibility(String layerId, bool visible) {
    final layer = _layerState.getLayerById(layerId);
    if (layer != null) {
      // 更新图层可见性
      _layerState = _layerState.updateLayerProperties(
        layerId,
        {'visible': visible},
      );

      // 更新图层上的所有元素可见性
      final layerElements = getElementsByLayerId(layerId);
      ElementState newElementState = _elementState;

      for (final element in layerElements) {
        newElementState = newElementState.updateElement(
            element.id, element.copyWith(visible: visible));
      }

      _elementState = newElementState;

      // 如果隐藏了图层，清除该图层上已选择的元素
      if (!visible) {
        final selectedIds = _selectionState.selectedIds;
        final layerElementIds = layerElements.map((e) => e.id).toSet();
        final remainingSelectedIds = selectedIds.difference(layerElementIds);

        if (remainingSelectedIds.length != selectedIds.length) {
          _selectionState = SelectionState(selectedIds: remainingSelectedIds);
        }
      }

      notifyListeners();
    }
  }

  /// 撤销操作
  bool undo() => _commandManager.undo();

  /// 更新元素
  void updateElement(String elementId, ElementData element) {
    _elementState = _elementState.updateElement(elementId, element);
    notifyListeners();
  }

  /// 更新元素状态
  void updateElementState(ElementState newState) {
    _elementState = newState;
    notifyListeners();
  }

  /// 更新图层属性
  void updateLayerProperties(String layerId, Map<String, dynamic> properties) {
    final layer = _layerState.getLayerById(layerId);
    if (layer != null) {
      _layerState = _layerState.updateLayerProperties(layerId, properties);
      notifyListeners();
    }
  }

  /// 更新图层状态
  void updateLayerState(LayerState newState) {
    _layerState = newState;
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
    LayerState? layerState,
    SelectionState? selectionState,
    String? selectedLayerId,
  }) {
    bool hasChanges = false;

    if (elementState != null) {
      _elementState = elementState;
      hasChanges = true;
    }

    if (layerState != null) {
      _layerState = layerState;
      hasChanges = true;
    }

    if (selectionState != null) {
      _selectionState = selectionState;
      hasChanges = true;
    }

    if (selectedLayerId != null) {
      _selectedLayerId = selectedLayerId;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }
}
