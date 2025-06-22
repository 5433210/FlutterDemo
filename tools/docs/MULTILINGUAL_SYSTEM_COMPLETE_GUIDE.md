# 多语言硬编码文本检测和替换系统完整指南

## 🌟 系统概述

本系统专为Flutter项目设计，能够自动检测和替换代码中的中英文硬编码文本，支持ARB键复用、智能命名、并提供完整的审核和替换流程。

### ✨ 主要特性

- **双语言支持**：同时检测中文和英文硬编码文本
- **高覆盖率检测**：支持Text、hintText、labelText、tooltip、对话框、按钮等多种UI场景
- **智能键复用**：自动检测并复用现有ARB键，避免重复翻译
- **上下文感知命名**：根据文件路径和模块生成符合项目习惯的键名
- **完整工作流程**：从检测、审核到替换的一站式解决方案
- **安全可控**：支持干运行模式，所有更改都可预览和撤销

## 📁 系统文件结构

```
demo/
├── multilingual_hardcoded_detector.py    # 主检测器
├── enhanced_arb_applier.py               # ARB应用器
├── multilingual_detector_manager.bat     # 管理脚本
├── multilingual_hardcoded_report/        # 报告目录
│   ├── multilingual_summary_*.txt        # 汇总报告
│   ├── multilingual_detail_*.txt         # 详细报告
│   └── multilingual_mapping_*.yaml       # 映射文件
├── lib/l10n/
│   ├── app_zh.arb                        # 中文ARB文件
│   └── app_en.arb                        # 英文ARB文件
└── lib/                                  # 源代码目录
```

## 🚀 快速开始

### 1. 运行检测

**方法一：使用管理脚本（推荐）**
```bash
./multilingual_detector_manager.bat
```
选择选项 `[1] 检测中英文硬编码文本`

**方法二：直接命令行**
```bash
python multilingual_hardcoded_detector.py --mode both --output-format yaml
```

### 2. 查看检测结果

检测完成后会生成三个文件：
- `multilingual_summary_*.txt` - 汇总报告
- `multilingual_detail_*.txt` - 详细报告  
- `multilingual_mapping_*.yaml` - 映射文件

### 3. 审核映射文件

打开生成的YAML映射文件，检查并修改：

```yaml
# 示例映射条目
- homePageTitle:
    text_en: "Home Page"              # 英文原文
    text_zh: "首页"                   # 修改为合适的中文翻译
    file: presentation/pages/home_page.dart
    line: 13
    action: create_new                # create_new 或 reuse_existing
    approved: true                    # 改为 true 表示审核通过
```

### 4. 应用替换

```bash
python enhanced_arb_applier.py --input multilingual_hardcoded_report/multilingual_mapping_*.yaml --dry-run
```

确认无误后移除 `--dry-run` 参数正式应用。

## 🔍 检测能力详解

### 支持的中文检测场景

- **Text Widget**: `Text('中文文本')`
- **UI属性**: `hintText: '请输入', labelText: '标签', tooltip: '提示'`
- **按钮**: `ElevatedButton(child: Text('按钮'))`
- **对话框**: `AlertDialog(title: Text('标题'), content: Text('内容'))`
- **应用栏**: `AppBar(title: Text('标题'))`
- **列表**: `ListTile(title: Text('标题'))`

### 支持的英文检测场景

- **Text Widget**: `Text('Home Page')`, `const Text('Cancel')`
- **UI属性**: `tooltip: 'Edit Tags', hintText: 'Enter text'`
- **按钮**: `child: Text('Save'), label: Text('Submit')`
- **对话框**: `AlertDialog(title: Text('Confirm'))`
- **导航**: `BottomNavigationBarItem(label: 'Home')`

### 智能过滤机制

系统会自动排除以下内容，避免误检：
- 注释中的文本
- 导入语句和包名
- 调试和日志语句
- 技术术语和编程关键词
- 单字母或过短的文本
- URL和文件路径

## 🎯 ARB键复用策略

### 相似度算法

系统使用字符串相似度算法检测可复用的ARB键：
- **相似度 ≥ 0.9**: 自动复用，标记为已审核
- **0.8 ≤ 相似度 < 0.9**: 建议复用，需人工确认
- **相似度 < 0.8**: 创建新键

### 复用示例

```yaml
# 英文文本 "Cancel" 自动复用现有键
- cancel:
    text_en: "Cancel"
    text_zh: "取消"                   # 自动获取现有中文翻译
    action: reuse_existing
    similarity: 1.0
    approved: true                    # 自动标记为已审核

# 英文文本 "Element" 复用相似键 "elements"
- elements:
    text_en: "Element"
    text_zh: "元素"
    action: reuse_existing
    similarity: 0.93
    approved: true
```

## 🏗️ 键名生成规则

### 中文键名生成

- **提取中文字符**：提取文本中的中文部分
- **长度限制**：截取前8个字符
- **模块前缀**：根据文件路径添加模块前缀

```
文件：lib/presentation/pages/home/home_page.dart
文本：首页
生成：home首页
```

### 英文键名生成

