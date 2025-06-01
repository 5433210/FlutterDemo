### 5. 层级操作

#### 5.1 上移元素

**现有实现**:
- 在元素集合中调整元素位置
- 可能处理Z索引值
- 通知UI更新

**重构影响**:
- **修改**: 层级操作改为命令模式
- **删除**: 直接操作元素集合顺序的代码
- **新增**: `MoveElementUpCommand`命令类
- **保留**: 层级计算逻辑

**调整方案**:
```dart
// 旧实现
void moveElementUp(String elementId) {
  final index = _elements.indexWhere((e) => e.id == elementId);
  if (index < 0 || index >= _elements.length - 1) return;
  
  // 交换元素位置
  final temp = _elements[index];
  _elements[index] = _elements[index + 1];
  _elements[index + 1] = temp;
  
  notifyListeners();
}

// 新实现
void moveElementUp(String elementId) {
  final command = MoveElementUpCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class MoveElementUpCommand implements Command {
  final String elementId;
  int? _originalZIndex;
  int? _newZIndex;
  
  MoveElementUpCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存原始Z索引
    _originalZIndex = element.zIndex;
    
    // 获取当前层级之上的下一个元素
    final nextElement = stateManager.elementState.getNextElementByZIndex(_originalZIndex!);
    if (nextElement == null) return;
    
    // 保存新的Z索引
    _newZIndex = nextElement.zIndex;
    
    // 交换两个元素的Z索引
    stateManager.elementState.updateElement(element.copyWith(zIndex: _newZIndex!));
    stateManager.elementState.updateElement(nextElement.copyWith(zIndex: _originalZIndex!));
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_originalZIndex == null || _newZIndex == null) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 获取具有新Z索引的元素
    final swappedElement = stateManager.elementState.getElementByZIndex(_originalZIndex!);
    if (swappedElement == null) return;
    
    // 恢复原始Z索引
    stateManager.elementState.updateElement(element.copyWith(zIndex: _originalZIndex!));
    stateManager.elementState.updateElement(swappedElement.copyWith(zIndex: _newZIndex!));
  }
}
```

#### 5.2 下移元素

**现有实现**:
- 在元素集合中调整元素位置
- 可能处理Z索引值
- 通知UI更新

**重构影响**:
- **修改**: 层级操作改为命令模式
- **删除**: 直接操作元素集合顺序的代码
- **新增**: `MoveElementDownCommand`命令类
- **保留**: 层级计算逻辑

**调整方案**:
```dart
// 旧实现
void moveElementDown(String elementId) {
  final index = _elements.indexWhere((e) => e.id == elementId);
  if (index <= 0) return;
  
  // 交换元素位置
  final temp = _elements[index];
  _elements[index] = _elements[index - 1];
  _elements[index - 1] = temp;
  
  notifyListeners();
}

// 新实现
void moveElementDown(String elementId) {
  final command = MoveElementDownCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class MoveElementDownCommand implements Command {
  final String elementId;
  int? _originalZIndex;
  int? _newZIndex;
  
  MoveElementDownCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存原始Z索引
    _originalZIndex = element.zIndex;
    
    // 获取当前层级之下的下一个元素
    final prevElement = stateManager.elementState.getPreviousElementByZIndex(_originalZIndex!);
    if (prevElement == null) return;
    
    // 保存新的Z索引
    _newZIndex = prevElement.zIndex;
    
    // 交换两个元素的Z索引
    stateManager.elementState.updateElement(element.copyWith(zIndex: _newZIndex!));
    stateManager.elementState.updateElement(prevElement.copyWith(zIndex: _originalZIndex!));
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_originalZIndex == null || _newZIndex == null) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 获取具有新Z索引的元素
    final swappedElement = stateManager.elementState.getElementByZIndex(_originalZIndex!);
    if (swappedElement == null) return;
    
    // 恢复原始Z索引
    stateManager.elementState.updateElement(element.copyWith(zIndex: _originalZIndex!));
    stateManager.elementState.updateElement(swappedElement.copyWith(zIndex: _newZIndex!));
  }
}
```

#### 5.3 移到最顶层

**现有实现**:
- 将元素移至集合末尾
- 可能更新所有元素的Z索引
- 通知UI更新

**重构影响**:
- **修改**: 层级操作改为命令模式
- **删除**: 直接操作元素集合顺序的代码
- **新增**: `BringToFrontCommand`命令类
- **保留**: 层级计算逻辑

