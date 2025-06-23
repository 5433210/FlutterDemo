# Ubuntu WSL Flutter Linux构建指南

## 概述

本指南说明如何在Windows系统上使用Ubuntu WSL来构建Flutter应用的Linux版本。

## 为什么选择Ubuntu WSL

- ✅ **最受欢迎的Linux发行版** - 广泛使用，社区支持好
- ✅ **软件包管理简单** - apt包管理器易于使用
- ✅ **兼容性好** - 与大多数Linux软件兼容
- ✅ **图形支持** - WSL2在Windows 11上原生支持GUI
- ✅ **稳定可靠** - 长期支持版本稳定性高

## 前置条件

### 1. 安装Ubuntu WSL

如果还没有Ubuntu WSL，可以通过以下方式安装：

```powershell
# 安装Ubuntu (最新LTS版本)
wsl --install -d Ubuntu

# 或者从Microsoft Store安装Ubuntu 22.04 LTS
```

### 2. 检查WSL状态

```powershell
# 检查已安装的发行版
wsl --list --verbose

# 启动Ubuntu
wsl -d Ubuntu
```

## 快速开始

### 方法一：使用PowerShell脚本（推荐）

1. **运行PowerShell脚本**
   ```powershell
   .\scripts\build_linux.ps1
   ```

2. **首次使用选择选项1设置环境**
   - 自动更新Ubuntu系统
   - 安装所需的开发工具和依赖
   - 下载并配置Flutter
   - 启用Linux桌面支持

3. **后续构建选择选项2**
   - 自动构建Linux版本
   - 生成发布包

### 方法二：使用批处理文件

```cmd
scripts\build_linux.bat
```

### 方法三：直接在Ubuntu WSL中执行

1. **进入Ubuntu WSL**
   ```powershell
   wsl -d Ubuntu
   ```

2. **切换到项目目录**
   ```bash
   cd /mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo
   ```

3. **首次设置环境**
   ```bash
   chmod +x scripts/setup_ubuntu_wsl_flutter.sh
   ./scripts/setup_ubuntu_wsl_flutter.sh
   ```

4. **构建Linux版本**
   ```bash
   chmod +x scripts/build_ubuntu_wsl.sh
   ./scripts/build_ubuntu_wsl.sh
   ```

## Ubuntu WSL环境设置详解

### 自动安装的软件包

```bash
# 开发工具
curl git unzip xz-utils zip

# 构建工具  
cmake ninja-build pkg-config clang

# GTK和图形库
libgtk-3-dev libglu1-mesa libblkid-dev liblzma-dev

# Web开发（可选）
google-chrome-stable
```

### Flutter配置

设置脚本会自动：
- 下载Flutter 3.16.0稳定版
- 配置环境变量
- 启用Linux桌面支持
- 运行Flutter doctor检查

## 构建过程

### 1. 环境验证
- 检查WSL环境
- 验证Flutter安装
- 确认项目路径

### 2. 依赖管理
```bash
flutter pub get      # 获取Dart依赖
flutter gen-l10n     # 生成本地化文件
```

### 3. 清理构建
```bash
flutter clean        # 清理缓存
flutter pub get      # 重新获取依赖
```

### 4. Linux构建
```bash
flutter build linux --release
```

## 构建产物

### 构建输出位置
```
build/linux/x64/release/bundle/
├── demo                    # 主执行文件
├── lib/                    # 共享库
├── data/                   # 应用数据
│   ├── icudtl.dat
│   └── flutter_assets/     # Flutter资源
└── ...
```

### 运行应用

#### 在Ubuntu WSL中运行
```bash
cd build/linux/x64/release/bundle
./demo
```

#### 从Windows PowerShell运行
```powershell
wsl -d Ubuntu -e /mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/build/linux/x64/release/bundle/demo
```

## Ubuntu WSL图形界面支持

### Windows 11 用户
Windows 11的WSL2原生支持图形应用，无需额外配置。构建的Flutter Linux应用可以直接运行图形界面。

### Windows 10 用户
需要X11服务器支持：

1. **安装X11服务器**（如VcXsrv、Xming）
2. **配置DISPLAY环境变量**
   ```bash
   export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
   ```

## 优势对比

| 特性 | Ubuntu WSL | Arch WSL | 虚拟机 |
|------|------------|----------|--------|
| 易用性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| 包管理 | apt (简单) | pacman (灵活) | 各不相同 |
| 稳定性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 性能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 社区支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

## 故障排除

### 常见问题

1. **Ubuntu WSL未安装**
   ```powershell
   wsl --install -d Ubuntu
   ```

2. **Flutter命令未找到**
   ```bash
   source ~/.bashrc
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. **依赖包缺失**
   ```bash
   sudo apt update
   sudo apt install -y libgtk-3-dev
   ```

4. **图形界面不显示**
   - 确保Windows 11或安装X11服务器
   - 检查DISPLAY环境变量

### 调试构建

```bash
# 详细构建日志
flutter build linux --verbose

# 检查Flutter环境
flutter doctor -v

# 查看可用设备
flutter devices
```

## 最佳实践

1. **定期更新**
   ```bash
   sudo apt update && sudo apt upgrade
   flutter upgrade
   ```

2. **清理构建**
   ```bash
   flutter clean
   rm -rf build/
   ```

3. **性能优化**
   - 将项目复制到WSL文件系统以提高I/O性能
   - 配置WSL内存限制

4. **备份环境**
   ```bash
   # 导出WSL镜像
   wsl --export Ubuntu ubuntu-backup.tar
   ```

## 总结

Ubuntu WSL提供了在Windows上构建Flutter Linux应用的优秀解决方案：

- 🚀 **简单易用** - 一键设置，自动化构建
- 🔧 **功能完整** - 完整的Linux开发环境
- 🎯 **高性能** - 接近原生Linux性能
- 🖥️ **图形支持** - 支持GUI应用直接运行
- 📦 **生态丰富** - 庞大的Ubuntu软件生态

通过本指南，您可以轻松在Windows上构建高质量的Flutter Linux应用！ 