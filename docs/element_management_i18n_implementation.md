# 元素管理混入多语言支持实现说明

## 概述

本文档描述了 `ElementManagementMixin` 中多语言支持的实现过程和使用方法。

## 实现的修改

### 1. 本地化键值对添加

在 `app_zh.arb` 和 `app_en.arb` 文件中添加了以下键值对：

```json
{
  "collectionElement": "集字元素",    // 英文: "Collection Element"
  "imageElement": "图片元素",        // 英文: "Image Element"  
  "textElement": "文本元素",         // 英文: "Text Element"
  "defaultEditableText": "属性面板编辑文本",  // 英文: "Editable Text in Property Panel"
  "defaultLayer": "默认图层"         // 英文: "Default Layer"
}
```

### 2. ElementManagementMixin 修改

在 `ElementManagementMixin` 中：

1. **添加了导入语句**：
   ```dart
   import '../../../l10n/app_localizations.dart';
   ```

2. **添加了抽象属性**：
   ```dart
   /// 获取本地化实例 - 需要由实现类提供
   AppLocalizations get l10n;
   ```

3. **替换了所有硬编码字符串**：
   - `'集字元素'` → `l10n.collectionElement`
   - `'图片元素'` → `l10n.imageElement`
   - `'文本元素'` → `l10n.textElement`
   - `'属性面板编辑文本'` → `l10n.defaultEditableText`
   - `'默认图层'` → `l10n.defaultLayer`

### 3. PracticeEditController 修改

在 `PracticeEditController` 中：

1. **添加了导入语句**：
   ```dart
   import '../../../l10n/app_localizations.dart';
   ```

2. **添加了本地化字段**：
   ```dart
   // 本地化实例
   final AppLocalizations _l10n;
   ```

3. **修改了构造函数**：
   ```dart
   PracticeEditController(this._practiceService, this._l10n) {
     // ...
   }
   ```

4. **实现了抽象方法**：
   ```dart
   /// 获取本地化实例（为 ElementManagementMixin 提供）
   @override
   AppLocalizations get l10n => _l10n;
   ```

## 使用方法

### 在页面中使用控制器

```dart
class MyEditPage extends StatefulWidget {
  @override
  _MyEditPageState createState() => _MyEditPageState();
}

class _MyEditPageState extends State<MyEditPage> {
  late PracticeEditController _controller;

  @override
  void initState() {
    super.initState();
    // 注意：l10n 需要在 build 方法中获取，不能在 initState 中获取
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 获取本地化实例和服务
    final l10n = AppLocalizations.of(context);
    final practiceService = /* 获取服务实例 */;
    
    // 初始化控制器
    _controller = PracticeEditController(practiceService, l10n);
  }

  @override
  Widget build(BuildContext context) {
    // 构建UI...
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 或者在 Provider 中使用

```dart
class EditPageProvider extends ChangeNotifier {
  PracticeEditController? _controller;
  
  PracticeEditController getController(BuildContext context) {
    if (_controller == null) {
      final l10n = AppLocalizations.of(context);
      final practiceService = /* 获取服务实例 */;
      _controller = PracticeEditController(practiceService, l10n);
    }
    return _controller!;
  }
}
```

## 影响的功能

以下功能现在支持多语言：

1. **元素创建时的默认名称**：
   - 集字元素默认名称
   - 图片元素默认名称
   - 文本元素默认名称

2. **文本元素的默认内容**：
   - 新创建的文本元素将显示本地化的默认文本

3. **图层管理**：
   - 默认图层的名称

## 注意事项

1. **构造函数变更**：所有创建 `PracticeEditController` 的地方都需要传入 `AppLocalizations` 实例。

2. **Context 依赖**：`AppLocalizations.of(context)` 需要在 Widget 的 build 阶段调用，不能在 initState 中调用。

3. **向后兼容性**：这是一个破坏性更改，需要更新所有使用控制器的地方。

## 验证

可以通过以下方式验证多语言支持：

1. 切换系统语言（中文/英文）
2. 创建新的元素，观察默认名称是否正确显示对应语言
3. 检查新建文本元素的默认内容是否为对应语言版本

## 未来扩展

可以继续添加更多需要本地化的字符串，如：

- 操作描述（用于撤销/重做）
- 错误消息
- 提示文本
- 状态描述等

只需要在 ARB 文件中添加对应的键值对，然后在代码中替换硬编码字符串即可。
