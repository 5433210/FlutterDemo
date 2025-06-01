// filepath: lib/canvas/compatibility/canvas_controller_adapter.dart

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import '../core/canvas_state_manager.dart';
import '../core/commands/command_manager.dart';
import '../core/commands/element_commands.dart';
import '../core/interfaces/element_data.dart';
import '../core/models/element_data.dart';

/// 兼容层适配器 - 将旧的API适配到新的架构
class CanvasControllerAdapter extends ChangeNotifier {
  late final CanvasStateManager _stateManager;

  CanvasControllerAdapter() {
    _stateManager = CanvasStateManager();
    _stateManager.addListener(() => notifyListeners());
  }

  /// 兼容旧API：是否可以重做
  bool get canRedo => _stateManager.canRedo;

  /// 兼容旧API：是否可以撤销
  bool get canUndo => _stateManager.canUndo;

  /// 暴露命令管理器给新组件使用
  CommandManager get commandManager => _stateManager.commandManager;

  /// 兼容旧API：获取所有元素
  List<Map<String, dynamic>> get elements {
    return _stateManager.elementState.sortedElements
        .map((element) => _elementToLegacyMap(element))
        .toList();
  }

  /// 兼容旧API：获取选中的元素ID列表
  List<String> get selectedElementIds {
    return _stateManager.selectionState.selectedIds.toList();
  }

  /// 暴露状态管理器给新组件使用
  CanvasStateManager get stateManager => _stateManager;

  /// 兼容旧API：添加元素
  void addElement(Map<String, dynamic> elementData) {
    final element = _legacyMapToElement(elementData);
    final command = AddElementCommand(
      stateManager: _stateManager,
      element: element,
    );
    _stateManager.commandManager.execute(command);
  }

  /// 兼容旧API：清除选择
  void clearSelection() {
    final newSelectionState = _stateManager.selectionState.clearSelection();
    _stateManager.updateSelectionState(newSelectionState);
  }

  /// 兼容旧API：删除选中的元素
  void deleteSelectedElements() {
    if (_stateManager.selectionState.selectedIds.isEmpty) return;

    final command = DeleteElementsCommand(
      stateManager: _stateManager,
      elementIds: _stateManager.selectionState.selectedIds.toList(),
    );
    _stateManager.commandManager.execute(command);
  }

  /// 兼容旧API：重做
  bool redo() => _stateManager.redo();

  /// 兼容旧API：选择元素
  void selectElement(String id, {bool addToSelection = false}) {
    final newSelectionState = addToSelection
        ? _stateManager.selectionState.addToSelection(id)
        : _stateManager.selectionState.selectSingle(id);
    _stateManager.updateSelectionState(newSelectionState);
  }

  /// 兼容旧API：撤销
  bool undo() => _stateManager.undo();

  /// 兼容旧API：更新元素
  void updateElement(String id, Map<String, dynamic> updates) {
    final currentElement = _stateManager.elementState.getElementById(id);
    if (currentElement == null) return;

    final elementMap = _elementToLegacyMap(currentElement);
    elementMap.addAll(updates);
    final updatedElement = _legacyMapToElement(elementMap);

    final command = UpdateElementCommand(
      stateManager: _stateManager,
      elementId: id,
      newElementData: updatedElement,
    );
    _stateManager.commandManager.execute(command);
  }

  /// 将新的ElementData转换为旧的Map格式
  Map<String, dynamic> _elementToLegacyMap(ElementData element) {
    return {
      'id': element.id,
      'type': element.type,
      'x': element.bounds.left,
      'y': element.bounds.top,
      'width': element.bounds.width,
      'height': element.bounds.height,
      'rotation': element.rotation,
      'opacity': element.opacity,
      'zIndex': element.zIndex,
      'isSelected': element.isSelected,
      'isLocked': element.isLocked,
      'isHidden': element.isHidden,
      ...element.properties,
    };
  }

  /// 将旧的Map格式转换为新的ElementData
  CanvasElementData _legacyMapToElement(Map<String, dynamic> data) {
    final properties = Map<String, dynamic>.from(data);

    // 移除基础属性，剩余的作为自定义属性
    final baseKeys = {
      'id',
      'type',
      'x',
      'y',
      'width',
      'height',
      'rotation',
      'opacity',
      'zIndex',
      'isSelected',
      'isLocked',
      'isHidden'
    };

    for (final key in baseKeys) {
      properties.remove(key);
    }

    return CanvasElementData(
      id: data['id'] as String,
      type: data['type'] as String,
      bounds: Rect.fromLTWH(
        (data['x'] as num?)?.toDouble() ?? 0.0,
        (data['y'] as num?)?.toDouble() ?? 0.0,
        (data['width'] as num?)?.toDouble() ?? 100.0,
        (data['height'] as num?)?.toDouble() ?? 100.0,
      ),
      rotation: (data['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (data['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: (data['zIndex'] as num?)?.toInt() ?? 0,
      isSelected: data['isSelected'] as bool? ?? false,
      isLocked: data['isLocked'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      properties: properties,
    );
  }
}
