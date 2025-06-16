# ARB优化与国际化工具集

本工具集提供了一套完整的解决方案，用于优化Flutter项目的ARB文件并自动化处理硬编码文本的国际化。

## 🎯 主要功能

### 1. ARB文件优化
- **重复键值检测**: 识别语义相似或完全重复的键值对
- **无用键值清理**: 查找代码中未使用的键值并清理
- **命名规范检查**: 检测命名不规范的键值（如label1, text2等）
- **自动合并优化**: 根据分析结果自动合并重复键值，删除无用键值

### 2. 硬编码文本检测
- **全面模式识别**: 支持多种UI组件和文本场景
  - Text组件、TextField提示文本、Dialog标题等
  - 枚举显示名称、错误消息、常量字符串等
- **上下文分析**: 提取文件模块、函数、类上下文信息
- **置信度评估**: 为每个检测结果提供置信度评分

### 3. 智能ARB匹配
- **相似度计算**: 基于文本内容和语义的智能匹配
- **键名建议**: 根据模块、组件类型、语义含义生成规范键名
- **翻译建议**: 提供基础的中英文翻译映射

### 4. 交互式替换
- **批量处理**: 支持按文件分组的批量确认和处理
- **代码替换**: 自动替换硬编码文本为ARB引用
- **导入管理**: 自动添加必要的本地化导入语句

## 📁 工具文件结构

```
scripts/
├── i18n_master.py              # 主控制器
├── arb_optimizer.py            # ARB文件优化器
├── hardcoded_text_detector.py  # 硬编码文本检测器
├── smart_arb_matcher.py        # 智能ARB匹配器
└── interactive_i18n_tool.py    # 交互式替换工具
```

## 🚀 快速开始

### 先决条件

1. Python 3.7+
2. Flutter项目已配置本地化 (l10n.yaml存在)
3. 安装依赖：`pip install jieba`

### 一键运行完整流程

```bash
# 运行完整的优化和国际化流程
python scripts/i18n_master.py --full
```

### 交互式模式

```bash
# 进入交互式菜单
python scripts/i18n_master.py --interactive
```

### 快速扫描

```bash
# 快速扫描项目状态
python scripts/i18n_master.py --scan
```

## 🔧 详细使用说明

### 1. ARB文件优化

```bash
# 分析ARB文件
python scripts/arb_optimizer.py --analyze

# 生成键值映射表
python scripts/arb_optimizer.py --generate-mapping

# 执行优化（会自动备份）
python scripts/arb_optimizer.py --optimize --backup
```

**输出文件:**
- `arb_analysis_report.md`: 详细分析报告
- `key_mappings.json`: 键值映射表
- `arb_backup_YYYYMMDD_HHMMSS/`: 备份目录

### 2. 硬编码文本检测

```bash
# 扫描所有硬编码文本
python scripts/hardcoded_text_detector.py --scan --json

# 指定最小置信度
python scripts/hardcoded_text_detector.py --scan --min-confidence 0.8

# 指定扫描目录
python scripts/hardcoded_text_detector.py --scan --root-dir lib/src
```

**输出文件:**
- `hardcoded_text_report.md`: 详细检测报告
- `hardcoded_text_report.json`: JSON格式数据

### 3. 智能ARB匹配

```bash
# 对检测到的硬编码文本进行匹配
python scripts/smart_arb_matcher.py --input hardcoded_text_report.json

# 指定ARB文件路径
python scripts/smart_arb_matcher.py \
  --input hardcoded_text_report.json \
  --arb-zh lib/l10n/app_zh.arb \
  --arb-en lib/l10n/app_en.arb
```

**输出文件:**
- `arb_match_report.md`: 匹配结果报告
- `arb_additions.json`: 需要新增的键值

### 4. 交互式替换

```bash
# 运行完整的交互式流程
python scripts/interactive_i18n_tool.py --full

# 仅检测阶段
python scripts/interactive_i18n_tool.py --detect-only

# 仅匹配阶段
python scripts/interactive_i18n_tool.py --match-only
```

## 📊 检测模式说明

### 支持的文本类型

| 类型 | 示例 | 优先级 |
|------|------|--------|
| `text_widget` | `Text('硬编码文本')` | 高 |
| `hint_text` | `hintText: '请输入'` | 高 |
| `title_text` | `title: Text('标题')` | 高 |
| `button_text` | `child: Text('按钮')` | 高 |
| `snackbar_content` | `content: Text('消息')` | 高 |
| `error_text` | `errorText: '错误信息'` | 中 |
| `return_string` | `return '枚举显示名';` | 中 |
| `print_statement` | `print('调试信息')` | 低 |

### 排除规则

