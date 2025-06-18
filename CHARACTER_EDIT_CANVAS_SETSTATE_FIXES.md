# CharacterEditCanvas setState After Dispose 修复文档

## 问题描述
CharacterEditCanvas 组件中出现 "setState() called after dispose()" 错误，主要发生在以下场景：
- Timer 回调中调用 setState
- 异步操作完成后调用 setState  
- ValueNotifier 监听器中调用 setState
- 键盘事件处理中调用 setState

## 错误堆栈示例
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: setState() called after dispose(): CharacterEditCanvasState#e7223(lifecycle state: defunct, not mounted)
CharacterEditCanvasState._updateOutline.<anonymous closure> (package:charasgem/widgets/character_edit/character_edit_canvas.dart:726:7)
Timer._createTimer.<anonymous closure> (dart:async-patch/timer_patch.dart:18:15)
```

## 修复方案

### 1. 添加 `_disposed` 状态标志
```dart
bool _disposed = false;

@override
void dispose() {
  _disposed = true;
  // ... 其他清理代码
  super.dispose();
}
```

### 2. 强化所有 setState 调用的生命周期检查

#### Timer 回调修复
**修复前：**
```dart
Timer(const Duration(milliseconds: 50), () async {
  if (!mounted) return;
  setState(() => _isProcessing = true);
});
```

**修复后：**
```dart  
Timer(const Duration(milliseconds: 50), () async {
  if (_disposed || !mounted) return;
  setState(() => _isProcessing = true);
});
```

#### 异步操作完成后修复
**修复前：**
```dart
if (mounted) {
  setState(() {
    _outline = result.outline;
    _isProcessing = false;
  });
}
```

**修复后：**
```dart
if (!_disposed && mounted) {
  setState(() {
    _outline = result.outline;  
    _isProcessing = false;
  });
}
```

#### ValueNotifier 监听器修复
**修复前：**
```dart
_altKeyNotifier.addListener(() {
  if (mounted) {
    setState(() {
      // UI更新
    });
  }
});
```

**修复后：**
```dart
_altKeyNotifier.addListener(() {
  if (!_disposed && mounted) {
    setState(() {
      // UI更新  
    });
  }
});
```

#### 键盘事件处理修复
**修复前：**
```dart
if (mounted) {
  setState(() {
    _isAltKeyPressed = isDown;
    _lastAltToggleTime = now;
  });
}
```

**修复后：**
```dart
if (!_disposed && mounted) {
  setState(() {
    _isAltKeyPressed = isDown;
    _lastAltToggleTime = now;
  });
}
```

#### Future.delayed 回调修复
**修复前：**
```dart
Future.delayed(const Duration(milliseconds: 50), () {
  if (mounted && _altKeyNotifier.value != isPressed) {
    setState(() {});
  }
});
```

**修复后：**
```dart
Future.delayed(const Duration(milliseconds: 50), () {
  if (!_disposed && mounted && _altKeyNotifier.value != isPressed) {
    setState(() {});
  }
});
```

### 3. 确保定时器清理
在 dispose 方法中确保所有定时器被取消：
```dart
@override
void dispose() {
  _disposed = true;
  _updateOutlineDebounceTimer?.cancel();
  // ... 其他清理
  super.dispose();
}
```

## 修复的 setState 调用位置

1. **_altKeyNotifier 监听器** (line ~152)
2. **_handleRawKeyEvent 键盘处理** (line ~475) 
3. **_handleKeyboardEvent 键盘处理** (line ~497)
4. **_onFocusChange 焦点变化** (line ~540)
5. **_updateAltState UI更新** (line ~623)
6. **Future.delayed 延迟回调** (line ~636)
7. **_updateOutline Timer回调** (line ~727)
8. **异步处理完成回调** (line ~786)
9. **错误处理回调** (line ~819)

## 验证方法

1. 运行应用并在字符编辑界面操作
2. 快速切换页面/关闭对话框
3. 检查控制台是否还有 setState after dispose 错误
4. 特别测试 Alt 键按压和释放操作
5. 测试图像处理过程中的页面切换

## 最佳实践

1. **双重检查**：始终使用 `!_disposed && mounted` 进行检查
2. **及时清理**：在 dispose 中设置 _disposed = true
3. **定时器管理**：确保所有 Timer 在 dispose 中被取消
4. **异步操作**：长时间异步操作前后都要检查组件状态
5. **监听器清理**：确保所有监听器在 dispose 中被移除

## 注意事项

- `_disposed` 标志应该在 dispose 方法的最开始设置
- mounted 检查仍然重要，因为它检查组件是否在 widget 树中
- _disposed 检查确保组件没有被销毁
- 对于长时间运行的异步操作，建议使用 Completer 并在 dispose 中取消

这些修复确保了 CharacterEditCanvas 组件的生命周期安全，避免了所有 setState after dispose 错误。
