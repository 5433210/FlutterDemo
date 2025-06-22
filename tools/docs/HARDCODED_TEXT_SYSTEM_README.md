# 硬编码文本检测和替换系统

这是一个专门为Flutter项目设计的硬编码文本检测和替换系统，能够自动检测UI界面文本和枚举值显示名称中的硬编码中文文本，并生成相应的ARB国际化键值，实现自动替换。

## 功能特点

### 1. 双重检测能力
- **UI文本检测**: 检测Widget中的文本、UI属性、按钮标签、对话框消息等
- **枚举显示名称检测**: 检测枚举类型的显示名称、toString方法、switch语句等

### 2. 智能键值生成
- 根据代码上下文自动生成有意义的ARB键名
- 避免重复键名冲突
- 支持模块化命名规则

### 3. 安全替换机制
- 创建完整备份系统
- 精确的行级别替换
- 自动添加必要的导入语句
- 错误处理和回滚支持

### 4. 用户审核流程
- 生成YAML格式的映射文件供用户审核
- 支持英文翻译的手动修改
- 只有用户确认的条目才会被处理

## 系统组件

### 核心检测器
1. **enhanced_hardcoded_detector.py** - 增强的UI文本硬编码检测器
2. **enum_display_detector.py** - 智能枚举显示名称检测器
3. **comprehensive_hardcoded_manager.py** - 综合检测管理器

### 应用工具
4. **enhanced_arb_applier.py** - 增强的ARB应用器，执行代码替换
5. **hardcoded_text_manager.bat** - 便捷的批处理管理界面

## 使用方法

### 快速开始
1. 运行 `hardcoded_text_manager.bat`
2. 选择 "1. 综合检测"
3. 审核生成的映射文件
4. 选择 "4. 应用映射文件"

### 详细步骤

#### 步骤1：运行检测
```bash
# 方式1：使用批处理界面（推荐）
hardcoded_text_manager.bat

# 方式2：直接运行Python脚本
python comprehensive_hardcoded_manager.py  # 综合检测
python enhanced_hardcoded_detector.py      # 仅UI文本
python enum_display_detector.py            # 仅枚举显示
```

#### 步骤2：审核映射文件
检测完成后会生成映射文件，例如：
```
comprehensive_hardcoded_report/comprehensive_mapping_20250617_143022.yaml
```

打开映射文件，找到类似以下的条目：
```yaml
ui_text_mappings:
  ui_text_widget:
    works_text_添加作品:
      text_zh: "添加作品"
      text_en: "添加作品"  # 请修改为英文翻译
      file: "presentation/pages/works/work_add_page.dart"
      line: 25
      context_type: "ui_text_widget"
      detection_type: "ui_text"
      approved: false  # 改为 true 表示确认处理
```

审核内容：
1. 检查 `text_zh` 是否正确
2. 修改 `text_en` 为准确的英文翻译
3. 将 `approved` 设置为 `true`

#### 步骤3：执行替换
```bash
# 使用批处理界面
hardcoded_text_manager.bat -> 选择 "4. 应用映射文件"

# 或直接运行
python enhanced_arb_applier.py --auto-latest
```

#### 步骤4：更新本地化文件
```bash
flutter gen-l10n
```

## 检测模式说明

### UI文本检测模式
系统会检测以下类型的硬编码文本：

1. **Widget文本**: Text(), SelectableText()等
2. **UI属性**: hintText, labelText, tooltip等
3. **按钮标签**: ElevatedButton, TextButton等
4. **对话框消息**: AlertDialog, SnackBar等
5. **导航元素**: AppBar, TabBar等
6. **列表卡片**: ListTile, Card等
7. **字符串常量**: static const String等
8. **异常消息**: throw Exception()等

### 枚举检测模式
系统会检测以下类型的枚举显示名称：

1. **Getter方法**: displayName, label, name等
2. **toString方法**: 重写的toString()方法
3. **Switch语句**: case分支中的返回值
4. **When表达式**: 模式匹配中的返回值
5. **扩展方法**: extension中的显示名称
6. **映射定义**: Map或List中的枚举值映射

## 生成的文件结构

