# ARB 优化工具使用指南

## 工具概述

本优化工具包含两个主要组件：

1. **生成 YAML 映射文件** - 分析当前 ARB 文件并生成人类可读的 YAML 映射
2. **应用 YAML 映射** - 根据编辑后的 YAML 映射更新 ARB 文件和代码引用

这种分离的设计允许开发者在自动分析和手动优化之间找到平衡点，通过编辑 YAML 文件来精确控制键值的合并和替换。

## 使用方法

### 第一步：生成 YAML 映射文件

运行以下命令生成 YAML 映射文件：

```bash
# 使用 Python 脚本
python generate_arb_mapping.py

# 或使用批处理文件（Windows）
generate_arb_mapping.bat

# 或使用 PowerShell 脚本（Windows）
.\generate_arb_mapping.ps1
```

这将在 `arb_report` 目录下生成 `key_mapping.yaml` 文件，包含以下几个部分：

1. **替换其他键的键** - 这些键会替换其他具有相同值的键
2. **被其他键替换的键** - 这些键将被替换（被注释掉）
3. **未使用的键** - 代码中未引用的键
4. **普通键** - 不参与替换的常规键

### 第二步：编辑 YAML 映射文件

打开 `arb_report/key_mapping.yaml` 文件并根据需要编辑：

- 可以修改键的值
- 可以修改替换关系
- 可以添加注释说明原因
- 可以取消注释被替换的键，使其保留在最终结果中

YAML 文件格式示例：

```yaml
# 替换其他键的键
commonKey: 公共值  # Replaces: oldKey1, oldKey2

# 被其他键替换的键
# oldKey1: 公共值  # Replaced by commonKey
# oldKey2: 公共值  # Replaced by commonKey

# 普通键（不参与替换）
normalKey1: 正常值1
normalKey2: 正常值2
```

### 第三步：应用 YAML 映射

编辑完成后，运行以下命令应用更改：

```bash
# 使用 Python 脚本
python apply_arb_mapping.py

# 或使用批处理文件（Windows）
apply_arb_mapping.bat

# 或使用 PowerShell 脚本（Windows）
.\apply_arb_mapping.ps1
```

此操作将：

1. 备份当前 ARB 文件
2. 根据 YAML 映射更新 ARB 文件
3. 更新代码中的键引用
4. 生成优化统计信息

### 第四步：重新生成本地化文件

应用映射后，运行以下命令重新生成本地化文件：

```bash
flutter gen-l10n
```

## 优化策略建议

编辑 YAML 映射时，考虑以下策略：

1. **以值为中心** - 不要只看键名，要关注翻译值的含义
2. **设计更好的键名** - 可以创建新的语义化键名来替代现有的键
3. **保持模块化** - 使用模块前缀（如 `common_`, `ui_`, `feature_`）来组织键
4. **保持一致性** - 确保类似功能使用一致的命名模式
5. **减少冗余** - 合并含义相同或相似的键

## 高级用例

### 根据语义合并键

即使值略有不同，也可以合并语义相似的键：

```yaml
# 原始 YAML
errorMessage: 出错了，请重试  # Replaces: retryError
# retryError: 发生错误，请再试一次  # Replaced by errorMessage

# 修改后，调整值以更通用
errorMessage: 发生错误，请重试  # Replaces: retryError
```

### 创建新键替代多个旧键

可以创建全新的键来替代多个现有键：

```yaml
# 添加新键
common_button_save: 保存  # Replaces: saveButton, confirmSave, saveChanges

# 移除旧键（已注释）
# saveButton: 保存  # Replaced by common_button_save
# confirmSave: 保存  # Replaced by common_button_save
# saveChanges: 保存  # Replaced by common_button_save
```

## 故障排除

如果遇到问题：

1. 检查生成的备份文件（`arb_backup_*` 目录）
2. 运行 `flutter analyze` 检查代码错误
3. 检查 YAML 文件格式是否正确（冒号后需要空格）
4. 尝试手动修复特定问题后重新运行工具

