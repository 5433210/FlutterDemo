# 平台构建环境搭建手册

## 概述

本目录包含Flutter Demo项目在7个目标平台上的详细构建环境搭建操作手册。每个平台都提供了完整的环境配置、工具安装、项目设置、打包发布和问题排查指南。

## 支持的平台

### 移动平台

#### 📱 [Android平台](./android_build_setup.md)
- **文件**: `android_build_setup.md`
- **适用系统**: Windows, macOS, Linux
- **主要工具**: Android Studio, Android SDK, Gradle
- **输出格式**: APK, AAB
- **分发渠道**: Google Play Store, 华为应用市场, 小米应用商店等

#### 🍎 [iOS平台](./ios_build_setup.md)
- **文件**: `ios_build_setup.md`
- **适用系统**: macOS
- **主要工具**: Xcode, iOS SDK, CocoaPods
- **输出格式**: IPA
- **分发渠道**: App Store, TestFlight, Enterprise分发

#### 🔶 [鸿蒙OS平台](./harmonyos_build_setup.md)
- **文件**: `harmonyos_build_setup.md`
- **适用系统**: Windows, macOS, Linux
- **主要工具**: DevEco Studio, HarmonyOS SDK
- **输出格式**: HAP
- **分发渠道**: 华为应用市场 (AppGallery)

### 桌面平台

#### 🪟 [Windows平台](./windows_build_setup.md)
- **文件**: `windows_build_setup.md`
- **适用系统**: Windows 10+
- **主要工具**: Visual Studio, Windows SDK, MSIX
- **输出格式**: EXE, MSIX
- **分发渠道**: Microsoft Store, 直接分发

#### 🍎 [macOS平台](./macos_build_setup.md)
- **文件**: `macos_build_setup.md`
- **适用系统**: macOS
- **主要工具**: Xcode, macOS SDK, create-dmg
- **输出格式**: APP, DMG
- **分发渠道**: Mac App Store, 直接分发, 公证分发

#### 🐧 [Linux平台](./linux_build_setup.md)
- **文件**: `linux_build_setup.md`
- **适用系统**: Ubuntu, Debian, Fedora, Arch等
- **主要工具**: CMake, GTK, 多种打包工具
- **输出格式**: AppImage, Snap, Flatpak, DEB, RPM
- **分发渠道**: Snap Store, Flathub, 各发行版官方仓库

### Web平台

#### 🌐 [Web平台](./web_build_setup.md)
- **文件**: `web_build_setup.md`
- **适用系统**: Windows, macOS, Linux
- **主要工具**: Flutter Web, Chrome, Web服务器
- **输出格式**: Web应用, PWA
- **分发渠道**: Web服务器, CDN, PWA应用商店

## 手册使用说明

### 📋 选择平台手册

1. **根据目标平台选择**：选择您要部署的目标平台对应的手册
2. **按操作系统过滤**：某些平台（如iOS、macOS）仅支持特定操作系统
3. **考虑分发需求**：根据应用分发方式选择合适的打包格式

### 🛠️ 手册内容结构

每个平台手册都包含以下标准章节：

1. **环境要求**
   - 系统要求和硬件配置
   - 必需软件版本
   - 开发者账号要求

2. **工具安装**
   - IDE和开发工具安装
   - SDK和工具链配置
   - 环境变量设置

3. **项目配置**
   - 目录结构说明
   - 配置文件编辑
   - 资源文件准备

4. **构建打包**
   - 构建命令和脚本
   - 打包配置优化
   - 多格式支持

5. **签名发布**
   - 证书生成和配置
   - 签名流程
   - 应用商店发布

6. **验证测试**
   - 构建验证
   - 功能测试
   - 性能检查

7. **问题排查**
   - 常见问题列表
   - 解决方案
   - 相关资源链接

### 🚀 快速开始指南

