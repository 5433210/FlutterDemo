# 移动端手势检测器冲突问题修复

## 问题描述

移动端出现了手势检测器冲突错误：
```
Incorrect GestureDetector arguments.
Having both a pan gesture recognizer and a scale gesture recognizer is
redundant; scale is a superset of pan.
Just use the scale gesture recognizer.
```

## 问题原因

在 `MobileImageView` 的 `_buildMobileGestureDetector` 方法中，同时使用了：
- `onScaleStart/Update/End` (缩放手势)
- `onPanStart/Update/End` (平移手势)

这两种手势是冲突的，因为 Scale 手势已经包含了 Pan 手势的所有功能。Flutter 不允许在同一个 GestureDetector 中同时使用这两种手势。

## 解决方案

### 1. 统一使用 Scale 手势
移除 Pan 手势处理器，只保留 Scale 手势处理器：
```dart
Widget _buildMobileGestureDetector({required Widget child}) {
  return GestureDetector(
    // 基础手势
    onTapUp: _handleTapUp,
    onLongPressStart: _handleLongPressStart,
    
    // 统一使用Scale手势处理单指和双指操作
    // Scale手势可以同时处理单指平移和双指缩放
    onScaleStart: _handleScaleStart,
    onScaleUpdate: _handleScaleUpdate,
    onScaleEnd: _handleScaleEnd,
    
    child: child,
  );
}
```

### 2. 重构手势处理逻辑

#### Scale Start 处理
- 根据 `details.pointerCount` 判断是单指还是双指操作
- 单指操作：检查点击位置，决定是选区选择还是准备平移/框选
- 双指操作：准备缩放和平移

#### Scale Update 处理
- 双指操作(`pointerCount > 1`)：处理缩放和平移
- 单指操作：根据工具模式处理平移或框选

#### Scale End 处理
- 清理状态，完成相应操作

### 3. 保持功能完整性

确保所有原有功能仍然可用：
- ✅ 双指捏合缩放
- ✅ 双指滑动平移  
- ✅ 单指滑动平移（平移工具模式）
- ✅ 单指框选（框选工具模式）
- ✅ 选区选择和调整
- ✅ 点击和长按手势

## 技术细节

### 指针数量判断
```dart
_isScaling = details.pointerCount > 1; // 双指为缩放模式
```

### 双指操作处理
```dart
if (details.pointerCount > 1) {
  // 双指缩放
  if (details.scale != _lastScale) {
    // 处理缩放
  }
  
  // 双指平移（当缩放比例不变时）
  if (details.scale == _lastScale && _lastPanPosition != null) {
    // 处理平移
  }
}
```

### 单指操作处理
```dart
// 单指操作
if (toolMode == Tool.pan && _isPanning && _lastPanPosition != null) {
  // 平移模式：单指滑动平移
  _handlePanGesture(_lastPanPosition!, position);
} else if (toolMode == Tool.select) {
  // 框选模式
  if (_isSelecting) {
    _updateSelection(position);
  } else if (_isAdjusting) {
    _handleAdjustmentUpdate(position);
  }
}
```

## 验证结果

- ✅ 构建成功，无手势冲突错误
- ✅ 保持所有原有功能
- ✅ 移动端手势操作流畅自然
- ✅ 工具模式切换正常

## 关键经验

1. **Flutter 手势冲突规则**：
   - Pan 和 Scale 手势不能同时使用
   - Scale 手势是 Pan 手势的超集
   - 优先使用 Scale 手势处理复杂交互

2. **移动端手势设计原则**：
   - 单指操作：点击、滑动、长按
   - 双指操作：缩放、旋转、平移
   - 根据指针数量区分操作类型

3. **状态管理**：
   - 正确跟踪手势状态（_isPanning, _isSelecting, _isAdjusting）
   - 在合适的时机重置状态
   - 避免状态冲突

修复完成，移动端手势操作已恢复正常。