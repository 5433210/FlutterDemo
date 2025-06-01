### 3. 选择操作 (续)

#### 3.3 取消选择

**现有实现**:
- 清空选择集合
- 通知UI更新

**重构影响**:
- **修改**: 取消选择操作改为命令模式
- **删除**: 直接修改选择状态的代码
- **新增**: `ClearSelectionCommand`命令类
- **保留**: 空

**调整方案**:
```dart
// 旧实现
void clearSelection() {
  _selectedElements.clear();
  notifyListeners();
}

// 新实现
void clearSelection() {
  final command = ClearSelectionCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class ClearSelectionCommand implements Command {
  Set<String>? previousSelection;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存之前的选择状态用于撤销
    previousSelection = Set.from(stateManager.selectionState.selectedElementIds);
    
    // 清除选择
    stateManager.selectionState.clearSelection();
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (previousSelection != null && previousSelection!.isNotEmpty) {
      // 恢复之前的选择状态
      stateManager.selectionState.setSelection(previousSelection!);
    }
  }
}
```

#### 3.4 追加选择

**现有实现**:
- 检查修饰键（通常是Shift）
- 添加或移除元素到/从选择集合
- 通知UI更新

**重构影响**:
- **修改**: 追加选择逻辑移至交互引擎
- **删除**: 直接修改选择状态的代码
- **新增**: `ToggleSelectionCommand`命令类
- **保留**: 修饰键检测逻辑

**调整方案**:
```dart
// 旧实现
void toggleElementSelection(String elementId, bool isShiftPressed) {
  if (isShiftPressed) {
    // 追加/移除选择
    if (_selectedElements.contains(elementId)) {
      _selectedElements.remove(elementId);
    } else {
      _selectedElements.add(elementId);
    }
  } else {
    // 替换选择
    _selectedElements.clear();
    _selectedElements.add(elementId);
  }
  notifyListeners();
}

// 新实现 - 交互引擎中
void handleSelectionTap(InputEvent event) {
  final hitResult = stateManager.hitTestManager.hitTest(event.position);
  if (hitResult.isNotEmpty) {
    final elementId = hitResult.first;
    final isAppend = event.modifiers.contains(ModifierKey.shift);
    
    final command = ToggleSelectionCommand(
      elementId: elementId,
      appendToSelection: isAppend,
    );
    commandManager.executeCommand(command);
  } else if (!event.modifiers.contains(ModifierKey.shift)) {
    // 点击空白区域，清除选择
    commandManager.executeCommand(ClearSelectionCommand());
  }
}

// 新增的命令实现
class ToggleSelectionCommand implements Command {
  final String elementId;
  final bool appendToSelection;
  Set<String>? previousSelection;
  
  ToggleSelectionCommand({
    required this.elementId,
    this.appendToSelection = false,
  });
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存之前的选择状态
    previousSelection = Set.from(stateManager.selectionState.selectedElementIds);
    
    if (appendToSelection) {
      // 追加/移除选择
      stateManager.selectionState.toggleSelection(elementId);
    } else {
      // 替换选择
      stateManager.selectionState.setSelection({elementId});
    }
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (previousSelection != null) {
      // 恢复之前的选择状态
      stateManager.selectionState.setSelection(previousSelection!);
    }
  }
}
```

#### 3.5 反向选择

**现有实现**:
- 获取所有元素ID
- 计算当前未选择的元素ID
- 更新选择集合
- 通知UI更新

**重构影响**:
- **修改**: 反向选择操作改为命令模式
- **删除**: 直接修改选择状态的代码
- **新增**: `InvertSelectionCommand`命令类
- **保留**: 集合差集计算逻辑

**调整方案**:
```dart
// 旧实现
void invertSelection() {
  // 获取所有元素ID
  final allIds = _elements.map((e) => e.id).toSet();
  
  // 计算未选择的元素
  final unselectedIds = allIds.difference(_selectedElements);
  
  // 更新选择
  _selectedElements.clear();
  _selectedElements.addAll(unselectedIds);
  
  notifyListeners();
}

// 新实现
void invertSelection() {
  final command = InvertSelectionCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class InvertSelectionCommand implements Command {
  Set<String>? previousSelection;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存之前的选择状态
    previousSelection = Set.from(stateManager.selectionState.selectedElementIds);
    
    // 获取所有元素ID
    final allIds = stateManager.elementState.elements.keys.toSet();
    
    // 计算未选择的元素
    final unselectedIds = allIds.difference(stateManager.selectionState.selectedElementIds);
    
    // 设置新的选择状态
    stateManager.selectionState.setSelection(unselectedIds);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (previousSelection != null) {
      // 恢复之前的选择状态
      stateManager.selectionState.setSelection(previousSelection!);
    }
  }
}
```

