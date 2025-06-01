# 画布功能重构影响分析

## 概述

本文档从功能视角分析Canvas重构对现有画布操作的影响，包括元素操作和画布操作两大类别。对每项功能，我们分析其在新架构下的实现方式、代码调整需求和迁移策略。

## 一、元素操作功能影响分析

### 1. 基本操作

#### 1.1 新增元素

**现有实现**:
- 直接修改元素集合
- 回调通知UI更新
- 缺乏撤销/重做支持

**重构影响**:
- **修改**: 所有元素添加操作改为通过命令模式实现
- **删除**: 直接操作集合的代码
- **新增**: `AddElementCommand`类实现添加逻辑
- **保留**: 元素数据结构设计，但转换为不可变模式

**调整方案**:
```dart
// 旧实现
void addElement(CanvasElement element) {
  _elements.add(element);
  notifyListeners();
}

// 新实现
void addElement(ElementData elementData) {
  final command = AddElementCommand(elementData: elementData);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class AddElementCommand implements Command {
  final ElementData elementData;
  
  AddElementCommand({required this.elementData});
  
  @override
  void execute(CanvasStateManager stateManager) {
    stateManager.elementState.addElement(elementData);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    stateManager.elementState.removeElement(elementData.id);
  }
}
```

#### 1.2 复制元素

**现有实现**:
- 深拷贝元素对象
- 修改ID和位置
- 直接添加到集合

**重构影响**:
- **修改**: 复制逻辑改为创建新的不可变数据对象
- **删除**: 可变对象的复制方法
- **新增**: `CopyElementCommand`和专用复制服务
- **保留**: 元素属性复制逻辑

**调整方案**:
```dart
// 旧实现
void copyElement(String elementId) {
  final element = _getElementById(elementId);
  if (element != null) {
    final copy = element.copy();
    copy.id = _generateUniqueId();
    copy.position = _calculateNewPosition(element.position);
    _elements.add(copy);
    notifyListeners();
  }
}

// 新实现
void copyElement(String elementId) {
  final command = CopyElementCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class CopyElementCommand implements Command {
  final String elementId;
  String? newElementId;
  
  CopyElementCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element != null) {
      newElementId = generateUniqueId();
      final copyData = element.copyWith(
        id: newElementId!,
        bounds: _calculateNewBounds(element.bounds),
      );
      stateManager.elementState.addElement(copyData);
    }
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (newElementId != null) {
      stateManager.elementState.removeElement(newElementId!);
    }
  }
}
```

#### 1.3 粘贴元素

**现有实现**:
- 从剪贴板获取数据
- 转换为元素对象
- 直接添加到集合

**重构影响**:
- **修改**: 粘贴过程改为命令模式
- **删除**: 直接操作元素集合的代码
- **新增**: `PasteElementCommand`和剪贴板服务
- **保留**: 剪贴板数据格式解析逻辑

**调整方案**:
```dart
// 旧实现
Future<void> pasteFromClipboard() async {
  final clipboardData = await _getClipboardData();
  if (clipboardData != null) {
    final element = _convertToElement(clipboardData);
    _elements.add(element);
    notifyListeners();
  }
}

// 新实现
Future<void> pasteFromClipboard() async {
  final clipboardData = await clipboardService.getClipboardData();
  if (clipboardData != null) {
    final command = PasteElementCommand(clipboardData: clipboardData);
    commandManager.executeCommand(command);
  }
}

// 新增的命令和服务
class ClipboardService {
  Future<ClipboardData?> getClipboardData() async {
    // 实现剪贴板访问逻辑
  }
}

class PasteElementCommand implements Command {
  final ClipboardData clipboardData;
  String? newElementId;
  
  PasteElementCommand({required this.clipboardData});
  
  @override
  Future<void> execute(CanvasStateManager stateManager) async {
    final elementData = await _convertToElementData(clipboardData);
    if (elementData != null) {
      newElementId = elementData.id;
      stateManager.elementState.addElement(elementData);
    }
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (newElementId != null) {
      stateManager.elementState.removeElement(newElementId!);
    }
  }
}
```

#### 1.4 删除元素

**现有实现**:
- 直接从集合中移除
- 通知UI更新
- 可能处理相关依赖关系

**重构影响**:
- **修改**: 删除操作改为命令模式
- **删除**: 直接操作集合的代码
- **新增**: `DeleteElementCommand`命令类
- **保留**: 依赖关系处理逻辑

