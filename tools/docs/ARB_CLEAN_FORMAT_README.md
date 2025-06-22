# ARB优化脚本 - 无行内注释版

## 变更说明

我们对ARB优化脚本进行了改进，去掉了YAML文件中的行内注释，使其更符合标准YAML格式。主要变更包括：

1. **YAML格式变更**：
   - 之前：`key: value #替代了其他key的`
   - 现在：`# 以下键替代了其他键`，然后下一行是`key: value`

2. **更清晰的结构**：
   - 使用独立的注释行来标记替代键和普通键
   - 避免了可能由行内注释引起的解析问题

3. **更标准的YAML**：
   - 符合YAML标准规范
   - 更容易与其他YAML工具配合使用

## 使用方法

### 生成YAML映射

使用以下命令之一生成新格式的YAML映射文件：

```bash
# 使用批处理脚本
generate_arb_mapping_clean.bat

# 使用PowerShell脚本
.\generate_arb_mapping_clean.ps1

# 或直接运行Python脚本
python enhanced_arb_mapping.py
```

### 应用YAML映射

编辑生成的YAML文件后，使用以下命令之一应用映射：

```bash
# 使用批处理脚本
apply_arb_mapping.bat

# 使用PowerShell脚本
.\apply_arb_mapping.ps1

# 或直接运行Python脚本
python apply_arb_mapping.py
```

## 注意事项

- 新的YAML格式与旧格式不兼容，请确保使用更新后的`apply_arb_mapping.py`脚本
- 如果您有之前版本生成的YAML文件，建议重新生成以使用新格式
- 脚本会自动创建ARB文件的备份，以防需要恢复

## 新YAML格式示例

```yaml
# 以下键替代了其他键
addLayer: 添加图层
   addLayer: 添加图层
   practiceEditAddLayer: 添加图层

# 以下是普通键
backgroundColor: 背景颜色
   backgroundColor: 背景颜色
```
