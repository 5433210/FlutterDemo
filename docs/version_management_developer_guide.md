# 版本管理开发者使用指南

## 概述

本指南介绍如何在日常开发中使用版本管理系统，包括版本信息查看、版本更新、构建号管理等操作。

## 快速开始

### 1. 环境准备

确保您的开发环境已安装：
- Python 3.9+
- Flutter SDK
- Git

### 2. 安装Git钩子

```bash
# 安装版本管理Git钩子
bash hooks/install-hooks.sh
```

### 3. 生成初始版本信息

```bash
# 生成所有平台的版本信息
python scripts/generate_version_info.py
```

## 日常开发工作流

### 版本信息查看

#### 命令行方式
```bash
# 查看当前版本信息
python scripts/generate_version_info.py --info

# 查看构建历史
python scripts/update_build_number.py --history
```

#### VS Code方式
- 使用 `Ctrl+Shift+P` 打开命令面板
- 输入 `Tasks: Run Task`
- 选择 `查看版本信息`

### 版本更新操作

#### 1. 递增版本号

```bash
# 递增修订版本 (1.0.0 -> 1.0.1)
python scripts/generate_version_info.py --increment patch

# 递增次版本 (1.0.0 -> 1.1.0)  
python scripts/generate_version_info.py --increment minor

# 递增主版本 (1.0.0 -> 2.0.0)
python scripts/generate_version_info.py --increment major
```

#### 2. 手动设置版本

```bash
# 设置特定版本号
python scripts/generate_version_info.py --set-version 1.2.3

# 设置预发布版本
python scripts/generate_version_info.py --set-version 1.2.3 --prerelease beta
```

#### 3. 构建号管理

```bash
# 递增构建号
python scripts/update_build_number.py --strategy increment

# 使用时间戳构建号
python scripts/update_build_number.py --strategy timestamp

# 手动设置构建号
python scripts/update_build_number.py --build-number 20250623001
```

### 版本检查和验证

#### 版本一致性检查
```bash
# 检查所有平台版本信息一致性
python scripts/check_version_consistency.py

# 静默模式检查（仅显示错误）
python scripts/check_version_consistency.py --quiet
```

## VS Code集成使用

### 可用任务列表

在VS Code中按 `Ctrl+Shift+P`，输入 `Tasks: Run Task`，可以看到以下版本管理任务：

#### 版本信息管理
- **版本信息生成** - 生成所有平台的版本信息
- **版本一致性检查** - 检查各平台版本信息一致性
- **查看版本信息** - 显示当前版本信息详情

#### 版本更新
- **版本递增 - Patch** - 递增修订版本号
- **版本递增 - Minor** - 递增次版本号  
- **版本递增 - Major** - 递增主版本号
- **更新构建号** - 递增构建号并更新所有平台

#### 开发工具
- **构建历史查看** - 查看构建历史记录
- **安装Git钩子** - 安装版本管理Git钩子
- **多平台构建测试** - 测试多个平台的构建是否正常

### 任务快捷键

您可以在 VS Code 中为常用任务设置快捷键：

1. 打开 `File > Preferences > Keyboard Shortcuts`
2. 搜索 `Tasks: Run Task`
3. 设置快捷键，例如 `Ctrl+Alt+V`

## Git钩子使用

### Pre-commit钩子

每次提交时自动运行：
- 版本相关文件变更检查
- 版本一致性验证
- 硬编码版本号检查
- Flutter代码分析

### Pre-push钩子

每次推送时自动运行：
- 版本一致性检查
- 版本信息最新性验证
- 保护分支额外检查（代码分析、构建测试）
- 版本标签检查

### 跳过钩子检查

如需跳过钩子检查，可使用 `--no-verify` 参数：

```bash
# 跳过pre-commit检查
git commit --no-verify -m "紧急修复"

# 跳过pre-push检查
git push --no-verify
```

## 版本信息文件说明

### version.json

主要的版本信息文件，包含：

```json
{
  "version": {
    "major": 1,
    "minor": 0,
    "patch": 1,
    "build": "20250623001",
    "prerelease": ""
  },
  "git": {
    "commit": "7ec3784b",
    "branch": "main",
    "tag": null,
    "is_dirty": false
  },
  "build_time": "2025-06-23T02:15:16",
  "platforms": {
    "android": { "versionName": "1.0.1", "versionCode": 20250623001 },
    "ios": { "CFBundleShortVersionString": "1.0.1", "CFBundleVersion": "20250623001" },
    "ohos": { "versionName": "1.0.1", "versionCode": 20250623001 },
    "web": { "version": "1.0.1", "version_name": "1.0.1-20250623001" },
    "windows": { "FileVersion": "1.0.1.20250623001", "ProductVersion": "1.0.1.20250623001" },
    "macos": { "CFBundleShortVersionString": "1.0.1", "CFBundleVersion": "20250623001" },
    "linux": { "APP_VERSION_STRING": "1.0.1-20250623001" }
  }
}
```

### version.yaml

