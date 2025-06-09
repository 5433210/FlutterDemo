# 撤销操作调试指南

## 问题症状
- 单选元素平移、resize后undo没有恢复元素
- 单选元素rotate后undo恢复了元素，但控制点box没有恢复  
- 多选平移后undo能够正常恢复

## 调试步骤

### 1. 验证撤销操作是否被创建
在浏览器开发者工具的Console中查看日志，搜索以下关键词：
- `创建元素调整大小操作`
- `创建元素平移操作` 
- `创建元素旋转操作`
- `批量更新元素最终位置`

### 2. 验证撤销操作是否被执行
查看日志中的以下关键词：
- `执行元素移动操作`
- `撤销元素移动操作`
- `执行元素调整大小操作`
- `撤销元素调整大小操作`

### 3. 验证UI更新是否被触发
查看以下方法是否被调用：
- `notifyListeners()` 调用
- `_updateElementInCurrentPage` 执行

### 4. 操作路径分析

#### 单选元素平移路径
可能的路径：
1. **控制点拖拽路径**: `CanvasControlPointHandlers` → `createElementTranslationOperation`
2. **普通拖拽路径**: `SmartCanvasGestureHandler` → `batchUpdateElementProperties` + `createElementTranslationOperation`

#### 单选元素resize路径  
1. **控制点路径**: `CanvasControlPointHandlers` → `createElementResizeOperation`

#### 单选元素rotate路径
1. **控制点路径**: `CanvasControlPointHandlers` → `createElementRotationOperation`

#### 多选平移路径
1. **拖拽路径**: `SmartCanvasGestureHandler` → `batchUpdateElementProperties` + `createElementTranslationOperation`

### 5. 关键检查点

#### 检查点1: 撤销操作创建
- 在操作结束后，检查 `UndoRedoManager` 的撤销栈是否增加了操作
- 确认操作类型是否正确

#### 检查点2: 撤销操作执行
- 点击undo按钮后，检查对应的撤销操作是否被调用
- 确认 `updateElement` 函数是否被执行

#### 检查点3: 数据更新
- 确认元素数据在撤销后是否正确更新
- 检查 `state.selectedElement` 是否正确更新

#### 检查点4: UI刷新
- 确认 `notifyListeners()` 是否被调用
- 检查UI是否正确重新渲染

### 6. 可能的问题点

#### 问题1: 撤销操作未创建
- 检查对应的 `create*Operation` 方法是否被调用
- 确认操作路径是否正确

#### 问题2: 撤销操作创建了但未执行
- 检查 `UndoRedoManager.undo()` 是否被调用
- 确认撤销栈中是否有对应操作

#### 问题3: 撤销操作执行了但数据未更新
- 检查 `updateElement` 函数的实现
- 确认 `_updateElementInCurrentPage` 是否正确

#### 问题4: 数据更新了但UI未刷新
- 检查 `notifyListeners()` 调用
- 确认控制点组件是否正确更新

### 7. 快速验证方法

#### 方法1: 添加断点
在以下方法中添加断点：
- `UndoRedoManager.addOperation()`
- `UndoRedoManager.undo()`
- `_updateElementInCurrentPage()`
- `createElementResizeOperation()`
- `createElementTranslationOperation()`

#### 方法2: 添加日志
在关键方法中添加 `debugPrint` 日志：
```dart
debugPrint('🔧 DEBUG: 撤销操作创建 - ${operation.description}');
debugPrint('🔧 DEBUG: 撤销操作执行 - ${elementId}');
debugPrint('🔧 DEBUG: 元素数据更新 - ${properties}');
debugPrint('🔧 DEBUG: UI刷新调用');
```

#### 方法3: 检查撤销栈
在操作后添加日志查看撤销栈状态：
```dart
debugPrint('🔧 DEBUG: 撤销栈大小 - ${undoRedoManager.canUndo}');
debugPrint('🔧 DEBUG: 重做栈大小 - ${undoRedoManager.canRedo}');
```

### 8. 预期的正确流程

#### 单选元素操作流程
1. 用户开始操作 → 保存原始状态
2. 用户操作过程 → 实时预览
3. 用户结束操作 → 应用最终状态 + 创建撤销操作
4. 用户点击undo → 执行撤销操作 → 恢复原始状态 + 刷新UI

#### 多选元素操作流程  
1. 用户开始操作 → 保存所有元素原始状态
2. 用户操作过程 → 批量实时预览
3. 用户结束操作 → 批量应用最终状态 + 创建批量撤销操作
4. 用户点击undo → 执行批量撤销操作 → 恢复所有元素原始状态 + 刷新UI

## 结论模板

基于调试结果，问题出现在：
- [ ] 撤销操作未被创建
- [ ] 撤销操作创建了但未被执行  
- [ ] 撤销操作执行了但数据未正确更新
- [ ] 数据更新了但UI未刷新
- [ ] 控制点组件未正确响应元素变化

具体修复方案：
1. [具体问题描述]
2. [修复步骤]
3. [验证方法] 