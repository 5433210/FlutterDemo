# Windows 桌面平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: Windows Desktop

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Visual Studio配置](#2-visual-studio配置)
- [3. Flutter Windows配置](#3-flutter-windows配置)
- [4. 项目配置](#4-项目配置)
- [5. MSIX打包配置](#5-msix打包配置)
- [6. 代码签名配置](#6-代码签名配置)
- [7. Microsoft Store配置](#7-microsoft-store配置)
- [8. 验证配置](#8-验证配置)
- [9. 常见问题](#9-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **操作系统**: Windows 10 版本1903或更高版本
- **架构**: x64, ARM64
- **内存**: 最少8GB RAM（推荐16GB）
- **存储**: 至少30GB可用空间

### 1.2 必需软件版本
- **Visual Studio**: 2022 Community 或更高版本
- **Windows SDK**: 10.0.18362.0 或更高版本
- **Flutter**: 3.13.0 或更高版本
- **Git**: 2.30 或更高版本

### 1.3 可选工具
- **Windows Terminal**: 增强的命令行体验
- **PowerShell 7**: 更好的脚本支持
- **MSIX Packaging Tool**: 应用打包工具

## 2. Visual Studio配置

### 2.1 安装 Visual Studio

1. **下载 Visual Studio 2022 Community**
   ```
   https://visualstudio.microsoft.com/downloads/
   ```

2. **安装必需的工作负载**
   ```
   - 使用C++的桌面开发
   - .NET桌面开发（可选，用于C#扩展）
   ```

3. **单个组件选择**
   ```
   - Windows 10/11 SDK (最新版本)
   - CMake工具
   - Git for Windows
   - IntelliCode
   ```

### 2.2 配置 Build Tools

```powershell
# 验证Visual Studio安装
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"

# 或通过命令行安装Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# 验证安装的组件
vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
```

### 2.3 配置环境变量

```powershell
# 设置Visual Studio环境变量
$env:VS_PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community"
$env:WINDOWS_SDK_PATH = "C:\Program Files (x86)\Windows Kits\10"

# 添加到系统PATH
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:VS_PATH\MSBuild\Current\Bin", "Machine")
```

## 3. Flutter Windows配置

### 3.1 启用Windows桌面支持

```powershell
# 检查Flutter版本
flutter --version

# 启用Windows桌面支持
flutter config --enable-windows-desktop

# 验证Windows支持
flutter devices
# 应该看到 Windows 设备
```

### 3.2 检查Windows配置

```powershell
# 检查Flutter配置
flutter doctor -v

# 检查Windows特定配置
flutter doctor --android-licenses
```

### 3.3 为现有项目添加Windows支持

```powershell
# 在项目根目录执行
flutter create --platforms windows .

# 或创建新项目
flutter create --platforms windows,web,android,ios demo_app
```

## 4. 项目配置

### 4.1 Windows目录结构

```
windows/
├── flutter/               # Flutter引擎文件
├── runner/               # 应用入口点
│   ├── CMakeLists.txt    # 构建配置
│   ├── main.cpp          # 主入口文件
│   ├── resource.h        # 资源定义
│   ├── runner.exe.manifest # 应用清单
│   ├── Runner.rc         # 资源脚本
│   └── utils.cpp         # 工具函数
├── CMakeLists.txt        # 根构建配置
└── .gitignore
```

### 4.2 配置应用信息

编辑 `windows/runner/Runner.rc`:

```rc
#include "resource.h"

#define APSTUDIO_READONLY_SYMBOLS
#include "verrsrc.h"
#undef APSTUDIO_READONLY_SYMBOLS

VS_VERSION_INFO VERSIONINFO
 FILEVERSION 1,0,0,1
 PRODUCTVERSION 1,0,0,1
 FILEFLAGSMASK 0x3fL
#ifdef _DEBUG
 FILEFLAGS 0x1L
#else
 FILEFLAGS 0x0L
#endif
 FILEOS 0x40004L
 FILETYPE 0x1L
 FILESUBTYPE 0x0L
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904B0"
        BEGIN
            VALUE "CompanyName", "Demo Company"
            VALUE "FileDescription", "Flutter Demo Desktop Application"
            VALUE "FileVersion", "1.0.0.1"
            VALUE "InternalName", "demo.exe"
            VALUE "LegalCopyright", "Copyright (C) 2025 Demo Company. All rights reserved."
            VALUE "OriginalFilename", "demo.exe"
            VALUE "ProductName", "Demo App"
            VALUE "ProductVersion", "1.0.0.1"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1200
    END
END

IDI_APP_ICON ICON "resources\\app_icon.ico"

#if defined(_DEBUG) || defined(DEBUG) || defined(DBG)
IDI_APP_ICON ICON "resources\\app_icon.ico"
#endif
```

### 4.3 配置CMakeLists.txt

编辑 `windows/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.14)
project(demo LANGUAGES CXX)

set(BINARY_NAME "demo")

# 配置输出目录
set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR}/runner)

# Flutter配置
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# 生成的插件构建规则
set(FLUTTER_EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral")

# 定义应用目标
set(FLUTTER_APPLICATION_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(PROJECT_NAME "demo")

# 添加子目录
add_subdirectory(${FLUTTER_MANAGED_DIR})
add_subdirectory(runner)
add_subdirectory(plugins)

# 配置安装
install(TARGETS ${BINARY_NAME} DESTINATION "." COMPONENT Runtime)
install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "data" COMPONENT Runtime)
install(FILES "${FLUTTER_LIBRARY}" DESTINATION "." COMPONENT Runtime)
```

### 4.4 配置应用清单

编辑 `windows/runner/runner.exe.manifest`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity version="1.0.0.0" name="demo.exe" type="win32"/>
  
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>

  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 及更高版本 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
      <!-- Windows 8.1 及更高版本 -->
      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"/>
      <!-- Windows 7 及更高版本 -->
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
    </application>
  </compatibility>

  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
</assembly>
```

## 5. MSIX打包配置

### 5.1 安装MSIX工具

```powershell
# 通过Flutter安装msix插件
flutter pub add msix

# 或手动添加到pubspec.yaml
# dependencies:
#   msix: ^3.16.7
```

### 5.2 配置MSIX设置

在 `pubspec.yaml` 中添加MSIX配置：

```yaml
msix_config:
  display_name: Demo App
  publisher_display_name: Demo Company
  identity_name: com.example.demo
  msix_version: 1.0.0.0
  description: Flutter Demo Desktop Application
  
  # 图标配置
  logo_path: assets/images/app_icon.png
  
  # 能力配置
  capabilities: 'internetClient,location,microphone,webcam'
  
  # 语言配置
  languages: zh-cn, en-us
  
  # 签名配置（可选）
  certificate_path: certificates/demo_cert.pfx
  certificate_password: your_password
  
  # Store配置
  publisher: CN=Demo Company
  store: true
```

### 5.3 创建MSIX包

```powershell
# 构建Release版本
flutter build windows --release

# 创建MSIX包
flutter pub run msix:create

# 或使用简化命令
dart run msix:create
```

### 5.4 高级MSIX配置

```yaml
msix_config:
  # 高级设置
  architecture: x64
  file_extension: .demo
  protocol_activation: demo
  start_up_task: DemoStartupTask
  
  # 自动启动配置
  auto_start: true
  
  # 更新配置
  update_blocks_activation: false
  
  # 依赖项
  dependencies: 'Microsoft.VCLibs.140.00'
```

## 6. 代码签名配置

### 6.1 生成代码签名证书

```powershell
# 生成自签名证书（测试用）
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=Demo Company" -KeyAlgorithm RSA -KeyLength 2048 -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyExportPolicy Exportable -KeyUsage DigitalSignature -CertStoreLocation Cert:\CurrentUser\My

# 导出证书
$password = ConvertTo-SecureString -String "your_password" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath "demo_cert.pfx" -Password $password

# 安装证书到受信任的根证书颁发机构
Import-Certificate -FilePath "demo_cert.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
```

### 6.2 使用证书签名

```powershell
# 使用signtool签名MSIX包
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" sign /fd SHA256 /a /f demo_cert.pfx /p your_password demo.msix

# 验证签名
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" verify /pa demo.msix
```

### 6.3 自动化签名脚本

创建 `scripts/sign_windows.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory=$true)]
    [string]$CertificatePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$MsixPath
)

# 配置签名工具路径
$SignTool = "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe"

# 执行签名
& $SignTool sign /fd SHA256 /f $CertificatePath /p $CertificatePassword $MsixPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "签名成功: $MsixPath" -ForegroundColor Green
} else {
    Write-Error "签名失败: $MsixPath"
    exit 1
}

# 验证签名
& $SignTool verify /pa $MsixPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "签名验证成功" -ForegroundColor Green
} else {
    Write-Error "签名验证失败"
    exit 1
}
```

## 7. Microsoft Store配置

### 7.1 注册开发者账号

1. **访问**: https://partner.microsoft.com/
2. **注册Microsoft合作伙伴中心账号**
3. **支付年费**: $19（个人）或 $99（公司）

### 7.2 创建应用预留

```powershell
# 在Partner Center中
# 1. 应用和游戏 -> 新建应用
# 2. 预留应用名称: Demo App
# 3. 获取应用标识信息
```

### 7.3 配置Store信息

更新 `pubspec.yaml` 中的Store配置：

```yaml
msix_config:
  # Store特定配置
  store: true
  publisher: CN=Demo Company, O=Demo Company, L=City, S=State, C=US
  
  # 从Partner Center获取的信息
  identity_name: 12345DemoCompany.DemoApp
  publisher_id: CN=12345678-1234-1234-1234-123456789012
```

### 7.4 提交应用

```powershell
# 构建Store版本
flutter build windows --release
dart run msix:create --store

# 上传到Partner Center
# 1. 在Partner Center中创建新的提交
# 2. 上传MSIX包
# 3. 填写应用信息和描述
# 4. 提交认证
```

## 8. 验证配置

### 8.1 构建测试

```powershell
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建Debug版本
flutter build windows --debug

# 构建Release版本
flutter build windows --release

# 运行应用
.\build\windows\runner\Release\demo.exe
```

### 8.2 MSIX包测试

```powershell
# 创建MSIX包
dart run msix:create

# 安装测试
Add-AppxPackage -Path .\demo.msix

# 启动已安装的应用
start shell:AppsFolder\com.example.demo_1234567890123!App

# 卸载应用
Remove-AppxPackage -Package com.example.demo_1.0.0.0_x64__1234567890123
```

### 8.3 性能测试

```powershell
# 使用性能工具包
# 1. 下载Windows Performance Toolkit
# 2. 运行性能分析
wpr -start GeneralProfile
# 运行应用并执行操作
wpr -stop demo_performance.etl

# 分析结果
wpa demo_performance.etl
```

## 9. 常见问题

### 9.1 构建问题

**问题**: "Visual Studio not found"
```powershell
# 解决方案
# 1. 确保安装了Visual Studio 2022
# 2. 安装"使用C++的桌面开发"工作负载
# 3. 重新运行 flutter doctor
```

**问题**: "Windows SDK not found"
```powershell
# 解决方案
# 1. 在Visual Studio Installer中添加Windows SDK
# 2. 或单独下载安装Windows SDK
# 3. 设置环境变量 WINDOWS_SDK_DIR
```

**问题**: "CMake not found"
```powershell
# 解决方案
# 方式一：通过Visual Studio安装CMake
# 方式二：独立安装CMake
winget install Kitware.CMake
```

### 9.2 MSIX打包问题

**问题**: "Invalid publisher name"
```yaml
# 解决方案 - 确保publisher格式正确
msix_config:
  publisher: CN=Your Company Name
```

**问题**: "Certificate not found"
```powershell
# 解决方案
# 1. 确保证书路径正确
# 2. 检查证书密码
# 3. 验证证书是否已过期
certlm.msc  # 打开证书管理器检查
```

**问题**: "App registration failed"
```powershell
# 解决方案
# 1. 以管理员身份运行PowerShell
# 2. 启用开发者模式
# Settings -> Update & Security -> For developers -> Developer mode
```

### 9.3 运行时问题

**问题**: "DLL load failed"
```powershell
# 解决方案
# 1. 安装Visual C++ Redistributable
# 2. 确保所有依赖的DLL都在应用目录中
# 3. 使用Dependency Walker检查依赖关系
```

**问题**: "Access denied errors"
```powershell
# 解决方案
# 1. 以管理员身份运行应用
# 2. 检查应用清单中的权限配置
# 3. 配置Windows Defender排除规则
```

## 相关资源

### 官方文档
- [Flutter Desktop Documentation](https://docs.flutter.dev/platform-integration/desktop)
- [Building Windows apps with Flutter](https://docs.flutter.dev/deployment/windows)
- [Microsoft Store Documentation](https://docs.microsoft.com/en-us/windows/uwp/publish/)

### 开发工具
- [Visual Studio](https://visualstudio.microsoft.com/)
- [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/)
- [MSIX Packaging Tool](https://www.microsoft.com/en-us/p/msix-packaging-tool/9n5lw3jbcxkf)

### 分发和签名
- [Code Signing for Windows](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Microsoft Partner Center](https://partner.microsoft.com/)
- [Windows App Certification Kit](https://developer.microsoft.com/en-us/windows/downloads/app-certification-kit/)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 