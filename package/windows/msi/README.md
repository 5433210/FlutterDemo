# 字字珠玑 MSI 安装包构建指南

## 概述

本目录包含用于构建字字珠玑 Windows MSI 安装包的脚本和配置文件。MSI 格式提供了传统的 Windows 安装体验，兼容性更好，适合企业环境和不支持 MSIX 的系统。

## 目录结构

```
package/windows/msi/
├── setup.iss                    # Inno Setup 脚本文件
├── Build_MSI_Package.bat        # MSI 构建脚本
├── Sign_MSI_Package.bat         # MSI 签名脚本
├── Verify_MSI_Package.bat       # MSI 验证脚本
├── license.txt                  # 软件许可协议
├── readme.txt                   # 安装前说明
└── README.md                    # 本文档
```

## 前置要求

### 必需软件

1. **Inno Setup 6**
   - 下载地址: https://jrsoftware.org/isdl.php
   - 安装到默认路径: `C:\Program Files (x86)\Inno Setup 6`

2. **Flutter SDK**
   - 确保已配置 Flutter 环境
   - 能够执行 `flutter build windows --release`

3. **Windows SDK** (用于代码签名)
   - 包含 SignTool.exe
   - 随 Visual Studio 或独立安装

### 可选软件

1. **7-Zip** (用于包内容验证)
2. **PowerShell** (用于高级验证功能)

## 构建流程

### 方法一：使用自动化脚本 (推荐)

#### 1. 基础构建
```bash
# 双击运行或在命令行执行
Build_MSI_Package.bat
```

#### 2. 构建 + 签名
```bash
# 先构建
Build_MSI_Package.bat

# 再签名
Sign_MSI_Package.bat
```

#### 3. 验证构建结果
```bash
Verify_MSI_Package.bat
```

#### 4. 一键构建所有包 (MSIX + MSI)
```bash
# 从项目根目录运行
package\windows\Build_All_Packages.bat
```

### 方法二：手动构建

#### 1. 准备构建环境
```bash
cd /d "C:\path\to\your\project"
flutter clean
flutter pub get
flutter build windows --release
```

#### 2. 运行 Inno Setup 编译
```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" package\windows\msi\setup.iss
```

#### 3. 验证输出
检查 `releases\windows\v1.0.1\` 目录中的生成文件。

## 输出文件

构建成功后，在 `releases\windows\v1.0.1\` 目录中会生成：

- `CharAsGemInstaller_v1.0.1.exe` - MSI 安装包 (未签名)
- `CharAsGemInstaller_Signed_v1.0.1.exe` - MSI 安装包 (已签名，如果执行了签名)
- `CharAsGem.cer` - 数字证书文件 (如果执行了签名)
- `安装说明_完整版.txt` - 安装说明文档
- `版本信息.txt` - 构建信息和校验码

## 配置说明

### setup.iss 关键配置

```ini
[Setup]
AppName=字字珠玑                    # 应用程序名称
AppVersion=1.0.1                   # 版本号
AppPublisher=大力出奇迹              # 发布者
DefaultDirName={autopf}\CharAsGem  # 默认安装路径
OutputDir=releases\windows\v1.0.1  # 输出目录
```

### 包含的文件类型

- **主程序**: `charasgem.exe` 和相关 DLL
- **应用数据**: `data` 目录下的所有文件
- **字体资源**: `assets\fonts` 目录
- **图像资源**: `assets\images` 目录

### 安装特性

- **文件关联**: 自动关联 `.csg` 文件格式
- **开始菜单**: 创建程序组和快捷方式
- **桌面图标**: 可选创建桌面快捷方式
- **注册表**: 写入应用程序信息
- **卸载支持**: 完整的卸载功能

## 自定义配置

### 修改版本信息

1. 编辑 `setup.iss` 中的 `AppVersion` 字段
2. 更新 `OutputBaseFilename` 以匹配新版本
3. 如需要，修改 `OutputDir` 路径

### 添加额外文件

在 `[Files]` 部分添加新的 `Source` 条目：

```ini
Source: "path\to\your\file"; DestDir: "{app}\subfolder"; Flags: ignoreversion
```

### 修改安装行为

在 `[Setup]` 部分调整：

- `PrivilegesRequired`: 权限要求 (admin/lowest)
- `MinVersion`: 最低系统版本
- `ArchitecturesAllowed`: 支持的架构

## 故障排除

### 常见问题

#### 1. Inno Setup 未找到
```
错误: 未找到 Inno Setup，请先安装 Inno Setup 6
```
**解决方案**: 从官网下载并安装 Inno Setup 6

#### 2. Flutter 构建文件缺失
```
警告: 未找到 Windows 构建文件
```
**解决方案**: 运行 `flutter build windows --release`

#### 3. 权限不足
```
错误: 无法写入输出目录
```
**解决方案**: 以管理员身份运行构建脚本

#### 4. 签名失败
```
签名失败 (错误码: 1)
```
**解决方案**: 
- 检查证书文件是否存在
- 验证证书密码
- 确保 SignTool 可访问

### 调试技巧

1. **启用详细输出**: 编辑脚本移除 `/Q` 参数
2. **检查构建日志**: 查看命令行输出
3. **验证源文件**: 确保所有引用的文件存在
4. **测试权限**: 以管理员身份运行

## 高级功能

### 批量构建

使用 `Build_All_Packages.bat` 可以：
- 同时构建 MSIX 和 MSI 包
- 自动签名两种格式
- 生成完整的发布包

### 自动化集成

可以将构建脚本集成到 CI/CD 流程：

```yaml
# GitHub Actions 示例
- name: Build MSI Package
  run: package\windows\msi\Build_MSI_Package.bat
  shell: cmd
```

### 企业部署

MSI 包支持：
- GPO (组策略对象) 部署
- SCCM (System Center Configuration Manager) 分发
- 静默安装: `CharAsGemInstaller_v1.0.1.exe /SILENT`
- 无人值守安装: `CharAsGemInstaller_v1.0.1.exe /VERYSILENT`

## 安全和签名

### 代码签名的重要性

1. **用户信任**: 避免 Windows Defender 警告
2. **企业要求**: 许多企业只允许已签名的软件
3. **分发渠道**: 某些分发平台要求代码签名

### 获取商业证书

为了生产环境部署，建议获取商业代码签名证书：

- **证书颁发机构**: DigiCert, GlobalSign, Sectigo 等
- **类型**: 标准代码签名证书或 EV 代码签名证书
- **成本**: 通常每年 $200-800 USD

### 使用自签名证书 (开发/测试)

当前配置使用自签名证书，适合：
- 内部开发和测试
- 受控环境部署
- 概念验证

## 版本管理

### 版本号策略

建议使用语义化版本控制 (SemVer):
- `MAJOR.MINOR.PATCH`
- 例如: `1.0.1` -> `1.0.2` (补丁更新)

### 发布目录结构

```
releases/windows/
├── v1.0.1/
│   ├── CharAsGemInstaller_v1.0.1.exe
│   ├── CharAsGemInstaller_Signed_v1.0.1.exe
│   ├── CharAsGem.cer
│   └── 安装说明_完整版.txt
├── v1.0.2/
│   └── ...
└── latest/  # 符号链接到最新版本
```

## 支持和反馈

如果在构建过程中遇到问题，请：

1. 检查本文档的故障排除部分
2. 验证前置要求是否满足
3. 查看构建脚本的详细输出
4. 查阅 Inno Setup 官方文档

---

**最后更新**: 2025-01-XX  
**维护者**: 字字珠玑开发团队