#### 对于移动应用开发
1. 首先阅读 [Android平台手册](./android_build_setup.md)
2. 如需iOS支持，参考 [iOS平台手册](./ios_build_setup.md)
3. 考虑中国市场，查看 [鸿蒙OS平台手册](./harmonyos_build_setup.md)

#### 对于桌面应用开发
1. Windows用户参考 [Windows平台手册](./windows_build_setup.md)
2. macOS用户参考 [macOS平台手册](./macos_build_setup.md)
3. Linux用户参考 [Linux平台手册](./linux_build_setup.md)

#### 对于Web应用开发
1. 所有平台都可以参考 [Web平台手册](./web_build_setup.md)
2. 考虑PWA功能增强用户体验

## 平台支持矩阵

| 功能特性 | Android | iOS | HarmonyOS | Windows | macOS | Linux | Web |
|---------|---------|-----|-----------|---------|-------|-------|-----|
| 本地开发 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 热重载 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 官方应用商店 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| 第三方分发 | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| 代码签名 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ |
| 自动更新 | ⚠️ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| 离线功能 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**图例**: ✅ 完全支持 | ⚠️ 有限支持 | ❌ 不支持

## 开发环境建议

### 🔧 推荐开发环境组合

#### 全平台开发 (推荐)
- **主系统**: macOS (支持iOS/macOS开发)
- **虚拟机**: Windows 11 (Windows应用开发)
- **容器/云**: Linux (Linux应用构建)

#### Windows主机开发
- **主系统**: Windows 11
- **虚拟机**: Linux Ubuntu (Linux应用开发)
- **云服务**: macOS云主机 (iOS/macOS应用构建)

#### macOS主机开发
- **主系统**: macOS
- **虚拟机**: Windows 11, Linux Ubuntu
- **原生支持**: iOS, macOS, Android, Web, Linux

### 💾 存储空间规划

| 平台 | SDK大小 | 工具大小 | 构建缓存 | 总计建议 |
|------|---------|----------|----------|----------|
| Android | ~5GB | ~3GB | ~2GB | 15GB |
| iOS | ~8GB | ~15GB | ~3GB | 30GB |
| HarmonyOS | ~3GB | ~5GB | ~2GB | 15GB |
| Windows | ~2GB | ~8GB | ~2GB | 15GB |
| macOS | ~5GB | (同iOS) | ~2GB | 10GB |
| Linux | ~1GB | ~2GB | ~1GB | 5GB |
| Web | ~500MB | ~1GB | ~500MB | 3GB |

**总计建议存储**: 100GB+ (包含所有平台)

## 版本管理集成

这些构建环境手册与项目的版本管理系统紧密集成：

- 📖 参考 [版本管理设计文档](../version_management_design.md)
- 📋 查看 [版本管理任务清单](../version_management_tasks.md)
- 🔄 配合 CI/CD 流水线自动化构建

## 更新和维护

### 📅 手册更新计划
- **季度更新**: SDK版本、工具链更新
- **月度检查**: 问题反馈、解决方案优化
- **即时修正**: 重大错误、安全问题

### 🐛 问题反馈
如果您在使用手册过程中遇到问题，请：
1. 检查对应平台的"常见问题"章节
2. 确认软件版本是否匹配要求
3. 在项目仓库提交Issue，标明平台和具体问题

### 🤝 贡献指南
欢迎贡献改进建议：
1. Fork项目仓库
2. 创建功能分支
3. 提交Pull Request
4. 描述改进内容和理由

---

## 相关资源

### 官方文档
- [Flutter官方文档](https://flutter.dev/docs)
- [Flutter Desktop支持](https://flutter.dev/desktop)
- [Flutter Web支持](https://flutter.dev/web)

### 社区资源
- [Flutter中文网](https://flutter.cn/)
- [Flutter开发者社区](https://flutter.dev/community)
- [GitHub Flutter项目](https://github.com/flutter/flutter)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0*  
*适用项目: Flutter Demo 应用版本管理系统* 