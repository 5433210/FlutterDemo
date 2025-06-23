# 本地化支持改进指南

## 当前状态

已为 `configuration_settings.dart` 添加了基本的本地化支持：

### ✅ 已完成
1. 添加了 `AppLocalizations` 导入
2. 使用现有的本地化键：
   - `configManagement`
   - `calligraphyStyle`  
   - `writingTool`
   - `loading`
   - `loadFailed`
   - `retry`

### 🔧 部分完成（暂时使用硬编码）
以下文本暂时使用硬编码，等待本地化文件完全生效后再替换：
- "个选项" - 用于显示配置项数量
- "管理书法风格和书写工具配置" - 配置管理描述
- "正在初始化配置..." - 初始化状态文本
- "配置初始化失败" - 初始化失败文本
- "书法风格管理" - 导航标题
- "书写工具管理" - 导航标题

## 新增的ARB键

已在 `app_zh.arb` 和 `app_en.arb` 中添加了以下键：

```json
{
  "configManagementDescription": "管理书法风格和书写工具配置",
  "configManagementTitle": "书法风格管理",
  "configInitializing": "正在初始化配置...",
  "configInitializationFailed": "配置初始化失败",
  "itemsCount": "{count} 个选项",
  "writingToolManagement": "书写工具管理"
}
```

## 下一步改进

### 1. 等待本地化生成完成
当 Flutter 的本地化生成完成后，可以替换硬编码文本：

```dart
// 替换
subtitle: Text('${items.length} 个选项'),
// 为
subtitle: Text(localizations.itemsCount(items.length)),

// 替换  
subtitle: const Text('管理书法风格和书写工具配置'),
// 为
subtitle: Text(localizations.configManagementDescription),

// 等等...
```

### 2. 完整的本地化方法

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final localizations = AppLocalizations.of(context);
  
  return SettingsSection(
    title: localizations.configManagement,
    // 使用本地化的所有文本...
  );
}
```

### 3. 导航方法本地化

```dart
void _navigateToStyleConfig(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ConfigManagementPage(
        category: 'style',
        title: localizations.configManagementTitle,
      ),
    ),
  );
}
```

## 测试本地化

### 验证方法
1. 在应用中切换语言设置
2. 检查所有文本是否正确显示为对应语言
3. 确认带参数的本地化方法正常工作

### 调试技巧
如果本地化方法不可用：
1. 运行 `flutter clean`
2. 运行 `flutter pub get`
3. 运行 `flutter gen-l10n`
4. 重启 IDE

## 最佳实践

1. **避免硬编码文本**：所有用户可见的文本都应使用本地化
2. **使用有意义的键名**：本地化键应该清楚地描述其用途
3. **提供英文后备**：确保所有支持的语言都有对应的翻译
4. **参数化消息**：对于包含变量的文本，使用参数化本地化方法
5. **文档化**：记录所有本地化键的用途和上下文

## 故障排除

### 常见问题
1. **本地化方法不存在**：确保已运行 `flutter gen-l10n`
2. **编译错误**：检查ARB文件语法是否正确
3. **文本不更新**：可能需要热重启而不是热重载
4. **缺少翻译**：确保所有支持的语言都有对应的ARB文件

### 解决方案
- 检查 `l10n.yaml` 配置
- 验证ARB文件格式
- 确认本地化委托正确配置在应用中
