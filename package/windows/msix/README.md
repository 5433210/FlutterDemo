# 字字珠玑 MSIX 包构建与分发指南

## 概述

本目录包含构建和分发字字珠玑 Windows MSIX 安装包的完整工具链，专门用于解决 0x800B0109 证书信任问题。

## 目录结构

```
package/windows/msix/
├── msix_config.json                # MSIX 配置文件
├── Generate_Certificate.ps1        # 证书生成脚本
├── Build_MSIX_Package.bat          # MSIX 构建脚本
├── Deploy_One_Click.bat            # 一键部署脚本
├── Manual_Sign_MSIX.bat            # 手动签名工具
├── Verify_Certificate_MSIX_Match.bat # 签名验证工具
├── Certificate_Diagnosis_Fix.bat   # 证书诊断修复工具
├── CharAsGem.cer                   # 自签名证书（公钥）
├── CharAsGem.pfx                   # 自签名证书（私钥）
└── README.md                       # 本说明文件
```

## 使用方法

### 方法一：一键部署（推荐）

1. 双击运行 `Deploy_One_Click.bat`
2. 脚本将自动完成：
   - 生成/更新自签名证书
   - 构建 MSIX 包
   - 验证签名匹配
   - 运行诊断检查
3. 构建结果将输出到 `release/windows/v版本号/` 目录

### 方法二：分步执行

1. **生成证书**：
   ```powershell
   powershell -ExecutionPolicy Bypass -File Generate_Certificate.ps1
   ```

2. **构建 MSIX 包**：
   ```batch
   Build_MSIX_Package.bat
   ```

3. **验证签名**：
   ```batch
   Verify_Certificate_MSIX_Match.bat "path\to\package.msix" "CharAsGem.cer"
   ```

4. **如需手动签名**：
   ```batch
   Manual_Sign_MSIX.bat "path\to\package.msix"
   ```

## 输出位置

- **MSIX 包**：`releases/windows/v版本号/CharAsGemInstaller_v版本号.msix`
- **证书文件**：`releases/windows/v版本号/CharAsGem.cer`
- **安装说明**：`releases/windows/v版本号/安装说明.txt`

## 安装指南

### 最终用户安装步骤

1. **安装证书**：
   - 双击 `CharAsGem.cer`
   - 选择"安装证书"
   - 选择"本地计算机"
   - 选择"将所有的证书都放入下列存储"
   - 浏览选择"受信任的根证书颁发机构"
   - 完成安装

2. **安装应用**：
   - 双击 `CharAsGemInstaller_v版本号.msix`
   - 按提示完成安装

### 故障排除

如果遇到 0x800B0109 错误：

1. 运行 `Certificate_Diagnosis_Fix.bat` 进行诊断
2. 以管理员身份运行：
   ```cmd
   certutil -addstore -f "ROOT" "CharAsGem.cer"
   ```
3. 重启计算机后重新安装

## 技术说明

### 证书生成

- 使用 PowerShell 的 `New-SelfSignedCertificate` 生成自签名证书
- 证书有效期：3年
- 密钥长度：RSA 2048位
- 用途：代码签名

### 签名验证

- 比较 MSIX 包签名指纹与证书指纹
- 确保 Flutter msix 插件正确使用了指定证书
- 支持手动重新签名

### 自动化特性

- 自动读取版本信息并更新配置
- 自动创建版本化的输出目录
- 自动验证证书与 MSIX 签名匹配
- 失败时自动尝试修复

## 依赖要求

- Windows 10/11
- PowerShell 5.0+
- Flutter SDK
- Windows SDK（用于 signtool.exe）
- Visual Studio 或 Build Tools

## 注意事项

1. 确保项目已正确配置 Flutter 环境
2. 首次使用时会自动生成新的证书和 GUID
3. 每次构建都会验证证书与 MSIX 签名的匹配性
4. 建议在分发前运行完整的诊断检查

## 版本管理

版本信息从项目根目录的 `version.json` 读取，构建脚本会自动：
- 更新 msix_config.json 的版本字段
- 创建对应版本的输出目录
- 生成版本化的 MSIX 文件名

## 支持

如遇问题，请检查：
1. Flutter 环境是否正确配置
2. Windows SDK 是否已安装
3. PowerShell 执行策略是否允许脚本运行
4. 是否有足够的系统权限
