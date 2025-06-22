# ARB Key Mapping Tool

## 概述 (Overview)

这个工具使ARB键值映射更加直观和易于编辑。它使用YAML格式展示所有优化后的键及其值，并标记出哪些键替代了其他键。

This tool makes ARB key mapping more intuitive and easier to edit. It displays all optimized keys and their values in YAML format, clearly indicating which keys are replacing others.

## 文件格式 (File Format)

生成的YAML文件分为两部分：

The generated YAML file is divided into two sections:

### 1. 替代其他键的键 (Keys that replace other keys)

```yaml
# Keys that replace other keys
commonButton: 确认  # Replaces: confirmButton, okButton, applyButton
  confirmButton: 确认  # Replaced by commonButton
  okButton: 确认  # Replaced by commonButton
  applyButton: 应用  # Replaced by commonButton
```

这部分显示了哪些键被用来替代其他键，以及被替代的键的原始值。

This section shows which keys are used to replace others, along with the original values of the replaced keys.

### 2. 没有替代其他键的键 (Keys that don't replace others)

```yaml
# Keys that don't replace others
appTitle: 字字珠玑
about: 关于
settings: 设置
```

这部分显示了保持不变的键值对。

This section shows keys that remain unchanged.

## 使用方法 (Usage)

### 步骤1：创建YAML映射文件 (Step 1: Create YAML mapping)

运行以下命令创建YAML映射文件：

Run the following command to create the YAML mapping file:

```batch
arb_key_mapping.bat create
```

或

Or

```python
python create_yaml_mapping.py
```

这将在`arb_report`目录下生成`key_mapping.yaml`文件。

This will generate a `key_mapping.yaml` file in the `arb_report` directory.

### 步骤2：编辑YAML文件 (Step 2: Edit the YAML file)

编辑YAML文件以：

- 修改哪些键应该替代其他键
- 调整替代关系
- 根据需要保留更多键
- 更改键值

Edit the YAML file to:

- Change which keys should replace others
- Adjust replacement relationships
- Keep more keys if needed
- Change key values

编辑时请遵循YAML格式，并保持注释格式不变。

When editing, please follow the YAML format and keep the comment format unchanged.

### 步骤3：应用更改 (Step 3: Apply changes)

运行以下命令应用您的更改：

Run the following command to apply your changes:

```batch
arb_key_mapping.bat apply
```

或

Or

```python
python apply_yaml_mapping.py
```

这将：

1. 读取您编辑的YAML文件
2. 更新`key_mapping.json`文件
3. 将更改应用到ARB文件
4. 更新您的Dart文件中的代码引用

This will:

1. Read your edited YAML file
2. Update the `key_mapping.json` file
3. Apply the changes to the ARB files
4. Update code references in your Dart files

## 提示 (Tips)

- 在应用更改前，会自动创建ARB文件的备份
- 您可以通过注释掉替代关系来保留更多原始键
- 保持YAML的缩进和格式以确保正确解析
- 应用更改后，运行`flutter analyze`检查是否有任何问题

- A backup of ARB files is automatically created before applying changes
- You can preserve more original keys by commenting out replacement relationships
- Maintain the indentation and format of the YAML to ensure correct parsing
- After applying changes, run `flutter analyze` to check for any issues

## 高级用法 (Advanced Usage)

您可以使用此工具来：

- 完全重新设计您的本地化键结构
- 基于值的含义创建新的键名
- 合并具有相似含义的键
- 标准化术语和命名约定

You can use this tool to:

- Completely redesign your localization key structure
- Create new key names based on value meanings
- Merge keys with similar meanings
- Standardize terminology and naming conventions