---

## ARB Optimization Tool Guide (English Version)

## Tool Overview

This optimization tool consists of two main components:

1. **Generate YAML Mapping** - Analyzes current ARB files and generates a human-readable YAML mapping
2. **Apply YAML Mapping** - Updates ARB files and code references based on the edited YAML mapping

This separated design allows developers to find a balance between automatic analysis and manual optimization by editing the YAML file to precisely control key merging and replacement.

## Usage Instructions

### Step 1: Generate YAML Mapping File

Run the following command to generate the YAML mapping file:

```bash
# Using Python script
python generate_arb_mapping.py

# Or using batch file (Windows)
generate_arb_mapping.bat

# Or using PowerShell script (Windows)
.\generate_arb_mapping.ps1
```

This will generate a `key_mapping.yaml` file in the `arb_report` directory, containing the following sections:

1. **Keys that replace others** - These keys will replace other keys with the same values
2. **Keys that are replaced** - These keys will be replaced (commented out)
3. **Unused keys** - Keys not referenced in code
4. **Normal keys** - Regular keys not involved in replacements

### Step 2: Edit YAML Mapping File

Open the `arb_report/key_mapping.yaml` file and edit as needed:

- You can modify key values
- You can change replacement relationships
- You can add comments explaining reasons
- You can uncomment replaced keys to keep them in the final result

Example YAML file format:

```yaml
# Keys that replace others
commonKey: Common value  # Replaces: oldKey1, oldKey2

# Keys that are replaced by others
# oldKey1: Common value  # Replaced by commonKey
# oldKey2: Common value  # Replaced by commonKey

# Normal keys (not involved in replacements)
normalKey1: Normal value 1
normalKey2: Normal value 2
```

### Step 3: Apply YAML Mapping

After editing, run the following command to apply changes:

```bash
# Using Python script
python apply_arb_mapping.py

# Or using batch file (Windows)
apply_arb_mapping.bat

# Or using PowerShell script (Windows)
.\apply_arb_mapping.ps1
```

This operation will:

1. Backup current ARB files
2. Update ARB files based on YAML mapping
3. Update key references in code
4. Generate optimization statistics

### Step 4: Regenerate Localization Files

After applying the mapping, run the following command to regenerate localization files:

```bash
flutter gen-l10n
```

## Optimization Strategy Recommendations

When editing the YAML mapping, consider the following strategies:

1. **Value-Centered** - Don't just look at key names, focus on the meaning of translation values
2. **Design Better Key Names** - You can create new semantic key names to replace existing ones
3. **Stay Modular** - Use module prefixes (like `common_`, `ui_`, `feature_`) to organize keys
4. **Maintain Consistency** - Ensure similar functionality uses consistent naming patterns
5. **Reduce Redundancy** - Merge keys with identical or similar meanings

## Advanced Use Cases

### Merging Keys Based on Semantics

Even if values are slightly different, you can merge semantically similar keys:

```yaml
# Original YAML
errorMessage: Error occurred, please retry  # Replaces: retryError
# retryError: An error happened, please try again  # Replaced by errorMessage

# Modified, adjusting value to be more general
errorMessage: Error occurred, please try again  # Replaces: retryError
```

### Creating New Keys to Replace Multiple Old Keys

You can create entirely new keys to replace multiple existing ones:

```yaml
# Add new key
common_button_save: Save  # Replaces: saveButton, confirmSave, saveChanges

# Remove old keys (commented)
# saveButton: Save  # Replaced by common_button_save
# confirmSave: Save  # Replaced by common_button_save
# saveChanges: Save  # Replaced by common_button_save
```

## Troubleshooting

If you encounter issues:

1. Check generated backup files (`arb_backup_*` directory)
2. Run `flutter analyze` to check for code errors
3. Verify YAML file format is correct (space needed after colons)
4. Try manually fixing specific issues and rerun the tool