### 4. 元素控制（控制点）

#### 4.1 平移元素

**现有实现**:
- 跟踪拖动事件
- 实时更新元素位置
- 可能应用网格贴附
- 通知UI更新

**重构影响**:
- **修改**: 平移操作移至交互引擎，通过命令模式实现
- **删除**: 直接修改元素位置的代码
- **新增**: `MoveElementsCommand`命令类和交互处理器
- **保留**: 平移计算逻辑和贴附算法

**调整方案**:
```dart
// 旧实现
void handleElementDrag(String elementId, Offset delta) {
  final element = _getElementById(elementId);
  if (element == null) return;
  
  // 更新位置
  element.position = element.position + delta;
  
  // 应用网格贴附
  if (_gridSnapEnabled) {
    element.position = _snapToGrid(element.position);
  }
  
  notifyListeners();
}

// 新实现 - 交互引擎中
class ElementDragTool implements InteractionTool {
  Offset? _lastPosition;
  Set<String>? _draggedElementIds;
  MoveElementsCommand? _currentCommand;
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    switch (event.type) {
      case InputEventType.down:
        // 确定拖动的元素
        final hitResult = stateManager.hitTestManager.hitTest(event.position);
        if (hitResult.isNotEmpty) {
          final elementId = hitResult.first;
          
          // 如果点击的元素在当前选择中，拖动所有选择的元素
          if (stateManager.selectionState.isSelected(elementId)) {
            _draggedElementIds = Set.from(stateManager.selectionState.selectedElementIds);
          } else {
            // 否则，仅拖动点击的元素，并更新选择
            _draggedElementIds = {elementId};
            
            // 如果没有按Shift，切换选择
            if (!event.modifiers.contains(ModifierKey.shift)) {
              commandManager.executeCommand(
                ToggleSelectionCommand(elementId: elementId)
              );
            }
          }
          
          _lastPosition = event.position;
          _currentCommand = null;
        }
        break;
        
      case InputEventType.move:
        if (_lastPosition != null && _draggedElementIds != null) {
          final delta = event.position - _lastPosition!;
          
          // 如果是第一次移动，创建命令
          if (_currentCommand == null) {
            _currentCommand = MoveElementsCommand(
              elementIds: _draggedElementIds!,
              initialPositions: _draggedElementIds!.map((id) {
                final element = stateManager.elementState.getElementById(id)!;
                return MapEntry(id, element.bounds.topLeft);
              }).toMap(),
            );
          }
          
          // 更新命令中的当前位移
          _currentCommand!.updateDelta(delta);
          
          // 应用移动（不提交命令，只预览）
          _currentCommand!.previewExecute(stateManager);
          
          _lastPosition = event.position;
        }
        break;
        
      case InputEventType.up:
        if (_currentCommand != null) {
          // 提交命令
          commandManager.executeCommand(_currentCommand!);
          _currentCommand = null;
        }
        
        // 清理状态
        _lastPosition = null;
        _draggedElementIds = null;
        break;
    }
  }
}

// 新增的命令实现
class MoveElementsCommand implements Command {
  final Set<String> elementIds;
  final Map<String, Offset> initialPositions;
  Offset _currentDelta = Offset.zero;
  
  MoveElementsCommand({
    required this.elementIds,
    required this.initialPositions,
  });
  
  void updateDelta(Offset delta) {
    _currentDelta += delta;
  }
  
  // 用于实时预览
  void previewExecute(CanvasStateManager stateManager) {
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null) {
        final initialPos = initialPositions[id] ?? element.bounds.topLeft;
        final newPos = initialPos + _currentDelta;
        
        // 应用网格贴附
        final snappedPos = stateManager.gridState.isSnapEnabled
            ? stateManager.gridState.snapToGrid(newPos)
            : newPos;
        
        // 更新元素位置
        final updatedElement = element.copyWith(
          bounds: element.bounds.shift(snappedPos - element.bounds.topLeft),
        );
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 实际执行时使用预览的结果，不需要额外操作
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复原始位置
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null && initialPositions.containsKey(id)) {
        final initialPos = initialPositions[id]!;
        
        // 更新元素位置到初始状态
        final updatedElement = element.copyWith(
          bounds: element.bounds.shift(initialPos - element.bounds.topLeft),
        );
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
}
```