**调整方案**:
```dart
// 旧实现
void bringToFront(String elementId) {
  final index = _elements.indexWhere((e) => e.id == elementId);
  if (index < 0) return;
  
  // 移除元素
  final element = _elements.removeAt(index);
  
  // 添加到末尾（最上层）
  _elements.add(element);
  
  notifyListeners();
}

// 新实现
void bringToFront(String elementId) {
  final command = BringToFrontCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class BringToFrontCommand implements Command {
  final String elementId;
  int? _originalZIndex;
  
  BringToFrontCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存原始Z索引
    _originalZIndex = element.zIndex;
    
    // 获取最高Z索引值
    final highestZIndex = stateManager.elementState.getHighestZIndex();
    
    // 更新元素的Z索引为最高值 + 1
    stateManager.elementState.updateElement(
      element.copyWith(zIndex: highestZIndex + 1)
    );
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_originalZIndex == null) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 恢复原始Z索引
    stateManager.elementState.updateElement(
      element.copyWith(zIndex: _originalZIndex!)
    );
  }
}
```

#### 5.4 移到最底层

**现有实现**:
- 将元素移至集合开头
- 可能更新所有元素的Z索引
- 通知UI更新

**重构影响**:
- **修改**: 层级操作改为命令模式
- **删除**: 直接操作元素集合顺序的代码
- **新增**: `SendToBackCommand`命令类
- **保留**: 层级计算逻辑

**调整方案**:
```dart
// 旧实现
void sendToBack(String elementId) {
  final index = _elements.indexWhere((e) => e.id == elementId);
  if (index < 0) return;
  
  // 移除元素
  final element = _elements.removeAt(index);
  
  // 添加到开头（最下层）
  _elements.insert(0, element);
  
  notifyListeners();
}

// 新实现
void sendToBack(String elementId) {
  final command = SendToBackCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class SendToBackCommand implements Command {
  final String elementId;
  int? _originalZIndex;
  
  SendToBackCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存原始Z索引
    _originalZIndex = element.zIndex;
    
    // 获取最低Z索引值
    final lowestZIndex = stateManager.elementState.getLowestZIndex();
    
    // 更新元素的Z索引为最低值 - 1
    stateManager.elementState.updateElement(
      element.copyWith(zIndex: lowestZIndex - 1)
    );
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_originalZIndex == null) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 恢复原始Z索引
    stateManager.elementState.updateElement(
      element.copyWith(zIndex: _originalZIndex!)
    );
  }
}
```

### 6. 辅助功能

#### 6.1 网格显示/隐藏

**现有实现**:
- 更新网格显示状态标志
- 通知UI更新

**重构影响**:
- **修改**: 网格显示操作改为命令模式
- **删除**: 直接修改网格状态的代码
- **新增**: `ToggleGridVisibilityCommand`命令类和专用网格状态管理器
- **保留**: 网格渲染逻辑

**调整方案**:
```dart
// 旧实现
void toggleGridVisibility() {
  _gridVisible = !_gridVisible;
  notifyListeners();
}

// 新实现
void toggleGridVisibility() {
  final command = ToggleGridVisibilityCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class ToggleGridVisibilityCommand implements Command {
  bool? _previousVisibility;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存原始可见性状态
    _previousVisibility = stateManager.gridState.isVisible;
    
    // 切换网格可见性
    stateManager.gridState.setVisible(!_previousVisibility!);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_previousVisibility != null) {
      // 恢复原始可见性状态
      stateManager.gridState.setVisible(_previousVisibility!);
    }
  }
}

// 新增的网格状态管理器
class GridState extends ChangeNotifier {
  bool _isVisible = false;
  bool _isSnapEnabled = false;
  double _gridSize = 10.0;
  
  bool get isVisible => _isVisible;
  bool get isSnapEnabled => _isSnapEnabled;
  double get gridSize => _gridSize;
  
  void setVisible(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      notifyListeners();
    }
  }
  
  void setSnapEnabled(bool enabled) {
    if (_isSnapEnabled != enabled) {
      _isSnapEnabled = enabled;
      notifyListeners();
    }
  }
  
  void setGridSize(double size) {
    if (_gridSize != size) {
      _gridSize = size;
      notifyListeners();
    }
  }
  
  // 网格贴附工具方法
  Offset snapToGrid(Offset position) {
    if (!_isSnapEnabled) return position;
    
    return Offset(
      (_position.dx / _gridSize).round() * _gridSize,
      (_position.dy / _gridSize).round() * _gridSize,
    );
  }
  
  Rect snapRectToGrid(Rect rect) {
    if (!_isSnapEnabled) return rect;
    
    final topLeft = snapToGrid(rect.topLeft);
    final bottomRight = snapToGrid(rect.bottomRight);
    
    return Rect.fromPoints(topLeft, bottomRight);
  }
}
```

#### 6.2 网格贴附开启/关闭

**现有实现**:
- 更新网格贴附状态标志
- 通知UI更新

