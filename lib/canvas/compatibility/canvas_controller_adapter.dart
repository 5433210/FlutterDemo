// filepath: lib/canvas/compatibility/canvas_controller_adapter.dart

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import '../core/commands/command_manager.dart';
import '../core/commands/element_commands.dart';
import '../core/interfaces/element_data.dart';
import 'canvas_state_adapter.dart';

/// 兼容层适配器 - 将旧的API适配到新的架构
class CanvasControllerAdapter extends ChangeNotifier {
  dynamic _stateManager;

  CanvasControllerAdapter() {
    // 初始化时不创建状态管理器，等待attach方法被调用
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
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// 兼容旧API：获取选中的元素ID列表
  List<String> get selectedElementIds {
    return _stateManager.selectionState.selectedIds.toList();
  }

  /// 兼容旧API：获取状态管理器（为toolbar_adapter提供）
  dynamic get state => _stateManager;

  /// 暴露状态管理器给新组件使用
  dynamic get stateManager => _stateManager;

  void addElement(Map<String, dynamic> elementData) {
    final element = _legacyMapToElement(elementData);
    final command = AddElementCommand(
      stateManager: _stateManager.underlying,
      element: element,
    );
    _stateManager.underlying.commandManager.execute(command);
  }

  /// 兼容旧API：添加空集字元素在指定位置
  void addEmptyCollectionElementAt(double x, double y) {
    final element = {
      'id': 'collection_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'characters': '',
        'fontSize': 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'gridLines': false,
        'showBackground': true,
      },
    };

    addElement(element);
  }

  /// 兼容旧API：添加空图片元素在指定位置
  void addEmptyImageElementAt(double x, double y) {
    final element = {
      'id': 'image_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'image',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'imageUrl': '',
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    addElement(element);
  }

  /// 兼容旧API：添加文本元素
  void addTextElement() {
    final element = {
      'id': 'text_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'text': '属性页\n输入文本',
        'fontFamily': 'sans-serif',
        'fontSize': 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'textAlign': 'left',
        'verticalAlign': 'top',
        'writingMode': 'horizontal-l',
        'lineHeight': 1.2,
        'letterSpacing': 0.0,
        'padding': 8.0,
        'fontWeight': 'normal',
        'fontStyle': 'normal',
      },
    };

    addElement(element);
  }

  /// 附加到画布
  void attach(dynamic stateManager) {
    assert(stateManager is CanvasStateManagerAdapter,
        'CanvasControllerAdapter requires a CanvasStateManagerAdapter');
    _stateManager = stateManager;
    _stateManager.addListener(() => notifyListeners());
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
      stateManager: _stateManager.underlying,
      elementIds: _stateManager.selectionState.selectedIds.toList(),
    );
    _stateManager.underlying.commandManager.execute(command);
  }

  /// 从画布分离
  void detach() {
    if (_stateManager != null) {
      _stateManager.removeListener(() => notifyListeners());
      _stateManager = null;
    }
  }

  /// 兼容旧API：退出选择模式
  void exitSelectMode() {
    // 清除选择
    clearSelection();
  }

  /// 兼容旧API：重做
  bool redo() => _stateManager.redo();

  /// 兼容旧API：选择元素
  void selectElement(String id, {bool addToSelection = false}) {
    if (addToSelection) {
      _stateManager.addElementToSelection(id);
    } else {
      _stateManager.clearSelection();
      _stateManager.addElementToSelection(id);
    }
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
      stateManager: _stateManager.underlying,
      elementId: id,
      newElementData: updatedElement,
    );
    _stateManager.underlying.commandManager.execute(command);
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
  ElementData _legacyMapToElement(Map<String, dynamic> data) {
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

    return ElementData(
      id: data['id'] as String,
      type: data['type'] as String,
      layerId: data['layerId'] as String? ?? 'default',
      bounds: Rect.fromLTWH(
        (data['x'] as num?)?.toDouble() ?? 0.0,
        (data['y'] as num?)?.toDouble() ?? 0.0,
        (data['width'] as num?)?.toDouble() ?? 100.0,
        (data['height'] as num?)?.toDouble() ?? 100.0,
      ),
      rotation: (data['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (data['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: (data['zIndex'] as num?)?.toInt() ?? 0,
      visible: !(data['isHidden'] as bool? ?? false),
      locked: data['isLocked'] as bool? ?? false,
      properties: properties,
    );
  }
}
