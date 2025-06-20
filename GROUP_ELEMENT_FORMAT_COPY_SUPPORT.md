# 组合元素格式复制功能支持

## 功能说明

为组合元素（group类型）添加了格式复制和格式应用的支持，使组合元素也能享受格式刷功能。

## 实现内容

### 1. 格式复制功能 (`_copyElementFormatting`)

在 `lib/presentation/pages/practices/m3_practice_edit_page.dart` 中添加了对组合元素的格式复制支持：

```dart
} else if (element['type'] == 'group') {
  // 组合元素样式 - 主要是透明度属性
  _formatBrushStyles!['opacity'] = element['opacity'];
  _formatBrushStyles!['rotation'] = element['rotation'];
  
  // 组合元素的其他可能样式属性
  if (element.containsKey('width')) {
    _formatBrushStyles!['width'] = element['width'];
  }
  if (element.containsKey('height')) {
    _formatBrushStyles!['height'] = element['height'];
  }
  
  // 复制content中的样式属性（如果存在）
  if (element.containsKey('content') &&
      element['content'] is Map<String, dynamic>) {
    final content = element['content'] as Map<String, dynamic>;
    
    // 组合元素可能的样式属性
    final propertiesToCopy = [
      'backgroundColor',
      'borderColor',
      'borderWidth',
      'cornerRadius',
      'shadowColor',
      'shadowOpacity',
      'shadowOffset',
      'shadowBlur',
    ];
    
    // 复制所有指定的样式属性
    for (final property in propertiesToCopy) {
      if (content.containsKey(property)) {
        _formatBrushStyles!['content_$property'] = content[property];
      }
    }
  }
}
```

### 2. 格式应用功能 (`_applyFormatBrush`)

在同一文件中添加了对组合元素的格式应用支持：

```dart
} else if (elementType == 'group') {
  // 组合元素样式处理 - 主要是透明度和基本属性
  // 组合元素通常只应用基本的变换属性，已在通用样式部分处理
  
  // 应用content中的样式属性（如果存在）
  if (newProperties.containsKey('content') &&
      newProperties['content'] is Map) {
    Map<String, dynamic> content =
        Map<String, dynamic>.from(newProperties['content'] as Map);

    // 应用组合元素可能的样式属性
    final propertiesToApply = [
      'backgroundColor',
      'borderColor',
      'borderWidth',
      'cornerRadius',
      'shadowColor',
      'shadowOpacity',
      'shadowOffset',
      'shadowBlur',
    ];

    // 应用所有指定的样式属性
    for (final property in propertiesToApply) {
      final brushKey = 'content_$property';
      if (_formatBrushStyles!.containsKey(brushKey)) {
        content[property] = _formatBrushStyles![brushKey];
      }
    }

    // 更新元素的content属性
    newProperties['content'] = content;
  }
}
```

## 支持的属性

### 基本属性（外层）
- ✅ **透明度** (`opacity`) - 主要的可复制属性
- ✅ **旋转** (`rotation`) - 变换属性
- ✅ **宽度** (`width`) - 尺寸属性
- ✅ **高度** (`height`) - 尺寸属性

### 样式属性（content内）
- ✅ **背景颜色** (`backgroundColor`)
- ✅ **边框颜色** (`borderColor`)
- ✅ **边框宽度** (`borderWidth`)
- ✅ **圆角半径** (`cornerRadius`)
- ✅ **阴影颜色** (`shadowColor`)
- ✅ **阴影透明度** (`shadowOpacity`)
- ✅ **阴影偏移** (`shadowOffset`)
- ✅ **阴影模糊** (`shadowBlur`)

## 使用方式

1. **复制格式**：
   - 选中一个组合元素
   - 按 `Alt+Q` 或点击工具栏的"复制格式"按钮
   - 格式刷被激活，组合元素的样式被复制

2. **应用格式**：
   - 选中目标组合元素（可以是单个或多个）
   - 按 `Alt+W` 或点击工具栏的"应用格式刷"按钮
   - 复制的样式被应用到目标元素

## 特点

- **兼容性**：与现有的文本、图像、集字元素格式刷功能完全兼容
- **选择性**：只复制和应用存在的属性，避免强制覆盖
- **灵活性**：支持从组合元素复制格式应用到其他组合元素
- **一致性**：遵循现有格式刷的交互模式和UI反馈

## 验证

可以通过以下方式验证功能：

1. 创建两个组合元素
2. 为第一个组合元素设置透明度、背景色等样式
3. 选中第一个组合元素，按 `Alt+Q` 复制格式
4. 选中第二个组合元素，按 `Alt+W` 应用格式
5. 验证第二个组合元素的样式是否与第一个一致

## 相关文件

- `lib/presentation/pages/practices/m3_practice_edit_page.dart` - 主要实现文件

这个功能扩展使得组合元素的样式管理更加便捷，特别是在处理多个相似组合元素时，可以快速统一它们的视觉效果。