#### 4.2 旋转元素

**现有实现**:
- 跟踪旋转控制点拖动
- 计算旋转角度
- 更新元素旋转属性
- 通知UI更新

**重构影响**:
- **修改**: 旋转操作移至交互引擎，通过命令模式实现
- **删除**: 直接修改元素旋转的代码
- **新增**: `RotateElementsCommand`命令类和专用旋转控制点
- **保留**: 旋转角度计算逻辑

**调整方案**:
```dart
// 旧实现
void handleRotationDrag(String elementId, Offset center, Offset dragPoint) {
  final element = _getElementById(elementId);
  if (element == null) return;
  
  // 计算旋转角度
  final initialVector = element.rotationHandlePosition - element.center;
  final currentVector = dragPoint - center;
  final angle = _calculateAngle(initialVector, currentVector);
  
  // 更新旋转
  element.rotation = element.rotation + angle;
  
  notifyListeners();
}

// 新实现 - 交互引擎中
class RotationHandleInteractionHandler implements InteractionHandler {
  Offset? _rotationCenter;
  Offset? _lastHandlePosition;
  Set<String>? _rotatingElementIds;
  RotateElementsCommand? _currentCommand;
  
  @override
  bool canHandle(InputEvent event, InteractionState state) {
    // 检查是否点击了旋转控制点
    return state.activeControlPoint?.type == ControlPointType.rotation;
  }
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    switch (event.type) {
      case InputEventType.down:
        if (state.activeControlPoint?.type == ControlPointType.rotation) {
          // 获取相关元素的中心点
          _rotatingElementIds = state.activeControlPoint!.elementIds;
          _rotationCenter = _calculateRotationCenter(stateManager, _rotatingElementIds!);
          _lastHandlePosition = event.position;
          _currentCommand = null;
        }
        break;
        
      case InputEventType.move:
        if (_rotationCenter != null && _lastHandlePosition != null && _rotatingElementIds != null) {
          // 如果是第一次移动，创建命令
          if (_currentCommand == null) {
            _currentCommand = RotateElementsCommand(
              elementIds: _rotatingElementIds!,
              rotationCenter: _rotationCenter!,
              initialRotations: _rotatingElementIds!.map((id) {
                final element = stateManager.elementState.getElementById(id)!;
                return MapEntry(id, element.rotation);
              }).toMap(),
            );
          }
          
          // 计算旋转角度
          final initialVector = _lastHandlePosition! - _rotationCenter!;
          final currentVector = event.position - _rotationCenter!;
          final angle = _calculateAngle(initialVector, currentVector);
          
          // 更新命令中的当前旋转
          _currentCommand!.updateRotation(angle);
          
          // 应用旋转（不提交命令，只预览）
          _currentCommand!.previewExecute(stateManager);
          
          _lastHandlePosition = event.position;
        }
        break;
        
      case InputEventType.up:
        if (_currentCommand != null) {
          // 提交命令
          commandManager.executeCommand(_currentCommand!);
          _currentCommand = null;
        }
        
        // 清理状态
        _rotationCenter = null;
        _lastHandlePosition = null;
        _rotatingElementIds = null;
        break;
    }
  }
}

// 新增的命令实现
class RotateElementsCommand implements Command {
  final Set<String> elementIds;
  final Offset rotationCenter;
  final Map<String, double> initialRotations;
  double _additionalRotation = 0.0;
  
  RotateElementsCommand({
    required this.elementIds,
    required this.rotationCenter,
    required this.initialRotations,
  });
  
  void updateRotation(double angle) {
    _additionalRotation += angle;
  }
  
  // 用于实时预览
  void previewExecute(CanvasStateManager stateManager) {
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null) {
        final initialRotation = initialRotations[id] ?? element.rotation;
        final newRotation = initialRotation + _additionalRotation;
        
        // 更新元素旋转
        final updatedElement = element.copyWith(
          rotation: newRotation,
        );
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 实际执行时使用预览的结果，不需要额外操作
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复原始旋转
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null && initialRotations.containsKey(id)) {
        final initialRotation = initialRotations[id]!;
        
        // 更新元素旋转到初始状态
        final updatedElement = element.copyWith(
          rotation: initialRotation,
        );
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
}
```

#### 4.3 缩放元素

**现有实现**:
- 跟踪缩放控制点拖动
- 计算缩放因子
- 更新元素尺寸
- 可能保持宽高比
- 通知UI更新