**重构影响**:
- **修改**: 网格贴附操作改为命令模式
- **删除**: 直接修改网格贴附状态的代码
- **新增**: `ToggleGridSnapCommand`命令类
- **保留**: 网格贴附算法

**调整方案**:
```dart
// 旧实现
void toggleGridSnap() {
  _gridSnapEnabled = !_gridSnapEnabled;
  notifyListeners();
}

// 新实现
void toggleGridSnap() {
  final command = ToggleGridSnapCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class ToggleGridSnapCommand implements Command {
  bool? _previousSnapState;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存原始贴附状态
    _previousSnapState = stateManager.gridState.isSnapEnabled;
    
    // 切换网格贴附
    stateManager.gridState.setSnapEnabled(!_previousSnapState!);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_previousSnapState != null) {
      // 恢复原始贴附状态
      stateManager.gridState.setSnapEnabled(_previousSnapState!);
    }
  }
}
```

#### 6.3 格式刷复制

**现有实现**:
- 从选中元素获取样式属性
- 存储到格式刷状态
- 可能更新UI状态

**重构影响**:
- **修改**: 格式刷操作移至专用服务
- **删除**: 内联格式刷状态管理代码
- **新增**: `FormatPainterService`类和相关命令
- **保留**: 样式属性提取逻辑

**调整方案**:
```dart
// 旧实现
void copyFormat(String elementId) {
  final element = _getElementById(elementId);
  if (element == null) return;
  
  _formatPainterStyles = element.getStyles();
  _formatPainterActive = true;
  
  notifyListeners();
}

// 新实现
void copyFormat(String elementId) {
  final command = CopyFormatCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令和服务
class FormatPainterService {
  ElementStyles? _copiedStyles;
  bool _isActive = false;
  
  ElementStyles? get copiedStyles => _copiedStyles;
  bool get isActive => _isActive;
  
  void copyStyles(ElementStyles styles) {
    _copiedStyles = styles;
    _isActive = true;
    notifyListeners();
  }
  
  void applyStyles(ElementData element) {
    if (_copiedStyles == null) return null;
    
    return element.copyWith(styles: _copiedStyles);
  }
  
  void deactivate() {
    _isActive = false;
    notifyListeners();
  }
  
  void clear() {
    _copiedStyles = null;
    _isActive = false;
    notifyListeners();
  }
}

class CopyFormatCommand implements Command {
  final String elementId;
  ElementStyles? _previousStyles;
  bool _previousActiveState;
  
  CopyFormatCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存之前的格式刷状态
    _previousStyles = stateManager.formatPainterService.copiedStyles;
    _previousActiveState = stateManager.formatPainterService.isActive;
    
    // 复制样式
    stateManager.formatPainterService.copyStyles(element.styles);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复之前的格式刷状态
    if (_previousStyles != null) {
      stateManager.formatPainterService.copyStyles(_previousStyles!);
    } else {
      stateManager.formatPainterService.clear();
    }
    
    if (!_previousActiveState) {
      stateManager.formatPainterService.deactivate();
    }
  }
}
```

#### 6.4 格式刷应用

**现有实现**:
- 检查格式刷状态
- 应用存储的样式到目标元素
- 可能重置格式刷状态
- 通知UI更新

**重构影响**:
- **修改**: 应用格式刷操作改为命令模式
- **删除**: 内联格式应用代码
- **新增**: `ApplyFormatCommand`命令类
- **保留**: 样式应用逻辑

**调整方案**:
```dart
// 旧实现
void applyFormat(String elementId) {
  if (!_formatPainterActive || _formatPainterStyles == null) return;
  
  final element = _getElementById(elementId);
  if (element == null) return;
  
  // 应用样式
  element.applyStyles(_formatPainterStyles!);
  
  // 重置格式刷状态
  _formatPainterActive = false;
  
  notifyListeners();
}

// 新实现
void applyFormat(String elementId) {
  if (!stateManager.formatPainterService.isActive) return;
  
  final command = ApplyFormatCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class ApplyFormatCommand implements Command {
  final String elementId;
  ElementStyles? _previousStyles;
  
  ApplyFormatCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    if (!stateManager.formatPainterService.isActive) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 保存原始样式
    _previousStyles = element.styles;
    
    // 应用复制的样式
    final updatedElement = stateManager.formatPainterService.applyStyles(element);
    if (updatedElement != null) {
      stateManager.elementState.updateElement(updatedElement);
    }
    
    // 重置格式刷状态
    stateManager.formatPainterService.deactivate();
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_previousStyles == null) return;
    
    final element = stateManager.elementState.getElementById(elementId);
    if (element == null) return;
    
    // 恢复原始样式
    final restoredElement = element.copyWith(styles: _previousStyles);
    stateManager.elementState.updateElement(restoredElement);
  }
}
```