**调整方案**:
```dart
// 旧实现
void deleteElement(String elementId) {
  _elements.removeWhere((e) => e.id == elementId);
  notifyListeners();
}

// 新实现
void deleteElement(String elementId) {
  final command = DeleteElementCommand(elementId: elementId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class DeleteElementCommand implements Command {
  final String elementId;
  ElementData? deletedElement;
  
  DeleteElementCommand({required this.elementId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    deletedElement = stateManager.elementState.getElementById(elementId);
    if (deletedElement != null) {
      stateManager.elementState.removeElement(elementId);
    }
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (deletedElement != null) {
      stateManager.elementState.addElement(deletedElement!);
    }
  }
}
```

### 2. 组合操作

#### 2.1 组合元素

**现有实现**:
- 创建组合元素
- 添加子元素引用
- 从主集合中移除子元素

**重构影响**:
- **修改**: 组合过程改为命令模式
- **删除**: 直接操作元素层次结构的代码
- **新增**: `GroupElementsCommand`命令类和组合元素数据模型
- **保留**: 组合元素边界计算逻辑

**调整方案**:
```dart
// 旧实现
void groupElements(List<String> elementIds) {
  if (elementIds.length < 2) return;
  
  final elements = elementIds.map((id) => _getElementById(id)).whereType<CanvasElement>().toList();
  if (elements.isEmpty) return;
  
  final groupElement = GroupElement();
  groupElement.id = _generateUniqueId();
  groupElement.addChildren(elements);
  
  // 从主集合中移除子元素
  _elements.removeWhere((e) => elementIds.contains(e.id));
  _elements.add(groupElement);
  notifyListeners();
}

// 新实现
void groupElements(List<String> elementIds) {
  if (elementIds.length < 2) return;
  
  final command = GroupElementsCommand(elementIds: elementIds);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class GroupElementsCommand implements Command {
  final List<String> elementIds;
  String? groupId;
  List<ElementData>? originalElements;
  
  GroupElementsCommand({required this.elementIds});
  
  @override
  void execute(CanvasStateManager stateManager) {
    if (elementIds.length < 2) return;
    
    // 获取元素数据
    final elements = elementIds
        .map((id) => stateManager.elementState.getElementById(id))
        .whereType<ElementData>()
        .toList();
    
    if (elements.isEmpty) return;
    
    // 保存原始元素用于撤销
    originalElements = List.from(elements);
    
    // 创建组合元素数据
    groupId = generateUniqueId();
    final bounds = _calculateGroupBounds(elements);
    
    final groupData = GroupElementData(
      id: groupId!,
      bounds: bounds,
      childrenIds: elementIds,
    );
    
    // 从状态中移除子元素
    for (final id in elementIds) {
      stateManager.elementState.removeElement(id);
    }
    
    // 添加组合元素
    stateManager.elementState.addElement(groupData);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (groupId != null && originalElements != null) {
      // 移除组合元素
      stateManager.elementState.removeElement(groupId!);
      
      // 恢复原始元素
      for (final element in originalElements!) {
        stateManager.elementState.addElement(element);
      }
    }
  }
}
```

#### 2.2 解组合

**现有实现**:
- 获取组合元素
- 提取子元素
- 添加子元素到主集合
- 移除组合元素

**重构影响**:
- **修改**: 解组合过程改为命令模式
- **删除**: 直接操作元素集合的代码
- **新增**: `UngroupElementCommand`命令类
- **保留**: 子元素位置计算逻辑

**调整方案**:
```dart
// 旧实现
void ungroupElement(String groupId) {
  final groupElement = _getElementById(groupId);
  if (groupElement is! GroupElement) return;
  
  // 将子元素添加到主集合
  for (final child in groupElement.children) {
    _elements.add(child);
  }
  
  // 移除组合元素
  _elements.removeWhere((e) => e.id == groupId);
  notifyListeners();
}

// 新实现
void ungroupElement(String groupId) {
  final command = UngroupElementCommand(groupId: groupId);
  commandManager.executeCommand(command);
}

// 新增的命令实现
class UngroupElementCommand implements Command {
  final String groupId;
  GroupElementData? groupData;
  
  UngroupElementCommand({required this.groupId});
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(groupId);
    if (element is! GroupElementData) return;
    
    // 保存组合元素以便撤销
    groupData = element;
    
    // 获取子元素数据
    final childrenData = [];
    for (final childId in element.childrenIds) {
      final childData = stateManager.elementRepository.getElement(childId);
      if (childData != null) {
        childrenData.add(childData);
      }
    }
    
    // 添加子元素到状态
    for (final childData in childrenData) {
      stateManager.elementState.addElement(childData);
    }
    
    // 移除组合元素
    stateManager.elementState.removeElement(groupId);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (groupData == null) return;
    
    // 移除子元素
    for (final childId in groupData!.childrenIds) {
      stateManager.elementState.removeElement(childId);
    }
    
    // 恢复组合元素
    stateManager.elementState.addElement(groupData!);
  }
}
```