- **驼峰命名**：首个单词小写，后续单词首字母大写
- **长度限制**：最多4个单词
- **模块前缀**：根据文件路径添加模块前缀

```
文件：lib/presentation/widgets/common/button.dart
文本：Save Changes
生成：widgetSaveChanges
```

### 冲突处理

当生成的键名已存在时，系统会自动添加数字后缀：
```
homeTitle → homeTitle1 → homeTitle2 ...
```

## 📊 检测报告详解

### 汇总报告示例

```
=== 多语言硬编码文本检测汇总报告 ===
检测时间: 2025-06-17 03:18:19

=== 中文硬编码检测结果 ===
检测总数: 36
复用ARB键: 9
新建键: 27

中文硬编码按类型分布:
  - ui_properties: 13
  - ui_text_widget: 20
  - ui_appbar_navigation: 3

=== 英文硬编码检测结果 ===
检测总数: 57
复用ARB键: 21
新建键: 36

英文硬编码按类型分布:
  - ui_text_widget: 24
  - ui_appbar_navigation: 12
  - ui_buttons_labels: 14
  - ui_properties: 7

=== 总体统计 ===
硬编码文本总数: 93
ARB键复用总数: 30
新建键总数: 63
```

### 详细报告示例

```
--- UI_TEXT_WIDGET (24 个) ---
文件: presentation/pages/home_page.dart, 行: 13
文本: "Home Page"
建议键: home_page.dartHomepage
操作: 创建新键

文件: presentation/pages/practices/widgets/practice_title_edit_dialog.dart, 行: 53
文本: "Cancel"
复用键: cancel (相似度: 1.00)
操作: 复用现有键
```

## ⚙️ 高级配置

### 自定义检测模式

```bash
# 只检测中文
python multilingual_hardcoded_detector.py --mode chinese

# 只检测英文  
python multilingual_hardcoded_detector.py --mode english

# 检测全部（默认）
python multilingual_hardcoded_detector.py --mode both
```

### 输出格式选项

```bash
# YAML格式（推荐，用于后续处理）
python multilingual_hardcoded_detector.py --output-format yaml

# JSON格式
python multilingual_hardcoded_detector.py --output-format json

# 纯文本格式
python multilingual_hardcoded_detector.py --output-format text
```

### 排除特定文件

编辑检测器脚本，在`CODE_DIR`常量附近添加排除模式：

```python
EXCLUDED_PATHS = [
    '**/test/**',
    '**/generated/**',
    '**/build/**'
]
```

## 🛠️ 故障排除

### 常见问题

1. **正则表达式错误**
   ```
   Error: unterminated character set at position 10
   ```
   **解决方法**：确保正则表达式中的字符类正确闭合，检查方括号配对。

2. **编码错误**
   ```
   UnicodeDecodeError: 'utf-8' codec can't decode byte
   ```
   **解决方法**：确保所有Dart文件都是UTF-8编码。

3. **ARB文件不存在**
   ```
   FileNotFoundError: [Errno 2] No such file or directory: 'lib/l10n/app_zh.arb'
   ```
   **解决方法**：确保ARB文件路径正确，或修改检测器中的ARB文件路径配置。

### 调试模式

为检测器添加详细日志输出：

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### 性能优化

对于大型项目，可以：
1. 限制检测的文件范围
2. 使用多进程并行处理
3. 缓存ARB文件内容

## 📝 最佳实践

### 1. 定期检测

建议在开发过程中定期运行检测：
- 每日构建时自动检测
- 代码提交前手动检测
- 发布前完整检测

### 2. 团队协作

- 指定专人负责审核映射文件
- 建立翻译质量标准
- 维护项目专用术语表

### 3. 质量控制

- 审核所有新建的ARB键名
- 验证翻译的准确性和一致性
- 测试替换后的UI效果

### 4. 备份策略

- 应用替换前备份原始文件
- 使用版本控制跟踪所有更改
- 保留检测报告用于历史追溯

## 🔄 持续改进

### 扩展检测场景

根据项目需要，可以添加新的检测模式：

```python
# 添加新的检测模式到 ENGLISH_PATTERNS 或 CHINESE_PATTERNS
"ui_forms": [
    r'FormField.*?labelText:\s*[\'\"](.*?)[\'\"]',
    r'TextFormField.*?hintText:\s*[\'\"](.*?)[\'\"]',
]
```

### 优化键名生成

根据项目命名习惯调整键名生成算法：

```python
def generate_custom_key(self, text, context, file_path, language):
    # 自定义键名生成逻辑
    pass
```

### 集成CI/CD

将检测过程集成到持续集成流程：

```yaml
# GitHub Actions 示例
- name: Detect Hardcoded Text
  run: |
    python multilingual_hardcoded_detector.py --mode both
    # 检查是否有新的硬编码文本
```

## 📞 支持与反馈

如果遇到问题或有改进建议，请：
1. 查看本文档的故障排除部分
2. 检查相关的README文件
3. 提交issue或联系开发团队

---

**系统版本**: 2.0  
**最后更新**: 2025-06-17  
**支持语言**: 中文、英文  
**兼容性**: Flutter 3.0+, Dart 3.0+
