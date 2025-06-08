# 图像属性面板模块

这个目录包含了从原始的 `m3_practice_property_panel_image.dart` 文件拆分出来的多个小文件，按功能模块进行组织。

## 文件结构

### 主要文件

- **`image_property_panel.dart`** - 主要的图像属性面板组件
  - 包含 `M3ImagePropertyPanel` 主组件
  - 负责整体布局和状态管理
  - 使用其他模块的功能

### 混合类 (Mixins)

- **`image_property_panel_mixins.dart`** - 属性访问器和更新器
  - `ImagePropertyAccessors` - 提供图像属性的访问方法
  - `ImagePropertyUpdaters` - 提供属性更新的方法

### 功能处理器

- **`image_selection_handler.dart`** - 图像选择处理
  - `ImageSelectionHandler` mixin
  - 处理从图库和本地选择图像的逻辑

- **`image_transform_handler.dart`** - 图像变换处理
  - `ImageTransformHandler` mixin
  - 处理图像变换应用和重置的逻辑

### UI组件

- **`image_property_panel_widgets.dart`** - 所有UI组件
  - `ImagePropertyGeometryPanel` - 几何属性面板
  - `ImagePropertyVisualPanel` - 视觉属性面板
  - `ImagePropertySelectionPanel` - 图像选择面板
  - `ImagePropertyFitModePanel` - 适应模式面板
  - `ImagePropertyPreviewPanel` - 图像预览面板
  - `ImagePropertyTransformPanel` - 图像变换面板

### 绘制器

- **`image_transform_painter.dart`** - 变换预览绘制器
  - `ImageTransformPreviewPainter` - 自定义绘制器，用于显示变换预览

### 导出文件

- **`image_property_panel_export.dart`** - 统一导出文件
  - 方便其他地方导入所有相关组件

## 使用方式

```dart
// 导入主组件
import 'package:your_app/presentation/widgets/practice/property_panels/image/image_property_panel.dart';

// 或者导入所有组件
import 'package:your_app/presentation/widgets/practice/property_panels/image/image_property_panel_export.dart';
```

## 拆分的好处

1. **模块化** - 每个文件专注于特定功能
2. **可维护性** - 更容易定位和修改特定功能
3. **可重用性** - 组件可以在其他地方重用
4. **可测试性** - 更容易为单个功能编写测试
5. **代码可读性** - 文件更小，更容易理解

## 原始文件

原始的 `m3_practice_property_panel_image.dart` 文件超过2200行，现在已经被拆分成多个更小、更专注的文件。 