**重构影响**:
- **修改**: 缩放操作移至交互引擎，通过命令模式实现
- **删除**: 直接修改元素尺寸的代码
- **新增**: `ResizeElementsCommand`命令类和专用缩放控制点
- **保留**: 缩放计算逻辑和宽高比维护算法

**调整方案**:
```dart
// 旧实现
void handleResizeDrag(String elementId, ResizeHandle handle, Offset delta, bool maintainAspectRatio) {
  final element = _getElementById(elementId);
  if (element == null) return;
  
  // 获取原始尺寸
  Rect originalBounds = element.bounds;
  
  // 根据不同的控制柄计算新的边界
  Rect newBounds = _calculateNewBounds(originalBounds, handle, delta, maintainAspectRatio);
  
  // 更新元素边界
  element.bounds = newBounds;
  
  notifyListeners();
}

// 新实现 - 交互引擎中
class ResizeHandleInteractionHandler implements InteractionHandler {
  Offset? _initialHandlePosition;
  Set<String>? _resizingElementIds;
  ControlPointType? _activeHandleType;
  ResizeElementsCommand? _currentCommand;
  
  @override
  bool canHandle(InputEvent event, InteractionState state) {
    // 检查是否点击了缩放控制点
    return state.activeControlPoint?.type.isResizeHandle ?? false;
  }
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    switch (event.type) {
      case InputEventType.down:
        if (state.activeControlPoint?.type.isResizeHandle ?? false) {
          _resizingElementIds = state.activeControlPoint!.elementIds;
          _activeHandleType = state.activeControlPoint!.type;
          _initialHandlePosition = event.position;
          _currentCommand = null;
        }
        break;
        
      case InputEventType.move:
        if (_initialHandlePosition != null && _resizingElementIds != null && _activeHandleType != null) {
          final delta = event.position - _initialHandlePosition!;
          
          // 如果是第一次移动，创建命令
          if (_currentCommand == null) {
            _currentCommand = ResizeElementsCommand(
              elementIds: _resizingElementIds!,
              handleType: _activeHandleType!,
              initialBounds: _resizingElementIds!.map((id) {
                final element = stateManager.elementState.getElementById(id)!;
                return MapEntry(id, element.bounds);
              }).toMap(),
              maintainAspectRatio: event.modifiers.contains(ModifierKey.shift),
            );
          }
          
          // 更新命令中的当前缩放
          _currentCommand!.updateDelta(delta);
          
          // 应用缩放（不提交命令，只预览）
          _currentCommand!.previewExecute(stateManager);
        }
        break;
        
      case InputEventType.up:
        if (_currentCommand != null) {
          // 提交命令
          commandManager.executeCommand(_currentCommand!);
          _currentCommand = null;
        }
        
        // 清理状态
        _initialHandlePosition = null;
        _resizingElementIds = null;
        _activeHandleType = null;
        break;
    }
  }
}

// 新增的命令实现
class ResizeElementsCommand implements Command {
  final Set<String> elementIds;
  final ControlPointType handleType;
  final Map<String, Rect> initialBounds;
  final bool maintainAspectRatio;
  Offset _currentDelta = Offset.zero;
  
  ResizeElementsCommand({
    required this.elementIds,
    required this.handleType,
    required this.initialBounds,
    this.maintainAspectRatio = false,
  });
  
  void updateDelta(Offset delta) {
    _currentDelta = delta;
  }
  
  // 用于实时预览
  void previewExecute(CanvasStateManager stateManager) {
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null && initialBounds.containsKey(id)) {
        final originalBounds = initialBounds[id]!;
        
        // 根据控制点类型和增量计算新边界
        final newBounds = _calculateNewBounds(
          originalBounds,
          handleType,
          _currentDelta,
          maintainAspectRatio,
        );
        
        // 应用网格贴附
        final snappedBounds = stateManager.gridState.isSnapEnabled
            ? stateManager.gridState.snapRectToGrid(newBounds)
            : newBounds;
        
        // 更新元素边界
        final updatedElement = element.copyWith(bounds: snappedBounds);
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 实际执行时使用预览的结果，不需要额外操作
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复原始边界
    for (final id in elementIds) {
      final element = stateManager.elementState.getElementById(id);
      if (element != null && initialBounds.containsKey(id)) {
        final originalBounds = initialBounds[id]!;
        
        // 更新元素边界到初始状态
        final updatedElement = element.copyWith(bounds: originalBounds);
        
        stateManager.elementState.updateElement(updatedElement);
      }
    }
  }
}
```
