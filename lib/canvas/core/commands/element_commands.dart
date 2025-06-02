// filepath: lib/canvas/core/commands/element_commands.dart

import 'dart:ui';

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
  bool canMergeWith(Command other) => false;
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
  Command? mergeWith(Command other) => null;

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
  bool canMergeWith(Command other) => false;
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
  Command? mergeWith(Command other) => null;

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
}

/// 移动元素命令
class MoveElementsCommand implements Command {
  final CanvasStateManager stateManager;
  final List<String> elementIds;
  final Map<String, Offset> deltas;
  final Map<String, ElementData> _originalElements = {};

  MoveElementsCommand({
    required this.stateManager,
    required this.elementIds,
    required this.deltas,
  });

  @override
  String get description => 'Move ${elementIds.length} elements';

  @override
  String get id => 'move_elements_${elementIds.join('_')}';

  @override
  bool canMergeWith(Command other) {
    return other is MoveElementsCommand &&
        other.elementIds.length == elementIds.length &&
        other.elementIds.every((id) => elementIds.contains(id)) &&
        identical(other.stateManager, stateManager);
  }

  @override
  bool execute() {
    try {
      // 保存原始状态以便撤销
      _originalElements.clear();
      var newElementState = stateManager.elementState;

      for (final elementId in elementIds) {
        final element = stateManager.elementState.getElementById(elementId);
        if (element != null) {
          _originalElements[elementId] = element;

          final delta = deltas[elementId] ?? Offset.zero;
          final newBounds = element.bounds.translate(delta.dx, delta.dy);
          final updatedElement = element.copyWith(bounds: newBounds);

          newElementState =
              newElementState.updateElement(elementId, updatedElement);
        }
      }

      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Command? mergeWith(Command other) {
    if (!canMergeWith(other)) return null;

    final otherCommand = other as MoveElementsCommand;
    final mergedDeltas = <String, Offset>{};

    for (final elementId in elementIds) {
      final thisDelta = deltas[elementId] ?? Offset.zero;
      final otherDelta = otherCommand.deltas[elementId] ?? Offset.zero;
      mergedDeltas[elementId] = thisDelta + otherDelta;
    }

    return MoveElementsCommand(
      stateManager: stateManager,
      elementIds: elementIds,
      deltas: mergedDeltas,
    ).._originalElements.addAll(_originalElements);
  }

  @override
  bool undo() {
    try {
      var newElementState = stateManager.elementState;

      for (final entry in _originalElements.entries) {
        newElementState = newElementState.updateElement(entry.key, entry.value);
      }

      stateManager.updateElementState(newElementState);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 更新移动增量（用于拖拽过程中的实时更新）
  void updateDelta(Offset newDelta) {
    for (int i = 0; i < elementIds.length; i++) {
      if (i < deltas.length) {
        deltas[elementIds[i]] = newDelta;
      }
    }
  }
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
