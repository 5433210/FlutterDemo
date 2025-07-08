# 字字珠玑 Windows 系统兼容性安装指南

## 安装包格式选择

根据您的 Windows 系统版本，请选择合适的安装包格式：

### 🎯 MSIX 格式 (推荐 - 现代系统)

**适用系统：**
- ✅ Windows 10 版本 1709 (Build 16299) 及以上
- ✅ Windows 11 (所有版本)

**优势：**
- 现代化安装体验
- 自动更新支持
- 沙盒化安全性
- 快速安装和卸载

**安装文件：**
- `CharAsGemInstaller_Signed_v1.0.1.msix` (推荐)
- `charasgem.msix` (开发版本)

### 🛠️ MSI 格式 (标准版)

**适用系统：**
- ✅ Windows 10 (所有版本)
- ✅ Windows 11 (所有版本)

**优势：**
- 传统 Windows 安装体验
- 企业环境兼容
- GPO 部署支持
- 详细的安装选项

**安装文件：**
- `CharAsGemInstaller_v1.0.1.exe`
- `CharAsGemInstaller_Signed_v1.0.1.exe` (推荐)

### 🔧 MSI 格式 (兼容性版)

**适用系统：**
- ✅ Windows 7 SP1 (64位)
- ✅ Windows 8 (64位)
- ✅ Windows 8.1 (64位)
- ✅ Windows 10 (所有版本)
- ✅ Windows 11 (所有版本)

**优势：**
- 支持老旧系统
- 向下兼容性最好
- 针对老系统优化

**安装文件：**
- `compatibility/CharAsGemInstaller_Legacy_v1.0.1.exe`

## 系统要求详细对照表

| Windows 版本 | MSIX | MSI 标准版 | MSI 兼容版 | 推荐格式 |
|-------------|------|-----------|-----------|----------|
| Windows 7 SP1 | ❌ | ❌ | ✅ | MSI 兼容版 |
| Windows 8 | ❌ | ❌ | ✅ | MSI 兼容版 |
| Windows 8.1 | ❌ | ❌ | ✅ | MSI 兼容版 |
| Windows 10 1507-1703 | ❌ | ✅ | ✅ | MSI 标准版 |
| Windows 10 1709+ | ✅ | ✅ | ✅ | MSIX |
| Windows 11 | ✅ | ✅ | ✅ | MSIX |

## 安装方法

### 方法一：MSIX 安装 (Windows 10 1709+ / Windows 11)

1. **下载文件**：
   - `CharAsGemInstaller_Signed_v1.0.1.msix`
   - `CharAsGem.cer` (证书文件)

2. **安装证书** (首次安装需要)：
   - 双击 `CharAsGem.cer`
   - 选择 "安装证书"
   - 选择 "本地计算机"
   - 选择 "将所有的证书都放入下列存储" → "受信任的根证书颁发机构"
   - 点击 "确定" 完成证书安装

3. **安装应用程序**：
   - 双击 `CharAsGemInstaller_Signed_v1.0.1.msix`
   - 点击 "安装" 按钮
   - 安装完成后在开始菜单查找 "字字珠玑"

### 方法二：MSI 安装 (所有 Windows 版本)

#### Windows 7/8/8.1 用户：
1. **下载兼容性版本**：
   - `compatibility/CharAsGemInstaller_Legacy_v1.0.1.exe`
   - `compatibility/测试系统兼容性.bat` (可选)

2. **系统兼容性测试** (推荐)：
   - 运行 `测试系统兼容性.bat`
   - 检查系统是否满足要求

3. **安装应用程序**：
   - 右键点击 `CharAsGemInstaller_Legacy_v1.0.1.exe`
   - 选择 "以管理员身份运行"
   - 按照安装向导完成安装

#### Windows 10/11 用户：
1. **下载标准版本**：
   - `CharAsGemInstaller_Signed_v1.0.1.exe` (推荐)
   - 或 `CharAsGemInstaller_v1.0.1.exe`

2. **安装应用程序**：
   - 双击安装文件
   - 如出现安全警告，选择 "仍要运行"
   - 按照安装向导完成安装

## 故障排除

### Windows 7/8 常见问题

#### 问题：提示 "不是有效的 Win32 应用程序"
**解决方案：**
- 确保下载的是兼容性版本
- 检查系统是否为 64 位
- 运行系统兼容性测试脚本

#### 问题：安装过程中出现错误
**解决方案：**
- 确保以管理员身份运行安装程序
- 关闭杀毒软件后重试
- 检查系统是否安装了 SP1 更新

#### 问题：应用程序无法启动
**解决方案：**
- 安装 Visual C++ Redistributable for Visual Studio 2015-2019
- 下载地址：https://aka.ms/vs/16/release/vc_redist.x64.exe

### Windows 10/11 常见问题

#### 问题：MSIX 安装提示证书错误
**解决方案：**
- 确保先安装 CharAsGem.cer 证书
- 证书安装到 "受信任的根证书颁发机构"
- 重启计算机后重试

#### 问题：Windows Defender 阻止安装
**解决方案：**
- 临时关闭 Windows Defender 实时保护
- 将安装文件添加到排除列表
- 下载已签名版本

## 卸载方法

### MSIX 应用卸载：
1. 打开 "设置" → "应用"
2. 搜索 "字字珠玑"
3. 点击应用 → "卸载"

### MSI 应用卸载：
1. 打开 "控制面板" → "程序和功能"
2. 找到 "字字珠玑"
3. 右键点击 → "卸载"

## 企业部署

### 静默安装 (IT 管理员)

#### MSI 静默安装：
```cmd
# 静默安装
CharAsGemInstaller_v1.0.1.exe /SILENT

# 无人值守安装
CharAsGemInstaller_v1.0.1.exe /VERYSILENT

# 指定安装路径
CharAsGemInstaller_v1.0.1.exe /SILENT /DIR="C:\Program Files\CharAsGem"
```

#### MSIX 静默安装：
```powershell
# PowerShell 安装
Add-AppxPackage -Path "CharAsGemInstaller_Signed_v1.0.1.msix"

# 批量部署
Get-ChildItem "*.msix" | ForEach-Object { Add-AppxPackage $_.FullName }
```

### GPO 部署 (域环境)：
1. 将 MSI 文件复制到网络共享位置
2. 在组策略管理控制台中创建新的 GPO
3. 导航到 "计算机配置" → "软件设置" → "软件安装"
4. 添加新的安装包并指向 MSI 文件

## 技术支持

### 联系方式
- **项目文档**：查看项目 README.md
- **技术支持**：联系开发团队
- **问题反馈**：通过项目 Issue 系统

### 日志文件位置
- **Windows 7/8/8.1**：`%APPDATA%\CharAsGem\logs\`
- **Windows 10/11**：`%LOCALAPPDATA%\CharAsGem\logs\`

### 配置文件位置
- **Windows 7/8/8.1**：`%APPDATA%\CharAsGem\config\`
- **Windows 10/11**：`%LOCALAPPDATA%\CharAsGem\config\`

---

**版本**：v1.0.1  
**更新时间**：2025-01-XX  
**支持系统**：Windows 7 SP1+ (64位)
