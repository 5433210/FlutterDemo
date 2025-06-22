# ARB优化工作流程 - 包含未使用键处理

## 新增功能

现在ARB优化工具支持标记和处理未使用的键，使您能够更精确地控制ARB文件的优化过程。

## 完整工作流程

### 第一步：生成带未使用键标记的映射文件

运行以下命令生成包含未使用键标记的YAML映射文件：

```bash
# 使用批处理脚本（推荐）
generate_arb_mapping_with_unused.bat

# 或直接运行Python脚本
python enhanced_arb_mapping_with_unused.py
```

这将在 `arb_report` 目录下生成 `key_mapping.yaml` 文件，其中包含：

- **替代键** - 标记为 `# 以下键替代了其他键`
- **普通键** - 标记为 `# 以下是普通键`
- **未使用键** - 标记为 `# 以下是未使用的键 [UNUSED]`

### 第二步：编辑映射文件（可选）

打开 `arb_report/key_mapping.yaml` 文件，您可以：

1. 修改键值映射关系
2. 检查标记为 `[UNUSED]` 的键是否确实不需要
3. 移动键的分类（例如将某个键从"未使用"移到"普通"）

### 第三步：应用映射

运行以下命令应用映射：

```bash
# 使用批处理脚本（推荐，提供交互式选择）
apply_arb_mapping_with_unused.bat

# 或直接运行Python脚本
python apply_arb_mapping_with_unused.py

# 如果要删除未使用的键
python apply_arb_mapping_with_unused.py --remove-unused
```

## 批处理脚本选项

`apply_arb_mapping_with_unused.bat` 提供了交互式选择：

1. **仅应用键值映射（保留未使用的键）** - 安全选项，不会删除任何键
2. **应用键值映射并删除未使用的键** - 会删除所有标记为 [UNUSED] 的键
3. **取消** - 不执行任何操作

## 安全特性

- **自动备份**: 每次运行都会自动创建ARB文件的时间戳备份
- **确认提示**: 删除未使用键时会要求额外确认
- **代码警告**: 如果检测到代码中仍有对未使用键的引用，会显示警告

## 输出信息

应用映射后，您会看到详细的统计信息：

```
Original key count: 1178
New key count: 1020
Replaced by mapping: 50
Removed unused keys: 108
Reduced by: 158 keys (13.4%)
```

## 文件结构

```
demo/
├── enhanced_arb_mapping_with_unused.py     # 生成映射（带未使用键标记）
├── apply_arb_mapping_with_unused.py        # 应用映射（支持删除未使用键）
├── generate_arb_mapping_with_unused.bat    # 生成映射的批处理脚本
├── apply_arb_mapping_with_unused.bat       # 应用映射的批处理脚本
└── arb_report/
    ├── key_mapping.yaml                    # 主要的映射文件
    ├── unused_keys_list.txt               # 未使用键列表
    └── unused_keys.txt                    # 详细的未使用键报告
```

## 注意事项

1. **检查未使用键**: 在删除未使用键之前，请仔细检查这些键是否真的不需要
2. **代码同步**: 删除键后，确保相应的代码也被更新或删除
3. **测试验证**: 应用映射后，运行应用程序确保一切正常工作
4. **备份恢复**: 如果出现问题，可以从自动生成的备份目录恢复文件

## 与现有工具的兼容性

新工具与现有的ARB优化工具完全兼容：

- `enhanced_arb_mapping.py` - 继续可用，不包含未使用键标记
- `conservative_arb_mapping.py` - 继续可用，保守合并策略
- `apply_arb_mapping.py` - 继续可用，基本映射应用

新工具是现有工具的增强版本，提供了更多控制选项。
