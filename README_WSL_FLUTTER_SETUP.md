# Flutter WSL Linux构建完整指南

## ✅ 快速开始（推荐方法）

Flutter WSL环境已成功搭建完成，可以直接使用：

```powershell
# 最简单的构建方法
wsl -d Ubuntu -e "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_ubuntu_wsl_simple.sh"
```

## 🔧 环境状态

- ✅ Flutter 3.19.6 已安装在 `/home/wailik/development/flutter/`
- ✅ 构建脚本已配置并可用
- ⚠️ 注意：存在Dart SDK版本兼容性问题（项目需要>=3.4.0，当前3.3.4）

## 📋 可用的构建方法

### 方法1：直接运行简化脚本（推荐）
```powershell
wsl -d Ubuntu -e "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_ubuntu_wsl_simple.sh"
```

### 方法2：使用双击启动器
双击根目录的 `build_linux.cmd`

### 方法3：使用PowerShell工具
```powershell
.\scripts\build_linux.ps1 build
```

### 方法4：使用批处理
```cmd
.\scripts\build_linux.bat build
```

## 🐛 版本兼容性问题解决

当前遇到依赖版本问题，可选择以下解决方案：

### 方案1：升级Flutter（推荐）
```bash
wsl -d Ubuntu -e bash -c "/home/wailik/development/flutter/bin/flutter upgrade"
```

### 方案2：降级http包版本
修改 `pubspec.yaml` 中的http包版本要求

## 网络问题的解决方案（备用）

如果在WSL中直接下载Flutter遇到网络问题，可以使用以下离线安装方法：

### 方法1: Windows下载 + WSL安装

1. **在Windows中下载Flutter**
   ```powershell
   # 在PowerShell中运行
   Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz" -OutFile "flutter_linux.tar.xz"
   ```

2. **移动到项目目录并解压到WSL**
   ```powershell
   # 移动文件到项目目录
   Move-Item flutter_linux.tar.xz C:\Users\wailik\Documents\Code\Flutter\demo\demo\
   
   # 在WSL中解压
   wsl -d Ubuntu -e bash -c "
   cd /mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo
   mkdir -p ~/development
   cp flutter_linux.tar.xz ~/development/
   cd ~/development
   tar xf flutter_linux.tar.xz
   rm flutter_linux.tar.xz
   chmod +x ~/development/flutter/bin/flutter
   echo 'export PATH=\"\$PATH:\$HOME/development/flutter/bin\"' >> ~/.bashrc
   "
   ```

### 方法2: 使用本地Flutter副本

如果Windows上已有Flutter安装：

```powershell
# 复制Flutter到WSL
wsl -d Ubuntu -e bash -c "
mkdir -p ~/development
cp -r /mnt/c/src/flutter ~/development/
chmod +x ~/development/flutter/bin/flutter
echo 'export PATH=\"\$PATH:\$HOME/development/flutter/bin\"' >> ~/.bashrc
"
```

### 方法3: 手动验证安装

```bash
# 在WSL中验证安装
wsl -d Ubuntu -e bash -c "
source ~/.bashrc
flutter --version
flutter config --enable-linux-desktop
flutter doctor
"
```

## 快速自动化脚本

创建 `setup_flutter_offline.ps1`：

```powershell
Write-Host "🚀 Flutter WSL 离线设置" -ForegroundColor Green

# 检查Flutter文件是否已下载
$flutterFile = "flutter_linux.tar.xz"
if (-not (Test-Path $flutterFile)) {
    Write-Host "📥 下载Flutter Linux版本..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz" -OutFile $flutterFile
        Write-Host "✅ Flutter下载完成" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ 下载失败，请手动下载Flutter" -ForegroundColor Red
        Write-Host "下载地址: https://docs.flutter.dev/get-started/install/linux" -ForegroundColor Yellow
        exit 1
    }
}

# 在WSL中安装
Write-Host "🐧 在WSL中安装Flutter..." -ForegroundColor Yellow
wsl -d Ubuntu -e bash -c "
echo '🏠 创建开发目录...'
mkdir -p ~/development

echo '📁 复制Flutter文件...'
cp /mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/$flutterFile ~/development/

echo '📂 解压Flutter...'
cd ~/development
tar xf $flutterFile
rm $flutterFile

echo '🔧 设置权限...'
chmod +x ~/development/flutter/bin/flutter

echo '🌍 配置环境变量...'
if ! grep -q 'development/flutter/bin' ~/.bashrc; then
    echo 'export PATH=\"\$PATH:\$HOME/development/flutter/bin\"' >> ~/.bashrc
fi

echo '✅ 验证安装...'
export PATH=\"\$PATH:\$HOME/development/flutter/bin\"
~/development/flutter/bin/flutter --version

echo '🖥️ 启用Linux桌面支持...'
~/development/flutter/bin/flutter config --enable-linux-desktop

echo '🩺 运行Flutter doctor...'
~/development/flutter/bin/flutter doctor
"

Write-Host "🎉 Flutter WSL安装完成！" -ForegroundColor Green
Write-Host "💡 请重新启动WSL终端或运行 'source ~/.bashrc'" -ForegroundColor Yellow

# 清理下载文件
Remove-Item $flutterFile -ErrorAction SilentlyContinue
```

## 使用方法

1. 保存上述脚本为 `setup_flutter_offline.ps1`
2. 在PowerShell中运行：
   ```powershell
   .\setup_flutter_offline.ps1
   ```

## 故障排除

### 如果还是有问题：

1. **清理并重试**
   ```bash
   wsl -d Ubuntu -e bash -c "rm -rf ~/development/flutter"
   ```

2. **手动验证PATH**
   ```bash
   wsl -d Ubuntu -e bash -c "echo \$PATH"
   ```

3. **重新加载环境**
   ```bash
   wsl -d Ubuntu -e bash -c "source ~/.bashrc && flutter --version"
   ```

## 构建测试

安装完成后测试构建：

```powershell
.\scripts\build_linux.ps1 build
``` 