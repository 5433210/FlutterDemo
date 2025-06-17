# 多语言硬编码文本检测和替换系统 - 完整使用指南

## 🎯 系统概述

本系统提供了一个完整的Flutter项目硬编码文本检测、替换和多语言化解决方案，支持中英文双语检测、ARB键复用、智能命名、批量处理等功能。

## 📁 系统文件组成

### 核心脚本
1. **multilingual_hardcoded_detector.py** - 多语言硬编码文本检测器
2. **multilingual_mapping_applier.py** - 映射文件应用器（已修复语法错误）
3. **multilingual_mapping_applier_fixed.py** - 修复版本备份

### 管理脚本
- **multilingual_detector_manager.bat** - 一键检测管理脚本

### 示例文件
- **demo_mapping.yaml** - 标准YAML格式映射文件示例
- **demo_mapping_simple.yaml** - 简化格式映射文件示例

## 🚀 完整使用流程

### 第1步：检测硬编码文本

```bash
# 运行检测器，生成映射文件
python multilingual_hardcoded_detector.py

# 或使用批处理脚本
multilingual_detector_manager.bat
```

**输出：**
- 检测报告：`multilingual_hardcoded_report/multilingual_detection_report_YYYYMMDD_HHMMSS.txt`
- 映射文件：`multilingual_hardcoded_report/multilingual_mapping_YYYYMMDD_HHMMSS.yaml`

### 第2步：审核映射文件

打开生成的映射文件，进行以下操作：

1. **检查英文翻译**：确保所有英文翻译准确
2. **修改键名**：如需要，可以修改ARB键名
3. **批准条目**：将需要应用的条目的 `approved` 设置为 `true`

```yaml
# 示例格式
chinese:
  - text_zh: "保存"
    text_en: "Save"  # 确认英文翻译
    arb_key: "save"  # 可修改键名
    file: "lib/pages/edit_page.dart"
    line: 42
    action: "create"
    approved: true   # 设置为true表示批准应用
```

### 第3步：预览更改

```bash
# 预览模式 - 查看将要进行的更改
python multilingual_mapping_applier.py --input "映射文件路径" --dry-run

# 自动使用最新映射文件
python multilingual_mapping_applier.py --auto-latest --dry-run
```

**预览内容包括：**
- 统计信息（总数、已审核、复用/新建等）
- 将要添加到ARB文件的新键
- 将要修改的代码位置和替换内容

### 第4步：正式应用更改

```bash
# 正式应用（会提示确认）
python multilingual_mapping_applier.py --input "映射文件路径"

# 自动使用最新映射文件
python multilingual_mapping_applier.py --auto-latest
```

**自动功能：**
- 代码文件自动备份（`.backup.时间戳`）
- ARB文件自动备份
- 生成详细应用报告

## 🔧 高级功能

### 1. 检测器高级选项

```bash
# 指定检测目录
python multilingual_hardcoded_detector.py --scan-dir lib/specific_dir

# 排除特定文件
python multilingual_hardcoded_detector.py --exclude-pattern "**/test/**"

# 生成详细报告
python multilingual_hardcoded_detector.py --verbose
```

### 2. 应用器高级选项

```bash
# 预览模式
python multilingual_mapping_applier.py -i mapping.yaml -d

# 使用最新映射文件
python multilingual_mapping_applier.py -a -d

# 查看帮助
python multilingual_mapping_applier.py --help
```

## 🛡️ 安全特性

### 自动备份
- 修改前所有文件自动备份
- 备份文件命名：`原文件名.backup.YYYYMMDD_HHMMSS`

### 预览机制
- 强制预览模式确认更改
- 详细显示所有即将进行的操作

### 错误处理
- 文件不存在检查
- 语法错误提示
- 权限错误处理

## 📊 映射文件格式

### 标准YAML格式（推荐）

```yaml
chinese:
  - text_zh: "中文文本"
    text_en: "English Text"
    arb_key: "example_key"
    file: "lib/example.dart"
    line: 42
    action: "create"  # 或 "reuse"
    approved: true

english:
  - text_zh: "Chinese Translation"
    text_en: "English Text"
    arb_key: "english_key"
    file: "lib/example.dart"
    line: 45
    action: "create"
    approved: true
```

### OrderedDict格式（自动支持）

系统自动识别和处理Python OrderedDict格式的YAML文件。

## 🐛 常见问题解决

### 1. YAML语法错误

**错误：** `mapping values are not allowed here`

**解决：**
1. 检查YAML文件语法，特别注意缩进
2. 删除包含特殊字符如 `{type}` 的问题行
3. 使用标准格式重新生成映射文件

### 2. 文件路径问题

**错误：** 文件不存在

**解决：**
1. 检查文件路径格式（Windows使用反斜杠）
2. 确保文件在正确的相对路径位置
3. 检查文件权限

### 3. 应用失败

**解决：**
1. 先运行预览模式检查
2. 确保有文件写入权限
3. 检查备份空间是否足够

## 📈 系统状态

### ✅ 已完成功能
- [x] 中英文硬编码文本检测
- [x] ARB键复用和智能命名
- [x] 批量检测和报告生成
- [x] 映射文件审核流程
- [x] 干运行预览模式
- [x] 自动备份和安全应用
- [x] 详细应用报告
- [x] 语法错误修复
- [x] OrderedDict格式支持

### 🔄 改进空间
- [ ] 复杂嵌套文本的替换优化
- [ ] 大型项目性能优化
- [ ] 批量审核界面
- [ ] 回滚功能增强

## 📞 使用支持

如遇到问题：
1. 首先运行预览模式检查
2. 查看生成的报告文件
3. 检查备份文件是否正确生成
4. 确认映射文件格式符合规范

系统已经过完整测试，可以安全用于生产环境。建议在大批量应用前先在小范围测试。
