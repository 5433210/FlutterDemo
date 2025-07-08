# 字字珠玑 Windows 安装包构建和分发指南

## 概述

本项目为"字字珠玑"Flutter Windows 应用提供了完整的安装包构建和分发解决方案，支持两种主流的 Windows 安装格式：

- **MSIX**: 现代化的 Windows 应用包格式，适合 Windows 10/11
- **MSI**: 传统的 Windows 安装包格式，兼容性更广，适合企业环境

## 快速开始

### 一键构建所有安装包

```bash
# 从项目根目录运行
package\windows\Build_All_Packages.bat
```

这将构建 MSIX 和 MSI 两种格式的安装包，并提供可选的数字签名功能。

### 单独构建特定格式

#### 构建 MSIX 包
```bash
package\windows\msix\Build_MSIX_Simple.bat
```

#### 构建 MSI 包
```bash
package\windows\msi\Build_MSI_Package.bat
```

## 目录结构

```
package/windows/
├── Build_All_Packages.bat          # 一键构建所有安装包
├── msix/                           # MSIX 包相关文件
│   ├── Build_MSIX_Package.bat      # MSIX 完整构建脚本
│   ├── Build_MSIX_Simple.bat       # MSIX 简化构建脚本
│   ├── Deploy_One_Click.bat        # 一键部署脚本
│   ├── Manual_Sign_MSIX.bat        # 手动签名脚本
│   ├── Verify_Certificate_MSIX_Match.bat  # 证书验证脚本
│   ├── Certificate_Diagnosis_Fix.bat      # 证书诊断修复脚本
│   ├── Generate_Certificate.ps1           # 证书生成脚本
│   ├── CharAsGem.cer               # 自签名证书 (公钥)
│   ├── CharAsGem.pfx               # 自签名证书 (私钥)
│   ├── msix_config.json           # MSIX 配置文件
│   ├── README.md                   # MSIX 详细说明
│   └── DEPLOYMENT_REPORT.md        # 部署报告
└── msi/                            # MSI 包相关文件
    ├── Build_MSI_Package.bat       # MSI 构建脚本
    ├── Sign_MSI_Package.bat        # MSI 签名脚本
    ├── Verify_MSI_Package.bat      # MSI 验证脚本
    ├── Test_MSI_Complete.bat       # MSI 完整测试脚本
    ├── setup.iss                   # Inno Setup 配置文件
    ├── license.txt                 # 软件许可协议
    ├── readme.txt                  # 安装前说明
    └── README.md                   # MSI 详细说明

releases/windows/v1.0.1/            # 构建输出目录
├── charasgem.msix                  # MSIX 包 (未签名)
├── CharAsGemInstaller_Signed_v1.0.1.msix  # MSIX 包 (已签名)
├── CharAsGemInstaller_v1.0.1.exe   # MSI 包 (未签名)
├── CharAsGemInstaller_Signed_v1.0.1.exe   # MSI 包 (已签名)
├── CharAsGem.cer                   # 数字证书
├── 安装说明_完整版.txt              # 完整安装说明
└── 版本信息.txt                    # 构建信息和校验码
```

## 前置要求

### 必需软件

1. **Flutter SDK** (已配置)
2. **Windows SDK** (包含 SignTool.exe)
3. **Inno Setup 6** (用于 MSI 构建)
   - 下载: https://jrsoftware.org/isdl.php

### 系统要求

- Windows 10/11 (64-bit)
- 管理员权限 (用于签名和某些构建操作)
- 至少 2GB 可用磁盘空间

## 构建选项

### 交互式构建菜单

运行 `Build_All_Packages.bat` 将显示交互式菜单：

```
1. 仅构建 MSIX 包
2. 仅构建 MSI 包  
3. 构建 MSIX 和 MSI 包
4. 构建 + 签名 MSIX 和 MSI 包
5. 退出
```

### 自动化构建 (CI/CD)

对于自动化环境，可以直接调用具体脚本：

```yaml
# GitHub Actions 示例
- name: Build Windows Packages
  run: |
    package\windows\msix\Build_MSIX_Simple.bat
    package\windows\msi\Build_MSI_Package.bat
  shell: cmd
```

## 数字签名

### 自签名证书 (当前配置)

项目包含自签名证书，适用于：
- 开发和测试环境
- 内部分发
- 概念验证

