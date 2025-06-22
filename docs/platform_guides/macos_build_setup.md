# macOS 桌面平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: macOS Desktop

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Xcode和开发工具](#2-xcode和开发工具)
- [3. Flutter macOS配置](#3-flutter-macos配置)
- [4. 项目配置](#4-项目配置)
- [5. 签名和公证配置](#5-签名和公证配置)
- [6. DMG打包配置](#6-dmg打包配置)
- [7. Mac App Store配置](#7-mac-app-store配置)
- [8. 验证配置](#8-验证配置)
- [9. 常见问题](#9-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **macOS**: macOS 10.15 (Catalina) 或更高版本
- **硬件**: Intel Mac 或 Apple Silicon Mac
- **内存**: 最少8GB RAM（推荐16GB）
- **存储**: 至少50GB可用空间

### 1.2 必需软件版本
- **Xcode**: 14.0 或更高版本
- **macOS Deployment Target**: macOS 10.14 或更高版本
- **Flutter**: 3.13.0 或更高版本
- **Git**: 2.30 或更高版本

### 1.3 Apple开发者账号
- **个人/公司开发者账号**: $99/年
- **企业开发者账号**: $299/年（可选）

## 2. Xcode和开发工具

### 2.1 安装Xcode

```bash
# 方式一：通过App Store安装Xcode
# 在App Store中搜索并安装Xcode

# 方式二：通过Apple Developer Portal下载
# 访问 https://developer.apple.com/download/
```

### 2.2 Xcode Command Line Tools

```bash
# 安装命令行工具
xcode-select --install

# 验证安装
xcode-select -p
# 应该输出：/Applications/Xcode.app/Contents/Developer

# 接受许可协议
sudo xcodebuild -license accept
```

### 2.3 安装Homebrew（推荐）

```bash
# 安装Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 验证安装
brew --version

# 安装常用工具
brew install git wget curl
```

## 3. Flutter macOS配置

### 3.1 启用macOS桌面支持

```bash
# 检查Flutter版本
flutter --version

# 启用macOS桌面支持
flutter config --enable-macos-desktop

# 验证macOS支持
flutter devices
# 应该看到 macOS 设备
```

### 3.2 检查macOS配置

```bash
# 检查Flutter配置
flutter doctor -v

# 特别检查macOS配置
flutter doctor --verbose
```

### 3.3 为现有项目添加macOS支持

```bash
# 在项目根目录执行
flutter create --platforms macos .

# 或创建新项目
flutter create --platforms macos,ios,android,web demo_app
```

## 4. 项目配置

### 4.1 macOS目录结构

```
macos/
├── Flutter/                    # Flutter引擎配置
│   ├── Flutter-Debug.xcconfig
│   ├── Flutter-Release.xcconfig
│   └── GeneratedPluginRegistrant.swift
├── Runner/                     # 应用主体
│   ├── AppDelegate.swift       # 应用委托
│   ├── MainFlutterWindow.swift # 主窗口
│   ├── Assets.xcassets/        # 资源文件
│   ├── Base.lproj/            # 本地化文件
│   ├── Configs/               # 配置文件
│   ├── Info.plist             # 应用信息
│   └── *.entitlements         # 权限配置
├── Runner.xcodeproj/          # Xcode项目文件
└── Runner.xcworkspace/        # Xcode工作空间
```

### 4.2 配置应用信息

编辑 `macos/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Demo App</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string>app_icon</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Demo Company. All rights reserved.</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
```

### 4.3 配置权限

编辑 `macos/Runner/DebugProfile.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 网络访问 -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    
    <!-- 文件系统访问 -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- 相机和麦克风 -->
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    
    <!-- 禁用沙盒（开发调试用）-->
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

编辑 `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 启用沙盒（发布版本） -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- 网络访问 -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- 文件系统访问（沙盒模式下） -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- 其他必要权限 -->
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
</dict>
</plist>
```

### 4.4 配置应用图标

```bash
# 创建应用图标
# 1. 准备1024x1024的PNG图标
# 2. 使用iconutil创建icns文件
mkdir app_icon.iconset
sips -z 16 16     icon.png --out app_icon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out app_icon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out app_icon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out app_icon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out app_icon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out app_icon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out app_icon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out app_icon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out app_icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out app_icon.iconset/icon_512x512@2x.png

# 生成icns文件
iconutil -c icns app_icon.iconset

# 复制到项目
cp app_icon.icns macos/Runner/Assets.xcassets/AppIcon.appiconset/
```

## 5. 签名和公证配置

### 5.1 配置Apple开发者账号

```bash
# 在Xcode中添加Apple ID
# 1. Xcode -> Preferences -> Accounts
# 2. 添加Apple ID
# 3. 下载开发证书
# 4. 创建或下载Provisioning Profile
```

### 5.2 配置代码签名

在Xcode中配置签名：

```bash
# 1. 打开 macos/Runner.xcworkspace
# 2. 选择 Runner 项目
# 3. 选择 Runner target
# 4. 在 Signing & Capabilities 中：
#    - 勾选 "Automatically manage signing"
#    - 选择开发团队
#    - 设置 Bundle Identifier: com.example.demo
```

### 5.3 配置公证

创建 `scripts/notarize_macos.sh`:

```bash
#!/bin/bash

APP_PATH="$1"
BUNDLE_ID="com.example.demo"
APPLE_ID="your-apple-id@example.com"
APP_PASSWORD="your-app-specific-password"
TEAM_ID="YOUR_TEAM_ID"

if [ -z "$APP_PATH" ]; then
    echo "Usage: $0 <path-to-app>"
    exit 1
fi

echo "开始公证 $APP_PATH..."

# 压缩应用
ARCHIVE_PATH="${APP_PATH%.*}.zip"
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"

# 上传公证
echo "上传公证..."
xcrun notarytool submit "$ARCHIVE_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

# 检查公证状态
echo "检查公证状态..."
REQUEST_UUID=$(xcrun notarytool history --apple-id "$APPLE_ID" --password "$APP_PASSWORD" --team-id "$TEAM_ID" | head -2 | tail -1 | awk '{print $1}')

xcrun notarytool info "$REQUEST_UUID" \
    --apple-id "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --team-id "$TEAM_ID"

# 装订公证票据
echo "装订公证票据..."
xcrun stapler staple "$APP_PATH"

# 验证公证
echo "验证公证..."
xcrun stapler validate "$APP_PATH"
spctl -a -v "$APP_PATH"

echo "公证完成！"
```

### 5.4 创建App-Specific Password

```bash
# 1. 访问 https://appleid.apple.com/
# 2. 登录Apple ID
# 3. 在"安全"部分生成App专用密码
# 4. 保存密码用于公证脚本
```

## 6. DMG打包配置

### 6.1 安装create-dmg工具

```bash
# 使用Homebrew安装
brew install create-dmg

# 或手动安装
git clone https://github.com/create-dmg/create-dmg.git
cd create-dmg && make install
```

### 6.2 创建DMG打包脚本

创建 `scripts/create_dmg.sh`:

```bash
#!/bin/bash

APP_NAME="Demo App"
APP_PATH="build/macos/Build/Products/Release/Demo App.app"
DMG_NAME="Demo-App-1.0.0"
SOURCE_FOLDER="dmg_source"
BACKGROUND_IMAGE="assets/dmg_background.png"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 找不到应用 $APP_PATH"
    echo "请先运行: flutter build macos --release"
    exit 1
fi

# 创建临时文件夹
rm -rf "$SOURCE_FOLDER"
mkdir "$SOURCE_FOLDER"

# 复制应用到临时文件夹
cp -R "$APP_PATH" "$SOURCE_FOLDER/"

# 创建DMG
create-dmg \
    --volname "$APP_NAME" \
    --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon.icns" \
    --background "$BACKGROUND_IMAGE" \
    --window-pos 200 120 \
    --window-size 800 450 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 175 190 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 625 185 \
    --hdiutil-quiet \
    "$DMG_NAME.dmg" \
    "$SOURCE_FOLDER/"

# 清理临时文件
rm -rf "$SOURCE_FOLDER"

echo "DMG创建完成: $DMG_NAME.dmg"

# 签名DMG（如果有证书）
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "签名DMG..."
    codesign --sign "$SIGNING_IDENTITY" --timestamp "$DMG_NAME.dmg"
    echo "DMG签名完成"
fi
```

### 6.3 配置DMG背景图

```bash
# 创建800x450的DMG背景图
# 保存为 assets/dmg_background.png
# 图片应包含：
# - 应用图标放置区域（左侧）
# - 应用程序文件夹快捷方式区域（右侧）
# - 安装说明文字
```

## 7. Mac App Store配置

### 7.1 配置Store专用设置

编辑 `macos/Runner/Release.entitlements` 添加Store要求的权限：

```xml
<!-- Mac App Store专用权限 -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- 禁用JIT（Store要求） -->
<key>com.apple.security.cs.allow-jit</key>
<false/>

<!-- 禁用动态库加载（Store要求） -->
<key>com.apple.security.cs.allow-dyld-environment-variables</key>
<false/>

<!-- 禁用调试器附加 -->
<key>com.apple.security.cs.debugger</key>
<false/>
```

### 7.2 构建Store版本

```bash
# 构建Mac App Store版本
flutter build macos --release

# 在Xcode中配置Store签名
# 1. 打开 macos/Runner.xcworkspace
# 2. 选择 Runner target
# 3. 在 Signing & Capabilities 中选择 "Mac App Store" 证书
# 4. 确保使用正确的 Provisioning Profile
```

### 7.3 创建Store上传脚本

创建 `scripts/upload_to_store.sh`:

```bash
#!/bin/bash

APP_PATH="build/macos/Build/Products/Release/Demo App.app"
BUNDLE_ID="com.example.demo"
APPLE_ID="your-apple-id@example.com"
APP_PASSWORD="your-app-specific-password"

# 验证应用
echo "验证应用..."
xcrun altool --validate-app -f "$APP_PATH" -t macos \
    -u "$APPLE_ID" -p "$APP_PASSWORD"

if [ $? -ne 0 ]; then
    echo "应用验证失败"
    exit 1
fi

# 上传应用
echo "上传应用到App Store..."
xcrun altool --upload-app -f "$APP_PATH" -t macos \
    -u "$APPLE_ID" -p "$APP_PASSWORD"

if [ $? -eq 0 ]; then
    echo "应用上传成功！"
else
    echo "应用上传失败"
    exit 1
fi
```

## 8. 验证配置

### 8.1 构建测试

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建Debug版本
flutter build macos --debug

# 构建Release版本
flutter build macos --release

# 运行应用
open build/macos/Build/Products/Release/Demo\ App.app
```

### 8.2 签名验证

```bash
# 验证应用签名
codesign -dv --verbose=4 "build/macos/Build/Products/Release/Demo App.app"

# 验证沙盒权限
codesign -d --entitlements - "build/macos/Build/Products/Release/Demo App.app"

# 验证Gatekeeper
spctl -a -v "build/macos/Build/Products/Release/Demo App.app"
```

### 8.3 公证验证

```bash
# 检查公证状态
xcrun stapler validate "build/macos/Build/Products/Release/Demo App.app"

# 验证公证信息
spctl -a -v --raw "build/macos/Build/Products/Release/Demo App.app"
```

## 9. 常见问题

### 9.1 构建问题

**问题**: "Xcode not found"
```bash
# 解决方案
# 1. 确保已安装Xcode
# 2. 运行 xcode-select --install
# 3. 设置正确的Xcode路径
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**问题**: "CocoaPods not installed"
```bash
# 解决方案
sudo gem install cocoapods
# 或
brew install cocoapods
```

### 9.2 签名问题

**问题**: "Code signing failed"
```bash
# 解决方案
# 1. 检查Apple Developer账号状态
# 2. 更新证书和Provisioning Profile
# 3. 在Xcode中重新配置签名
# 4. 确保Bundle ID匹配
```

**问题**: "Entitlements not valid"
```bash
# 解决方案
# 1. 检查entitlements文件语法
# 2. 确保权限与应用功能匹配
# 3. 验证沙盒权限配置
```

### 9.3 公证问题

**问题**: "Notarization failed"
```bash
# 解决方案
# 1. 检查App-Specific Password是否正确
# 2. 确保应用已正确签名
# 3. 检查公证日志获取详细错误信息
xcrun notarytool log <submission-id> --apple-id <apple-id> --password <password> --team-id <team-id>
```

**问题**: "Hardened Runtime issues"
```bash
# 解决方案
# 1. 在项目设置中启用Hardened Runtime
# 2. 配置必要的Hardened Runtime异常权限
# 3. 避免使用JIT编译或动态库加载
```

### 9.4 App Store问题

**问题**: "App Store submission failed"
```bash
# 解决方案
# 1. 确保使用Mac App Store证书签名
# 2. 检查沙盒权限配置
# 3. 移除不允许的API调用
# 4. 确保Info.plist配置正确
```

## 相关资源

### 官方文档
- [Flutter macOS Documentation](https://docs.flutter.dev/platform-integration/desktop)
- [Building macOS apps with Flutter](https://docs.flutter.dev/deployment/macos)
- [Mac App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### 开发工具
- [Xcode](https://developer.apple.com/xcode/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [create-dmg](https://github.com/create-dmg/create-dmg)

### 签名和公证
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 