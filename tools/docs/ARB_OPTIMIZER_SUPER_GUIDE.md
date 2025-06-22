# ARB 优化超级指南

## 概述

本指南介绍了如何使用增强版ARB优化工具来优化Flutter项目中的本地化资源。该工具可以帮助您：

1. 识别并合并具有相同值的键
2. 删除不必要的模块或页面前缀
3. 将含义相同的键进行分组和合并
4. 按语义类别组织并排序键
5. 输出易于阅读和编辑的YAML格式

## 工具介绍

本套工具包含以下几个关键文件：

- `super_enhanced_arb_mapping.py`: 超级增强版ARB分析与映射生成工具
- `generate_super_enhanced_mapping.bat/ps1`: Windows批处理/PowerShell脚本，用于运行映射生成工具
- `apply_arb_mapping.py`: 应用YAML映射到ARB文件和代码的工具
- `apply_arb_mapping.bat/ps1`: Windows批处理/PowerShell脚本，用于应用映射

## 使用步骤

### 1. 生成YAML映射文件

运行以下命令之一来生成YAML映射文件：

```bash
# 使用批处理脚本
generate_super_enhanced_mapping.bat

# 或使用PowerShell脚本
.\generate_super_enhanced_mapping.ps1

# 或直接运行Python脚本
python super_enhanced_arb_mapping.py
```

这将在`arb_report`目录下生成`key_mapping.yaml`文件。

### 2. 编辑YAML映射文件

手动编辑生成的YAML文件，根据您的需求调整键的映射关系。文件格式如下：

```yaml
key: value #替代了其他key的
   key: value
   oldkey1: oldkey1 value
   oldkey2: oldkey2 value

key2: value #没有替代其他key的
   key2: value
```

您可以：

- 修改主键的名称和值
- 调整哪些键被合并到哪个主键下
- 添加或删除映射关系

### 3. 应用YAML映射

编辑完成后，运行以下命令之一来应用映射：

```bash
# 使用批处理脚本
apply_arb_mapping.bat

# 或使用PowerShell脚本
.\apply_arb_mapping.ps1

# 或直接运行Python脚本
python apply_arb_mapping.py
```

这将根据您编辑的YAML文件更新ARB文件和代码引用。

### 4. 验证更改

应用映射后，请验证：

- ARB文件中的键是否按预期更新
- 代码中的键引用是否正确更新
- 运行应用程序以检查本地化是否正常工作

## YAML文件结构解析

生成的YAML文件包含几个主要部分：

### 分析摘要

提供关于键的总体统计信息：

```yaml
# === 分析摘要 ===
# 总键数: 1178
# 具有相同值的键: 227
# 具有相似语义的键: 16802
# 常见前缀: character(302), work(229)...
```

### 按语义类别分组的键

将键按功能和语义类别分组：

```yaml
# === 按语义类别分组的键 ===
# --- BUTTON (40 键) ---
```

### 前缀分析与标准化建议

分析常见前缀并提供标准化建议：

```yaml
# === 前缀分析与标准化建议 ===
# --- character 前缀 (302 键) ---
# characterDetailAddTag: 添加标签 -> 建议: 'addTag'
```

### 语义分析与合并建议

识别具有相似语义的键并提供合并建议：

```yaml
# === 语义分析与合并建议 ===
# --- 相似含义: 'add' ---
# addTag: 添加标签
# addCategory: 添加分类
# 建议合并为: 'add'
```

## 最佳实践

1. **循序渐进**：不要一次性合并所有键，可以分阶段进行
2. **保持一致性**：为类似功能的键使用一致的命名方式
3. **谨慎删除前缀**：确保删除前缀不会导致键名冲突
4. **备份原始文件**：脚本会自动创建备份，但额外的备份也是好的做法
5. **验证每次更改**：每次应用更改后运行应用程序进行验证

## 注意事项

- 这个工具会自动创建ARB文件的备份
- 应用更改将会修改代码中的键引用，确保在版本控制系统中进行操作
- 如果遇到问题，可以从备份中恢复

## 高级用法

如果您需要进一步定制优化过程，可以修改以下文件中的常量和函数：

- `super_enhanced_arb_mapping.py`: 修改语义分类、前缀检测等算法
- `apply_arb_mapping.py`: 修改代码引用更新的模式匹配逻辑

祝您ARB优化成功！
