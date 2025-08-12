# Android 模拟器调试环境清理指南

## 概述

本指南提供了多种清理 Android 模拟器内部调试环境的方法，帮助解决调试过程中可能遇到的各种问题。

## 可用的清理工具

### 1. 交互式清理工具 (推荐)

```bash
# 运行交互式清理工具
scripts/android_emulator_cleaner.bat
```

### 2. 自动化清理脚本

```bash
# 批处理版本
scripts/clean_android_emulator.bat

# PowerShell 版本 (功能更丰富)
scripts/clean_android_emulator.ps1
```

### 3. PowerShell 脚本参数

```powershell
# 基本清理
./scripts/clean_android_emulator.ps1

# 指定包名清理
./scripts/clean_android_emulator.ps1 -PackageName "com.your.package"

# 强制清理（跳过确认）
./scripts/clean_android_emulator.ps1 -Force

# 清理但不重启模拟器
./scripts/clean_android_emulator.ps1 -SkipReboot
```

## 清理级别说明

### 🟢 快速清理

**适用场景**: 日常开发，构建问题
**清理内容**:

- Flutter 构建缓存
- Dart 包缓存

**使用方法**:

```bash
flutter clean
flutter pub get
```

### 🟡 标准清理

**适用场景**: 应用行为异常，数据问题
**清理内容**:

- 应用数据和缓存
- Flutter 构建缓存
- Gradle 缓存

**使用方法**:

```bash
# 使用交互式工具选择 "标准清理"
scripts/android_emulator_cleaner.bat
```

### 🔴 深度清理

**适用场景**: 严重的调试问题，模拟器状态异常
**清理内容**:

- 完全卸载应用
- 清理所有缓存
- 清理模拟器临时文件
- 重启模拟器

**注意**: 此操作会重启模拟器，请确保保存工作进度

## 手动清理步骤

### 1. 应用层面清理

```bash
# 查看已安装的应用
adb shell pm list packages | grep com.example.demo

# 清理应用数据
adb shell pm clear com.example.demo

# 完全卸载应用
adb uninstall com.example.demo
```

### 2. 系统层面清理

```bash
# 清理临时文件
adb shell rm -rf /data/local/tmp/*

# 清理应用私有目录
adb shell rm -rf /sdcard/Android/data/com.example.demo

# 清理下载文件夹中的安装包
adb shell rm -rf /sdcard/Download/*.apk
```

### 3. 开发环境清理

```bash
# Flutter 项目清理
flutter clean
flutter pub get

# Android Gradle 清理
cd android
./gradlew clean
./gradlew cleanBuildCache

# 清理 Gradle 守护进程
./gradlew --stop
```

### 4. IDE 和工具清理

```bash
# 清理 VS Code 工作区缓存
# 关闭 VS Code 后删除 .vscode 文件夹中的临时文件

# 清理 Android Studio 缓存
# 在 Android Studio 中: File > Invalidate Caches and Restart
```

## 常见问题解决

### 问题 1: "App not installed" 错误

**解决方案**:

```bash
# 深度清理并重新安装
adb uninstall com.example.demo
flutter clean
flutter pub get
flutter run
```

### 问题 2: 应用数据残留

**解决方案**:

```bash
# 清理应用数据目录
adb shell pm clear com.example.demo
adb shell rm -rf /sdcard/Android/data/com.example.demo
```

### 问题 3: 构建缓存冲突

**解决方案**:

```bash
# 完全清理构建缓存
flutter clean
cd android
./gradlew clean
./gradlew cleanBuildCache
cd ..
flutter pub get
```

### 问题 4: 模拟器状态异常

**解决方案**:

```bash
# 冷启动模拟器
adb reboot
# 或从 Android Studio 中 "Cold Boot Now"
```

## 预防措施

### 1. 定期清理

- 每天结束开发时执行快速清理
- 每周执行一次标准清理
- 遇到问题时执行深度清理

### 2. 版本控制

- 不要提交 `build/` 目录
- 添加适当的 `.gitignore` 规则
- 定期同步依赖版本

### 3. 环境管理

- 使用稳定版本的 Flutter SDK
- 保持 Android SDK 工具更新
- 定期更新依赖包

## 自动化建议

### 1. Git 钩子

可以设置 Git 钩子在切换分支时自动清理：

```bash
# 在 .git/hooks/post-checkout 中添加
#!/bin/sh
flutter clean
flutter pub get
```

### 2. VS Code 任务

添加清理任务到 `.vscode/tasks.json`:

```json
{
    "label": "Android 模拟器深度清理",
    "type": "shell",
    "command": "scripts/clean_android_emulator.bat",
    "group": "build"
}
```

### 3. 定时清理

使用 Windows 任务计划程序定期执行清理脚本。

## 故障排除

### ADB 命令不可用

```bash
# 确保 Android SDK platform-tools 在 PATH 中
# 或使用完整路径
%ANDROID_HOME%/platform-tools/adb devices
```

### Flutter 命令失败

```bash
# 检查 Flutter 环境
flutter doctor -v

# 重新安装 Flutter 依赖
flutter doctor --android-licenses
```

### 权限问题

```bash
# 确保 ADB 调试权限
adb kill-server
adb start-server
```

## 总结

选择合适的清理级别：

- **日常开发**: 使用快速清理
- **遇到问题**: 使用标准清理  
- **严重问题**: 使用深度清理

推荐使用交互式清理工具 `android_emulator_cleaner.bat`，它提供了友好的界面和多种清理选项。
