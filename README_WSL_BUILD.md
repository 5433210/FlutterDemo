# WSL Flutter Linux 构建工具

## 🚀 快速开始

### 方法1：使用根目录启动器（最简单）
双击项目根目录的 `build_linux.cmd` 文件

### 方法2：PowerShell命令
```powershell
.\scripts\build_linux.ps1
```

### 方法3：批处理文件
```cmd
scripts\build_linux.bat
```

## 📋 菜单选项说明

当运行构建工具后，会看到以下菜单：

```
=========================================
  WSL Flutter Linux Build Tool
=========================================

Available options:

  1. Setup WSL Flutter environment (first time use)
  2. Build Linux version (requires environment setup first)
  3. Show help information
  4. Exit

Please select operation (1-4):
```

### 选项说明：

- **选项1** - 设置WSL Flutter环境（首次使用必须）
  - 自动安装Ubuntu依赖包
  - 下载配置Flutter SDK
  - 启用Linux桌面支持

- **选项2** - 构建Linux版本（需要先完成选项1）
  - 清理之前的构建
  - 获取项目依赖
  - 构建Linux发布版本

- **选项3** - 显示帮助信息
  - 查看详细使用说明

- **选项4** - 退出工具

## ⚡ 使用流程

1. **首次使用**：选择选项1设置环境
2. **日常构建**：选择选项2构建Linux版本
3. **查看帮助**：选择选项3获取更多信息

## 📁 构建产物位置

成功构建后，Linux版本将位于：
```
build\linux\x64\release\bundle\
```

## 🔧 前置要求

- Windows 10/11 with WSL2
- Ubuntu WSL 已安装
- 网络连接（用于下载依赖）

## 📚 详细文档

查看完整指南：`docs/ubuntu_wsl_build_guide.md`

## ❓ 常见问题

**Q: 菜单选项没有显示？**
A: 尝试使用 `build_linux.cmd` 或重启PowerShell

**Q: Ubuntu WSL未安装？**  
A: 运行 `wsl --install -d Ubuntu`

**Q: 权限错误？**
A: 以管理员身份运行PowerShell

---
*Happy coding! 🎉* 