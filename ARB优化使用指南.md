# ARB 文件优化使用指南

本指南将帮助您使用自动化脚本系统优化项目中的 ARB 文件，提取公共键值，合并重复键值，删除未使用的键值，并更新代码中的引用。

## 准备工作

确保您的系统已安装以下软件:

- Python 3.6+
- Flutter SDK
- Git (用于恢复备份，如果需要)

## 优化流程概述

ARB 文件优化分为以下几个步骤:

1. **分析** - 分析现有 ARB 文件，找出重复、相似和未使用的键值
2. **决策** - 根据分析结果，决定哪些键值需要合并、删除或重命名
3. **应用** - 应用这些更改到 ARB 文件，并更新代码引用
4. **验证** - 确保更改后的项目能正常编译和运行

## 使用工具

我们提供了几个脚本来帮助您完成这个过程:

### 1. 交互式 ARB 优化工具 - `interactive_arb_optimizer.py`

这是主要的优化工具，提供交互式界面引导您完成整个优化过程。

```bash
python interactive_arb_optimizer.py
```

该工具会:
- 备份现有 ARB 文件
- 分析键值使用情况
- 找出重复和相似的键值
- 生成详细的报告
- 引导您决定要保留、合并或删除的键值
- 生成优化后的 ARB 文件
- 创建键值映射文件，供后续更新代码使用

### 2. 硬编码文本检测工具 - `hardcoded_text_detector.py`

这个工具用于发现代码中硬编码的中文文本，这些文本应该被国际化。

```bash
python hardcoded_text_detector.py
```

该工具会:
- 扫描所有 Dart 文件，查找硬编码的中文文本
- 生成详细报告，包括文件位置、行号和文本内容
- 为每个硬编码文本提供建议的 ARB 键值
- 创建可直接添加到 ARB 文件的建议条目

### 3. 应用 ARB 优化工具 - `apply_arb_optimization.py`

这个工具用于将键值映射应用到代码中，更新所有引用。

```bash
python apply_arb_optimization.py
```

该工具会:
- 读取由 `interactive_arb_optimizer.py` 生成的键值映射
- 更新所有 Dart 文件中的键值引用
- 重新生成本地化文件
- 检查项目是否能成功编译

## 推荐使用流程

为获得最佳结果，建议按以下顺序使用这些工具:

1. 首先，运行 `interactive_arb_optimizer.py`，完成初步优化
   ```bash
   python interactive_arb_optimizer.py
   ```

2. 查看生成的报告，在 `arb_report` 目录中
   - `unused_keys.txt` - 未使用的键值
   - `keys_to_merge.txt` - 可合并的键值
   - `similar_keys.txt` - 相似的键值，需要进一步评估
   - `key_usage.txt` - 键值使用统计
   - `key_mapping.json` - 键值映射关系

3. 根据交互式提示，决定要进行的优化操作

4. 运行 `hardcoded_text_detector.py`，检查是否有硬编码文本需要国际化
   ```bash
   python hardcoded_text_detector.py
   ```

5. 查看 `hardcoded_text_report` 目录中的报告，如有必要，将建议的条目添加到优化后的 ARB 文件中

6. 运行 `apply_arb_optimization.py`，应用更改到代码中
   ```bash
   python apply_arb_optimization.py
   ```

7. 根据输出，解决可能出现的编译问题

## 恢复备份

如果在优化过程中遇到问题，您可以恢复备份:

```bash
# 手动恢复备份
cp arb_backup_YYYYMMDD_HHMMSS/app_zh.arb lib/l10n/
cp arb_backup_YYYYMMDD_HHMMSS/app_en.arb lib/l10n/
```

## 注意事项

- 所有脚本都会创建备份，所以您可以安全地尝试优化
- 复杂的字符串插值可能需要手动检查
- 如果有自定义的本地化逻辑，可能需要额外的处理

## 最佳实践

- 在开始优化前，确保所有代码已提交到版本控制系统
- 先在一个小的测试分支上尝试优化过程
- 对于关键应用，考虑先在测试环境中进行验证
- 优化后进行全面测试，确保所有文本正确显示

## 故障排除

如果遇到问题:

1. **错误: 找不到映射文件** - 确保先运行 `interactive_arb_optimizer.py`
2. **编译错误** - 检查 `apply_arb_optimization.py` 的输出，修复代码中的问题
3. **字符串插值问题** - 可能需要手动更新复杂的字符串插值代码

## 后续维护

完成一次优化后，建议:

1. 为开发团队建立 ARB 键值命名约定
2. 考虑在 CI 流程中添加 ARB 文件检查
3. 定期运行 `hardcoded_text_detector.py` 确保没有新增的硬编码文本