- 生成的文件 (`.g.dart`, `.freezed.dart` 等)
- 注释中的文本
- URL和文件路径
- 过短的文本 (< 2字符)
- 包含特殊技术字符的文本

## 🎨 键名命名规范

工具自动生成的键名遵循以下格式：
```
{模块}_{组件类型}_{语义含义}
```

**示例:**
- `auth_button_login` - 认证模块的登录按钮
- `home_dialog_confirm` - 首页模块的确认对话框
- `settings_hint_password` - 设置模块的密码提示

## 📝 报告格式

### ARB分析报告
```markdown
# ARB文件分析报告

## 基本统计
- 总键值数量: 670
- 已使用键值: 580
- 未使用键值: 90
- 疑似重复键值组: 15

## 疑似重复键值
### save vs saveButton
- 中文相似度: 0.95
- 英文相似度: 0.88
```

### 硬编码检测报告
```markdown
# 硬编码文本检测报告

## 统计信息
- 检测到硬编码文本: 156 处
- 涉及文件: 23 个
- 文本类型: 8 种

## 按文件详情
### lib/pages/login_page.dart (12 处)
**第 45 行** (text_widget):
- 文本: `登录`
- 代码: `Text('登录')`
- 置信度: 1.00
```

## ⚙️ 配置选项

### 相似度阈值
- **高相似度** (>0.85): 建议直接复用
- **中相似度** (0.7-0.85): 提示用户确认
- **低相似度** (<0.7): 建议创建新键值

### 置信度等级
- **高置信度** (>0.8): 确定需要国际化的文本
- **中置信度** (0.5-0.8): 可能需要国际化的文本
- **低置信度** (<0.5): 可能是技术性文本

## 🔄 工作流程建议

### 首次使用

1. **备份项目**: 确保代码已提交到版本控制
2. **分析现状**: `python scripts/i18n_master.py --scan`
3. **ARB优化**: 先优化现有ARB文件结构
4. **硬编码处理**: 处理所有硬编码文本
5. **验证测试**: 编译和功能测试

### 持续维护

1. **定期扫描**: 每周运行快速扫描
2. **CI集成**: 将检测工具集成到CI/CD流程
3. **代码审查**: 在代码审查中关注硬编码文本
4. **培训团队**: 确保团队了解国际化最佳实践

## 🚨 注意事项

### 安全考虑
- 工具会自动备份原始文件
- 建议在独立分支中运行完整流程
- 执行前确保代码已提交

### 翻译质量
- 自动生成的英文翻译仅供参考
- 建议专业翻译员审核所有译文
- 注意文化差异和本地化适配

### 性能影响
- 大型项目扫描可能需要几分钟
- 交互式模式适合逐步处理
- 可使用置信度阈值过滤结果

## 🐛 故障排除

### 常见问题

**Q: 检测到的硬编码文本过多怎么办？**
A: 使用 `--min-confidence 0.8` 提高置信度阈值，先处理高优先级文本。

**Q: ARB优化后编译失败？**
A: 检查 `key_mappings.json` 确认键值映射正确，运行 `flutter clean` 后重新编译。

**Q: 工具建议的键名不合适？**
A: 在交互式模式中可以手动修改键名，或调整 `smart_arb_matcher.py` 中的命名规则。

**Q: 如何排除特定文件或目录？**
A: 修改 `hardcoded_text_detector.py` 中的 `exclude_files` 和 `exclude_patterns` 配置。

### 调试模式

```bash
# 启用详细输出
python scripts/hardcoded_text_detector.py --scan --verbose

# 测试单个文件
python scripts/hardcoded_text_detector.py --file lib/pages/test_page.dart
```

## 📚 扩展开发

### 添加新的检测模式

在 `hardcoded_text_detector.py` 的 `detection_patterns` 中添加正则表达式：

```python
# 新的检测模式
r'CustomWidget\s*\(\s*text\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'custom_widget_text'
```

### 自定义键名生成规则

修改 `smart_arb_matcher.py` 中的映射字典：

```python
self.module_mapping.update({
    'payment': 'pay',
    'shopping': 'shop'
})
```

### 集成CI/CD

GitHub Actions示例：

```yaml
name: I18n Check
on: [push, pull_request]
jobs:
  check-hardcoded:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v3
        with:
          python-version: '3.8'
      - name: Install dependencies
        run: pip install jieba
      - name: Check hardcoded text
        run: python scripts/i18n_master.py --scan
```

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个工具集。特别欢迎以下贡献：

- 新的文本检测模式
- 更好的翻译算法
- 性能优化
- 文档改进

## 📄 许可证

MIT License - 详见 LICENSE 文件。
