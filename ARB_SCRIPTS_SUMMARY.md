# ARB优化脚本总结

## 当前活跃的脚本

### Python脚本

1. **enhanced_arb_mapping.py** - 标准映射生成器
   - 生成无行内注释的YAML格式
   - 推荐用于基本优化
   - 调用方式：`generate_arb_mapping_clean.bat`

2. **enhanced_arb_mapping_with_unused.py** - 增强映射生成器（含未使用键标记）
   - 标记未使用的键为 [UNUSED]
   - 提供完整的键分类
   - 调用方式：`generate_arb_mapping_with_unused.bat`

3. **conservative_arb_mapping.py** - 保守版映射生成器
   - 更谨慎的合并策略
   - 生成`key_mapping_conservative.yaml`
   - 调用方式：`generate_conservative_mapping.bat`

4. **super_enhanced_arb_mapping.py** - 超级增强版映射生成器
   - 最积极的合并策略
   - 调用方式：`generate_super_enhanced_mapping.bat`

5. **apply_arb_mapping.py** - 基本映射应用器
   - 应用YAML映射到ARB文件和代码
   - 调用方式：`apply_arb_mapping.bat`

6. **apply_arb_mapping_with_unused.py** - 增强映射应用器（含未使用键处理）
   - 支持删除未使用的键
   - 提供安全确认选项
   - 调用方式：`apply_arb_mapping_with_unused.bat`

7. **generate_arb_mapping.py** - 原版映射生成器
   - 保留用于兼容性
   - 调用方式：`generate_arb_mapping.bat`

8. **compare_arb_mappings.py** - 映射比较工具
   - 比较不同映射版本的差异
   - 独立运行

9. **clean_arb.py** - ARB清理工具
   - 清理ARB文件的辅助工具

### 批处理和PowerShell脚本

1. **generate_arb_mapping_clean.bat/.ps1** - 推荐使用（新格式）
2. **generate_arb_mapping.bat/.ps1** - 传统格式
3. **apply_arb_mapping.bat/.ps1** - 应用映射
4. **arb_key_mapping.bat** - 多功能工具

## 工作流程

### 标准工作流程（推荐）

1. 运行 `generate_arb_mapping_clean.bat`
2. 编辑生成的 `arb_report/key_mapping.yaml`
3. 运行 `apply_arb_mapping.bat`

### 未使用键处理工作流程（新增）

1. 运行 `generate_arb_mapping_with_unused.bat`
2. 检查生成的 `arb_report/key_mapping.yaml` 中标记为 [UNUSED] 的键
3. 编辑映射文件（可选）
4. 运行 `apply_arb_mapping_with_unused.bat` 并选择是否删除未使用键

### 保守工作流程

1. 运行 `generate_conservative_mapping.bat`
2. 编辑生成的 `arb_report/key_mapping_conservative.yaml`
3. 重命名为 `key_mapping.yaml`
4. 运行 `apply_arb_mapping.bat`

## 已删除的脚本

以下脚本已被删除，因为它们是早期版本或已被更好的版本替代：

- `value_focused_arb_optimizer.py`
- `run_arb_optimizer.py`
- `quick_arb_optimizer.py`
- `optimize_arb.py`
- `interactive_arb_optimizer.py`
- `enhanced_value_based_arb_optimizer.py`
- `apply_arb_optimization.py`
- `optimize_arb.bat`
- `enhanced_arb_optimize.bat`
- `arb_tools.bat/.ps1`
- `ARB优化使用指南.md`
- `ARB优化工具使用指南.md`

## 说明

- 所有脚本都输出无行内注释的标准YAML格式
- 支持结构化注释和缩进格式
- 保持向后兼容性
- 定期备份ARB文件
