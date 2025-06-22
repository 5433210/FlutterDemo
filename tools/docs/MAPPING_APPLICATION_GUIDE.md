# 📋 映射文件应用完整指南

## 🚀 快速应用步骤

### 步骤1: 检查映射文件状态

首先查看最新的映射文件是否存在已审核的条目：

```bash
# 查看需要审核的条目数量
grep -c "approved: false" multilingual_hardcoded_report/multilingual_mapping_*.yaml

# 查看已审核的条目数量  
grep -c "approved: true" multilingual_hardcoded_report/multilingual_mapping_*.yaml
```

### 步骤2: 审核映射文件

打开映射文件，对每个条目进行审核：

```yaml
# 示例：需要审核的条目
- homePageTitle:
    text_zh: "字体测试工具"
    text_en: "Font Test Tool"      # 修改为合适的英文翻译
    file: "presentation/pages/home_page.dart"
    line: 24
    action: "create_new"
    approved: true                 # 改为 true 表示审核通过
```

### 步骤3: 预览更改（干运行模式）

使用干运行模式预览即将应用的更改：

```bash
# 使用最新映射文件预览
python multilingual_mapping_applier.py --auto-latest --dry-run

# 或指定具体文件
python multilingual_mapping_applier.py --input "path/to/mapping.yaml" --dry-run
```

预览输出示例：
```
🔍 === 映射文件应用预览 ===
✅ 成功加载映射文件: demo_mapping.yaml
✅ 已加载ARB文件 - 中文: 708 键, 英文: 708 键

📊 === 映射统计 ===
总条目数: 8
已审核条目: 8
复用条目: 3
新建条目: 5

📝 === ARB文件更改预览 ===
将添加 5 个新键到ARB文件:
  homePageTitle:
    zh: 字体测试工具
    en: Font Test Tool

🔧 === 代码更改预览 ===
将更改 8 处代码:
  文件: lib/presentation/pages/home_page.dart
  行号: 24
  原文: "字体测试工具"
  替换: S.of(context).homePageTitle
```

### 步骤4: 正式应用更改

确认预览无误后，移除 `--dry-run` 参数正式应用：

```bash
# 应用最新映射文件
python multilingual_mapping_applier.py --auto-latest

# 系统会要求确认
⚠️  即将应用更改，这将修改代码文件和ARB文件。
确认继续？(y/N): y
```

应用过程会：
1. 自动创建备份（包含时间戳的backup目录）
2. 更新ARB文件（添加新键）
3. 替换代码中的硬编码文本
4. 显示详细的执行结果

## 🔧 替换效果演示

### 代码替换前后对比

**替换前：**
```dart
// home_page.dart
Text('字体测试工具')
const Text('Home Page')
tooltip: '编辑标签'
```

**替换后：**
```dart
// home_page.dart  
Text(S.of(context).homePageTitle)
const Text(S.of(context).homePageEnglish)
tooltip: S.of(context).editTags
```

### ARB文件更新

**app_zh.arb 新增：**
```json
{
  "homePageTitle": "字体测试工具",
  "homePageEnglish": "首页", 
  "editTags": "编辑标签"
}
```

**app_en.arb 新增：**
```json
{
  "homePageTitle": "Font Test Tool",
  "homePageEnglish": "Home Page",
  "editTags": "Edit Tags"
}
```

## 📋 完整工作流程

### 1. 运行检测
```bash
python multilingual_hardcoded_detector.py --mode both --output-format yaml
```

### 2. 审核映射文件
- 打开生成的 `multilingual_mapping_*.yaml` 文件
- 检查每个条目的键名和翻译
- 将审核通过的条目标记为 `approved: true`

### 3. 预览更改
```bash
python multilingual_mapping_applier.py --auto-latest --dry-run
```

### 4. 应用更改
```bash
python multilingual_mapping_applier.py --auto-latest
```

### 5. 验证结果
- 检查备份是否创建
- 验证ARB文件是否正确更新
- 测试代码编译和运行
- 检查UI文本是否正常显示

## ⚠️ 注意事项

### 安全措施
- **自动备份**：每次应用都会创建带时间戳的备份目录
- **干运行模式**：先预览再应用，避免意外更改
- **审核机制**：只处理 `approved: true` 的条目

### 审核要点
1. **键名检查**：确保键名符合项目命名规范
2. **翻译质量**：检查英文翻译是否准确、自然
3. **上下文适配**：确保翻译适合具体的UI场景
4. **复用验证**：检查复用的键是否真的匹配

### 常见问题

**Q: 如果应用失败怎么办？**
A: 系统会创建备份，可以从backup目录恢复原始文件。

**Q: 可以部分应用映射吗？**
A: 可以，只需将不需要的条目的 `approved` 设为 `false`。

**Q: 如何回滚更改？**
A: 从最近的backup目录复制文件回来即可。

**Q: 替换后编译失败怎么办？**
A: 检查是否需要添加import语句，或者键名是否包含特殊字符。

## 🎯 最佳实践

### 审核流程
1. **逐条检查**：不要批量标记，逐个审核每个条目
2. **测试翻译**：在实际UI中验证翻译效果
3. **保持一致**：确保同类UI文本使用一致的翻译风格
4. **分批应用**：大型项目建议分批次应用，便于测试

### 命名规范
- 使用有意义的驼峰式键名
- 包含必要的上下文信息
- 避免过长或过短的键名
- 保持项目内的命名一致性

现在您可以安全、可控地将检测到的硬编码文本应用到项目中了！🚀