### 3. 选择操作

#### 3.1 框选元素

**现有实现**:
- 跟踪拖动开始和结束位置
- 计算选择矩形
- 测试元素与选择区域的交叉
- 更新选择状态

**重构影响**:
- **修改**: 选择逻辑移至交互引擎
- **删除**: 选择状态直接修改代码
- **新增**: 专用选择管理器和选择命令
- **保留**: 碰撞检测算法

**调整方案**:
```dart
// 旧实现
void handleDragToSelect(Offset start, Offset end) {
  final selectionRect = Rect.fromPoints(start, end);
  
  _selectedElements.clear();
  for (final element in _elements) {
    if (_elementIntersectsRect(element, selectionRect)) {
      _selectedElements.add(element.id);
    }
  }
  
  notifyListeners();
}

// 新实现 - 交互引擎中
class RectangleSelectionTool implements InteractionTool {
  Offset? _startPosition;
  Rect? _currentSelectionRect;
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    switch (event.type) {
      case InputEventType.down:
        _startPosition = event.position;
        // 清除现有选择
        stateManager.selectionState.clearSelection();
        break;
        
      case InputEventType.move:
        if (_startPosition != null) {
          _currentSelectionRect = Rect.fromPoints(_startPosition!, event.position);
          // 更新可视反馈
          stateManager.interactionState.updateOverlay(
            SelectionRectOverlay(_currentSelectionRect!)
          );
        }
        break;
        
      case InputEventType.up:
        if (_startPosition != null && _currentSelectionRect != null) {
          // 创建并执行选择命令
          final command = RectangleSelectCommand(
            selectionRect: _currentSelectionRect!,
            appendToSelection: event.modifiers.contains(ModifierKey.shift)
          );
          commandManager.executeCommand(command);
          
          // 清理状态
          _startPosition = null;
          _currentSelectionRect = null;
          stateManager.interactionState.clearOverlay();
        }
        break;
    }
  }
}

// 新增的命令实现
class RectangleSelectCommand implements Command {
  final Rect selectionRect;
  final bool appendToSelection;
  Set<String>? previousSelection;
  
  RectangleSelectCommand({
    required this.selectionRect,
    this.appendToSelection = false,
  });
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存之前的选择状态
    previousSelection = Set.from(stateManager.selectionState.selectedElementIds);
    
    // 查找与选择矩形相交的元素
    final elementsInRect = stateManager.hitTestManager.hitTestRect(selectionRect);
    
    if (appendToSelection) {
      // 追加到现有选择
      stateManager.selectionState.addToSelection(elementsInRect);
    } else {
      // 替换现有选择
      stateManager.selectionState.setSelection(elementsInRect);
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

#### 3.2 全选

**现有实现**:
- 将所有元素ID添加到选择集合
- 通知UI更新

**重构影响**:
- **修改**: 全选操作改为命令模式
- **删除**: 直接修改选择状态的代码
- **新增**: `SelectAllCommand`命令类
- **保留**: 元素过滤逻辑（如果有）

**调整方案**:
```dart
// 旧实现
void selectAll() {
  _selectedElements.clear();
  for (final element in _elements) {
    _selectedElements.add(element.id);
  }
  notifyListeners();
}

// 新实现
void selectAll() {
  final command = SelectAllCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class SelectAllCommand implements Command {
  Set<String>? previousSelection;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存之前的选择状态
    previousSelection = Set.from(stateManager.selectionState.selectedElementIds);
    
    // 获取所有元素ID
    final allElementIds = stateManager.elementState.elements.keys.toSet();
    
    // 设置新的选择状态
    stateManager.selectionState.setSelection(allElementIds);
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
