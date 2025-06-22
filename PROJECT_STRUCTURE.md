# 📁 Flutter Demo 项目结构说明

本项目已经过重新整理，采用更清晰、更符合Flutter项目最佳实践的目录结构。

## 🏗️ 主要目录结构

### 📱 Flutter 核心目录
```
├── lib/                    # 主要源代码
├── test/                   # 单元测试和集成测试
├── android/                # Android平台特定代码
├── ios/                    # iOS平台特定代码
├── web/                    # Web平台特定代码
├── windows/                # Windows平台特定代码
├── macos/                  # macOS平台特定代码
├── linux/                  # Linux平台特定代码
├── assets/                 # 资源文件（图片、字体等）
```

### 📚 项目文档目录
```
├── docs/                   # 项目文档（已合并所有文档）
```

### 🛠️ 工具和管理目录
```
├── tools/                  # 开发工具集合
│   ├── scripts/           # 各种脚本文件
│   │   ├── *.py          # Python脚本（国际化、检测工具等）
│   │   ├── *.bat         # Windows批处理脚本
│   │   ├── *.ps1         # PowerShell脚本
│   │   └── *.sh          # Shell脚本
│   ├── reports/          # 各种分析报告
│   │   ├── *_report/     # 硬编码检测报告
│   │   ├── enum_*/       # 枚举分析报告
│   │   └── final_*/      # 最终报告
│   ├── backups/          # 备份文件
│   │   ├── arb_backup_*/ # ARB文件备份
│   │   └── backup_*/     # 其他备份
│   └── docs/             # 项目开发相关文档
│       └── *.md          # 设计方案、实施报告等
```

### 🔬 开发目录
```
├── development/            # 开发相关文件
│   ├── tests/             # 测试文件和样本
│   │   ├── test_*.dart   # 测试代码
│   │   └── test_*.yaml   # 测试配置
│   ├── samples/          # 示例和样本文件
│   │   ├── *.dart        # 示例代码
│   │   └── *.backup      # 备份文件
│   └── prototypes/       # 原型项目
│       └── prototype/    # 原型代码
```

### ⚙️ 配置和构建目录
```
├── scripts/               # 原有脚本目录（保持兼容性）
├── coverage/              # 代码覆盖率报告
├── build/                 # 构建输出目录
├── .dart_tool/           # Dart工具目录
├── .vscode/              # VS Code配置
├── .idea/                # IntelliJ IDEA配置
├── patches/              # 补丁文件
└── workspace/            # 工作空间目录
```

## 📋 配置文件

### 🔧 主要配置文件
- `pubspec.yaml` - Flutter项目配置
- `analysis_options.yaml` - 代码分析配置
- `l10n.yaml` - 国际化配置
- `10n.yaml` - 额外的国际化配置

### 🌐 平台配置
- `msix_config.json` - Windows MSIX包配置
- `setup.iss` - Inno Setup配置
- `devtools_options.yaml` - 开发工具配置
- `distribute_options.yaml` - 分发配置

## 🎯 整理原则

### ✅ 保留的结构
- 所有Flutter标准目录结构
- 原有的docs/和scripts/目录（doc/目录已合并到docs/）
- 重要的配置文件

### 📦 新增的管理结构
- `tools/` - 集中管理所有开发工具
- `development/` - 集中管理开发相关文件
- 按功能分类的子目录结构

### 🗑️ 清理的内容
- 删除了临时目录 `temp/`
- 删除了无用的临时文件
- 整合了分散的备份和报告文件
- 合并了 `doc/` 目录到 `docs/` 目录

## 🚀 使用指南

### 📝 脚本使用
- 国际化工具：`tools/scripts/`目录下的Python脚本
- 构建脚本：`tools/scripts/`目录下的批处理和PowerShell脚本
- 检测工具：`tools/scripts/`目录下的各种检测脚本

### 📊 报告查看
- 硬编码检测报告：`tools/reports/`
- 分析报告：`tools/reports/`目录下的各种报告

### 🔍 开发测试
- 测试代码：`development/tests/`
- 示例代码：`development/samples/`
- 原型项目：`development/prototypes/`

## 📈 优势

1. **清晰的分类**：按功能和用途明确分类
2. **易于维护**：相关文件集中管理
3. **标准兼容**：符合Flutter项目最佳实践
4. **向后兼容**：保留原有重要目录结构
5. **便于协作**：团队成员更容易找到所需文件

---

**最后更新时间**: 2025年6月22日  
**整理版本**: 1.0.0 