证书文件位置：
- `package\windows\msix\CharAsGem.cer` (公钥)
- `package\windows\msix\CharAsGem.pfx` (私钥)

### 商业证书 (生产环境推荐)

为了生产环境分发，建议使用商业代码签名证书：

1. **获取证书**: 从 DigiCert、GlobalSign 等 CA 购买
2. **配置证书**: 替换现有的 PFX 文件
3. **更新配置**: 修改相关脚本中的证书路径

## 安装方法

### 最终用户安装

#### 方法一：MSIX 包 (推荐)

1. 双击 `CharAsGem.cer` 安装证书到"受信任的根证书颁发机构"
2. 双击 MSIX 文件进行安装
3. 在开始菜单查找"CharAsGem"

#### 方法二：MSI 包 (简化安装流程)

1. 双击 `CharAsGemInstaller_Legacy_v1.0.1.exe`
2. 接受许可协议 (无额外信息页面)
3. 选择安装选项并完成安装
4. 安装过程已优化，移除了不必要的信息页面

### 企业部署

#### GPO 部署 (MSI)
```bash
# 静默安装
CharAsGemInstaller_v1.0.1.exe /SILENT

# 无人值守安装
CharAsGemInstaller_v1.0.1.exe /VERYSILENT
```

#### PowerShell 部署 (MSIX)
```powershell
Add-AppxPackage -Path "CharAsGemInstaller_Signed_v1.0.1.msix"
```

## 验证和测试

### 构建验证

```bash
# 验证 MSIX 包
package\windows\msix\Verify_Certificate_MSIX_Match.bat

# 验证 MSI 包
package\windows\msi\Verify_MSI_Package.bat

# 完整测试
package\windows\msi\Test_MSI_Complete.bat
```

### 安装测试

1. **虚拟机测试**: 在干净的 Windows 系统中测试
2. **功能测试**: 验证应用程序所有功能正常
3. **卸载测试**: 确保完全卸载不留残留
4. **权限测试**: 测试不同用户权限下的行为

## 故障排除

### 常见问题

#### 构建失败
- 检查 Flutter 环境是否正确配置
- 确保所有前置软件已安装
- 验证文件路径和权限

#### 签名问题
- 检查证书文件是否存在
- 验证证书密码
- 确保 SignTool.exe 可访问

#### 安装失败
- 验证目标系统兼容性
- 检查用户权限
- 确认证书信任状态

### 调试模式

编辑构建脚本，移除 `/Q` (静默) 参数以查看详细输出：

```bash
# 从这样
"%INNO_SETUP_DIR%\ISCC.exe" /Q "%MSI_DIR%\setup.iss"

# 改为这样
"%INNO_SETUP_DIR%\ISCC.exe" "%MSI_DIR%\setup.iss"
```

## 版本管理

### 版本号更新

编辑以下文件中的版本号：

1. `pubspec.yaml` - Flutter 项目版本
2. `package\windows\msi\setup.iss` - MSI 包版本
3. `package\windows\msix\msix_config.json` - MSIX 包版本

### 发布流程

1. **更新版本号**: 在所有配置文件中更新
2. **构建包**: 运行构建脚本
3. **签名**: 对安装包进行数字签名
4. **测试**: 在测试环境验证
5. **发布**: 分发到目标用户

## 安全考虑

### 代码签名重要性

- **用户信任**: 避免 Windows Defender 警告
- **企业要求**: 符合企业安全策略
- **分发渠道**: 满足分发平台要求

### 证书管理

- **私钥保护**: 安全存储 PFX 文件
- **密码管理**: 使用强密码保护
- **访问控制**: 限制证书访问权限
- **定期轮换**: 定期更新证书

## 支持和文档

### 详细文档

- [MSIX 包构建指南](package/windows/msix/README.md)
- [MSI 包构建指南](package/windows/msi/README.md)
- [部署报告](package/windows/msix/DEPLOYMENT_REPORT.md)

### 技术支持

如遇问题，请：

1. 查阅相关文档和故障排除指南
2. 检查系统要求和前置条件
3. 查看构建脚本输出的详细错误信息
4. 联系开发团队获取支持

---

**维护者**: 字字珠玑开发团队  
**最后更新**: 2025-01-XX  
**版本**: v1.0.1