```
project_root/
├── comprehensive_hardcoded_report/          # 综合检测报告
│   ├── comprehensive_mapping_*.yaml         # 综合映射文件
│   └── comprehensive_summary_*.txt          # 综合汇总报告
├── hardcoded_detection_report/              # UI文本检测报告
│   ├── hardcoded_mapping_*.yaml            # UI文本映射文件
│   ├── hardcoded_detail_*.txt              # 详细报告
│   └── hardcoded_summary_*.txt             # 汇总报告
├── enum_detection_report/                   # 枚举检测报告
│   ├── enum_mapping_*.yaml                 # 枚举映射文件
│   ├── enum_analysis_*.txt                 # 枚举分析报告
│   └── enum_pattern_detection_*.txt        # 模式检测报告
└── arb_backup_*/                           # 自动生成的备份目录
    ├── app_zh.arb                          # ARB文件备份
    ├── app_en.arb
    └── code/                               # 代码文件备份
```

## 安全特性

### 自动备份
- 每次执行替换前自动备份ARB文件和即将修改的代码文件
- 备份目录以时间戳命名，便于恢复

### 精确替换
- 基于文件名和行号的精确定位
- 只替换确认的硬编码文本
- 保持原有代码格式和结构

### 错误处理
- 详细的错误报告和失败原因
- 替换失败时不影响其他替换操作
- 提供回滚建议

## 配置说明

### 文件路径配置
```python
CODE_DIR = "lib"                    # 代码目录
ARB_DIR = "lib/l10n"               # ARB文件目录
ZH_ARB_PATH = "lib/l10n/app_zh.arb" # 中文ARB文件
EN_ARB_PATH = "lib/l10n/app_en.arb" # 英文ARB文件
```

### 排除模式
系统会自动排除以下内容：
- 注释内容（单行和多行）
- URL和文件路径
- import语句
- 注解内容

## 最佳实践

### 1. 键名命名规范
- 使用模块名作为前缀：`works_btn_add`
- 使用描述性词汇：`msg_delete_confirm`
- 避免通用词汇：`label1`, `text2`

### 2. 翻译质量控制
- 确保英文翻译准确地传达中文含义
- 考虑UI界面的空间限制
- 保持专业术语的一致性

### 3. 批量处理建议
- 分批处理，先处理重要的UI文本
- 逐步验证，确保应用功能正常
- 建立翻译词汇表，保持一致性

### 4. 团队协作
- 审核阶段可以多人参与
- 建立代码审查流程
- 定期运行检测，处理新增硬编码

## 故障排除

### 常见问题

1. **检测不到某些硬编码文本**
   - 检查文本是否包含中文字符
   - 验证文件是否在CODE_DIR目录中
   - 确认文本格式符合检测模式

2. **替换失败**
   - 检查文件是否被其他程序占用
   - 验证行号是否发生变化
   - 确认文本内容是否完全匹配

3. **生成的键名重复**
   - 系统会自动处理重复，添加数字后缀
   - 可以手动修改映射文件中的键名

4. **导入语句问题**
   - 系统会自动添加必要的l10n导入
   - 如有问题可手动添加：
     ```dart
     import '../../../l10n/app_localizations.dart';
     ```

### 恢复操作
如果替换出现问题，可以从备份恢复：
1. 找到对应的备份目录（arb_backup_*）
2. 复制ARB文件回原位置
3. 复制代码文件回原位置
4. 运行 `flutter gen-l10n`

## 扩展和定制

### 添加新的检测模式
在相应的检测器中添加新的正则表达式模式：

```python
DETECTION_PATTERNS = {
    "new_pattern_type": [
        r'new_pattern_regex_here',
        # 更多模式...
    ],
    # 现有模式...
}
```

### 自定义键名生成规则
修改 `generate_arb_key` 方法：

```python
def generate_arb_key(self, text, context, file_context):
    # 自定义逻辑
    return custom_key_name
```

### 添加新的文件类型支持
扩展文件搜索模式：

```python
dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
# 添加其他文件类型
kotlin_files = glob.glob(os.path.join(CODE_DIR, "**/*.kt"), recursive=True)
```

## 版本更新记录

### v1.0.0 (2025-06-17)
- 初始版本发布
- 支持UI文本和枚举显示名称检测
- 实现安全替换机制
- 提供综合检测管理器
- 包含完整的用户审核流程

---

**注意**: 使用本系统前请确保项目已经备份，虽然系统提供了自动备份功能，但额外的备份始终是好习惯。
