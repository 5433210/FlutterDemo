// filepath: lib/canvas/core/commands/element_commands.dart

import '../canvas_state_manager.dart';
import '../interfaces/command.dart';
import '../interfaces/element_data.dart';

/// 添加元素命令
class AddElementCommand implements Command {
  final CanvasStateManager stateManager;
  final ElementData element;

  AddElementCommand({
    required this.stateManager,
    required this.element,
  });

  @override
  String get description => 'Add element ${element.type}';

  @override
  String get id => 'add_element_${element.id}';

  @override
  bool execute() {
    try {
      final newElementState = stateManager.elementState.addElement(element);
      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }
  @override
  bool undo() {
    try {
      final newElementState =
          stateManager.elementState.removeElement(element.id);
      final newSelectionState =
          stateManager.selectionState.removeFromSelection(element.id);
      stateManager.updateStates(
        elementState: newElementState,
        selectionState: newSelectionState,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  bool canMergeWith(Command other) => false;
  
  @override
  Command? mergeWith(Command other) => null;
}

/// 删除元素命令
class DeleteElementsCommand implements Command {
  final CanvasStateManager stateManager;
  final List<String> elementIds;
  final Map<String, ElementData> _deletedElements = {};

  DeleteElementsCommand({
    required this.stateManager,
    required this.elementIds,
  });

  @override
  String get description => 'Delete ${elementIds.length} elements';

  @override
  String get id => 'delete_elements_${elementIds.join('_')}';

  @override
  bool execute() {
    try {
      // 保存要删除的元素数据以便撤销
      _deletedElements.clear();
      for (final id in elementIds) {
        final element = stateManager.elementState.getElementById(id);
        if (element != null) {
          _deletedElements[id] = element;
        }
      }

      final newElementState =
          stateManager.elementState.removeElements(elementIds);
      final newSelectionState = elementIds.fold(
        stateManager.selectionState,
        (state, id) => state.removeFromSelection(id),
      );

      stateManager.updateStates(
        elementState: newElementState,
        selectionState: newSelectionState,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  @override
  bool undo() {
    try {
      var newElementState = stateManager.elementState;
      for (final element in _deletedElements.values) {
        newElementState = newElementState.addElement(element);
      }
      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  bool canMergeWith(Command other) => false;
  
  @override
  Command? mergeWith(Command other) => null;
}

/// 更新元素命令
class UpdateElementCommand implements Command {
  final CanvasStateManager stateManager;
  final String elementId;
  final ElementData newElementData;
  ElementData? _previousElementData;

  UpdateElementCommand({
    required this.stateManager,
    required this.elementId,
    required this.newElementData,
  });

  @override
  String get description => 'Update element $elementId';

  @override
  String get id => 'update_element_$elementId';

  @override
  bool canMergeWith(Command other) {
    return other is UpdateElementCommand &&
        other.elementId == elementId &&
        identical(other.stateManager, stateManager);
  }

  @override
  bool execute() {
    try {
      // 保存之前的数据以便撤销
      _previousElementData =
          stateManager.elementState.getElementById(elementId);
      if (_previousElementData == null) return false;

      final newElementState =
          stateManager.elementState.updateElement(elementId, newElementData);
      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Command? mergeWith(Command other) {
    if (!canMergeWith(other)) return null;

    final otherCommand = other as UpdateElementCommand;
    return UpdateElementCommand(
      stateManager: stateManager,
      elementId: elementId,
      newElementData: otherCommand.newElementData,
    ).._previousElementData = _previousElementData;
  }

  @override
  bool undo() {
    try {
      if (_previousElementData == null) return false;

      final newElementState = stateManager.elementState
          .updateElement(elementId, _previousElementData!);
      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }
}