YAML格式的版本配置文件：

```yaml
version:
  major: 1
  minor: 0
  patch: 1
  build: "20250623001"
  prerelease: ""
```

### build_history.json

构建历史记录文件，跟踪所有构建号变更。

## 代码中使用版本信息

### 初始化版本配置

```dart
import 'package:demo/lib/version_config.dart';

void main() async {
  // 初始化版本配置
  await VersionConfig.initialize();
  
  runApp(MyApp());
}
```

### 获取版本信息

```dart
// 获取版本信息
final versionInfo = VersionConfig.versionInfo;

// 显示版本
Text('版本: ${versionInfo.fullVersion}');
Text('构建号: ${versionInfo.buildNumber}');
Text('Git提交: ${versionInfo.gitCommit}');

// 检查版本类型
if (versionInfo.isPrerelease) {
  Text('预发布版本');
}

if (versionInfo.isDev) {
  Text('开发版本');
}
```

### 版本比较

```dart
// 比较版本
final currentVersion = VersionConfig.versionInfo;
final remoteVersion = // 从服务器获取的版本信息

if (VersionConfig.needsUpdate(currentVersion, remoteVersion)) {
  // 显示更新提示
}
```

## 发布流程

### 1. 准备发布

```bash
# 1. 确保所有更改已提交
git status

# 2. 更新版本号
python scripts/generate_version_info.py --increment minor

# 3. 检查版本一致性
python scripts/check_version_consistency.py

# 4. 测试构建
flutter build apk --debug
flutter build web
```

### 2. 创建发布提交

```bash
# 提交版本更新
git add .
git commit -m "chore: 发布版本 v1.1.0"

# 创建版本标签
git tag v1.1.0
git push origin v1.1.0
```

### 3. GitHub Actions自动化

推送到主分支后，GitHub Actions会自动：
- 运行版本检查
- 执行多平台构建测试
- 更新构建号
- 生成构建产物

## 故障排除

### 常见问题

#### 1. 版本一致性检查失败

**问题**: `版本一致性检查失败`

**解决方案**:
```bash
# 重新生成版本信息
python scripts/generate_version_info.py

# 检查具体错误
python scripts/check_version_consistency.py
```

#### 2. Git钩子执行失败

**问题**: `pre-commit hook failed`

**解决方案**:
```bash
# 检查钩子权限
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push

# 重新安装钩子
bash hooks/install-hooks.sh
```

#### 3. Python脚本找不到

**问题**: `python: command not found`

**解决方案**:
- Windows: 确保Python已添加到PATH环境变量
- macOS/Linux: 使用 `python3` 命令或创建别名

#### 4. 构建号冲突

**问题**: 构建号重复或不正确

**解决方案**:
```bash
# 查看构建历史
python scripts/update_build_number.py --history

# 手动设置新的构建号
python scripts/update_build_number.py --build-number 20250623002
```

### 调试技巧

#### 1. 启用详细输出

```bash
# 使用--verbose参数获取详细信息
python scripts/generate_version_info.py --verbose
```

#### 2. 检查版本信息快照

Git钩子会在 `.git/version_snapshot.json` 生成版本快照，用于调试。

#### 3. 手动验证平台配置

```bash
# 检查Android配置
cat android/app/build.gradle.kts | grep version

# 检查iOS配置  
cat ios/Runner/Info.plist | grep -A1 CFBundleVersion

# 检查Web配置
cat web/manifest.json | grep version
```

## 最佳实践

### 1. 版本号管理

- **主版本号**: 重大功能更新或不兼容变更
- **次版本号**: 新功能添加，向后兼容
- **修订版本号**: 错误修复和小改进
- **构建号**: 每次构建自动递增

### 2. 提交规范

使用语义化提交消息：

```bash
# 功能更新
git commit -m "feat: 添加用户登录功能"

# 错误修复
git commit -m "fix: 修复登录页面崩溃问题"

# 版本发布
git commit -m "chore: 发布版本 v1.2.0"
```

### 3. 分支管理

- `main`: 稳定发布分支
- `develop`: 开发集成分支
- `feature/*`: 功能开发分支
- `hotfix/*`: 紧急修复分支

### 4. 自动化程度

- 开发阶段：自动递增构建号
- 测试阶段：手动控制版本号
- 发布阶段：严格的版本检查和验证

## 团队协作

### 新成员入门

1. 克隆仓库后立即运行：
   ```bash
   bash hooks/install-hooks.sh
   python scripts/generate_version_info.py
   ```

2. 在VS Code中配置任务快捷键

3. 熟悉版本更新工作流

### 版本发布责任人

- 负责版本号规划和发布时机
- 确保版本一致性和质量
- 维护版本发布文档

### 代码审查检查点

- [ ] 版本相关文件是否同步更新
- [ ] 是否使用了硬编码版本号
- [ ] 版本信息是否正确显示
- [ ] Git钩子是否正常工作

---

*最后更新：2025年6月23日*
*版本：1.0.0* 