# iOS 平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: iOS

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Xcode安装配置](#2-xcode安装配置)
- [3. Apple开发者账号](#3-apple开发者账号)
- [4. 证书和配置文件](#4-证书和配置文件)
- [5. Flutter iOS配置](#5-flutter-ios配置)
- [6. 项目配置](#6-项目配置)
- [7. 构建配置](#7-构建配置)
- [8. App Store Connect](#8-app-store-connect)
- [9. TestFlight配置](#9-testflight配置)
- [10. 验证配置](#10-验证配置)
- [11. 常见问题](#11-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **macOS**: macOS 12.0 (Monterey) 或更高版本
- **硬件**: Intel Mac 或 Apple Silicon Mac
- **存储**: 至少100GB可用空间（包括Xcode和模拟器）

### 1.2 必需软件版本
- **Xcode**: 15.0 或更高版本
- **iOS Deployment Target**: iOS 12.0 或更高版本
- **Flutter**: 3.13.0 或更高版本
- **CocoaPods**: 1.11.0 或更高版本

### 1.3 Apple开发者账号
- **个人/公司开发者账号**: $99/年
- **企业开发者账号**: $299/年（可选）

## 2. Xcode安装配置

### 2.1 安装 Xcode

#### 方式一：通过 App Store
```bash
# 在App Store中搜索并安装Xcode
# 优点：自动更新
# 缺点：下载速度可能较慢
```

#### 方式二：通过 Apple Developer Portal
```bash
# 1. 访问 https://developer.apple.com/download/
# 2. 使用Apple ID登录
# 3. 下载Xcode .xip文件
# 4. 双击解压并安装
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

### 2.3 iOS模拟器配置

```bash
# 列出可用的模拟器
xcrun simctl list devices

# 创建新的模拟器（可选）
xcrun simctl create "iPhone 15 Pro" "iPhone 15 Pro" "iOS 17.0"

# 启动模拟器
open -a Simulator
```

## 3. Apple开发者账号

### 3.1 注册开发者账号

1. **访问**: https://developer.apple.com/
2. **使用Apple ID登录**
3. **选择账号类型**:
   - Individual（个人）
   - Organization（组织）
   - Enterprise（企业）
4. **完成支付**: $99/年（个人/组织）

### 3.2 开发团队配置

```bash
# 在Xcode中配置开发团队
# 1. 打开Xcode
# 2. Preferences -> Accounts
# 3. 添加Apple ID
# 4. 下载开发证书
```

## 4. 证书和配置文件

### 4.1 开发证书

#### 自动管理（推荐）
```bash
# 在Xcode项目设置中
# 1. 选择项目 -> Signing & Capabilities
# 2. 勾选 "Automatically manage signing"
# 3. 选择开发团队
# 4. Xcode自动创建和管理证书
```

#### 手动管理
```bash
# 1. 访问 Apple Developer Portal
# 2. Certificates, Identifiers & Profiles
# 3. 创建开发/发布证书
# 4. 下载并双击安装到钥匙串
```

### 4.2 App ID配置

在Apple Developer Portal中：

```bash
# 1. Identifiers -> App IDs
# 2. 创建新的App ID
# 3. 设置Bundle ID: com.example.demo
# 4. 配置所需的Capabilities:
#    - Push Notifications
#    - In-App Purchase
#    - Background Modes
#    - etc.
```

### 4.3 Provisioning Profiles

```bash
# 开发用Provisioning Profile
# 1. Profiles -> Development
# 2. 选择App ID和开发证书
# 3. 选择测试设备
# 4. 下载并双击安装

# 发布用Provisioning Profile
# 1. Profiles -> Distribution
# 2. 选择App Store或Ad Hoc
# 3. 选择App ID和发布证书
# 4. 下载并安装
```

## 5. Flutter iOS配置

### 5.1 安装 CocoaPods

```bash
# 安装CocoaPods
sudo gem install cocoapods

# 或使用Homebrew
brew install cocoapods

# 验证安装
pod --version
```

### 5.2 Flutter配置检查

```bash
# 检查Flutter iOS配置
flutter doctor

# 配置iOS模拟器
flutter config --ios-simulator-log-enable

# 检查iOS设备
flutter devices
```

### 5.3 项目依赖安装

```bash
# 进入iOS目录
cd ios

# 安装Pod依赖
pod install

# 如果遇到问题，清理并重新安装
pod deintegrate
pod clean
pod install
```

## 6. 项目配置

### 6.1 Bundle Identifier配置

编辑 `ios/Runner.xcodeproj/project.pbxproj` 或在Xcode中配置：

```xml
<!-- 在Xcode中设置 -->
<!-- Project -> Runner -> Signing & Capabilities -->
<!-- Bundle Identifier: com.example.demo -->
```

### 6.2 Info.plist配置

编辑 `ios/Runner/Info.plist`:

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
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>demo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
</dict>
</plist>
```

### 6.3 权限配置

根据应用需要添加权限：

```xml
<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos</string>

<!-- 照片库权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select images</string>

<!-- 位置权限 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to provide location-based services</string>

<!-- 麦克风权限 -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>
```

## 7. 构建配置

### 7.1 Build Settings配置

在Xcode中配置以下设置：

```bash
# Build Settings
# 1. iOS Deployment Target: 12.0
# 2. Swift Language Version: Swift 5
# 3. Build Active Architecture Only: 
#    - Debug: YES
#    - Release: NO
# 4. Valid Architectures: arm64, x86_64
# 5. Excluded Architectures (Simulator): arm64 (仅Intel Mac需要)
```

### 7.2 Build Phases配置

```bash
# 添加Run Script Phase（如果需要）
# 1. Build Phases -> + -> New Run Script Phase
# 2. 添加脚本内容，例如：
echo "Building Flutter app..."
```

### 7.3 Scheme配置

```bash
# 配置构建Scheme
# 1. Product -> Scheme -> Manage Schemes
# 2. 编辑Runner scheme
# 3. Build Configuration:
#    - Debug: Debug
#    - Release: Release
#    - Archive: Release
```

## 8. App Store Connect

### 8.1 创建App记录

1. **登录App Store Connect**: https://appstoreconnect.apple.com/
2. **创建新App**:
   ```
   - Platform: iOS
   - Name: Demo App
   - Primary Language: Chinese (Simplified)
   - Bundle ID: com.example.demo
   - SKU: com.example.demo.001
   ```

### 8.2 App信息配置

```bash
# App信息页面配置
# 1. App Information
#    - Subtitle (可选)
#    - Category: 选择合适的分类
#    - Content Rights: 选择是否包含第三方内容
# 
# 2. Pricing and Availability
#    - Price Schedule: 免费或付费
#    - Availability: 选择发布地区
```

### 8.3 版本信息配置

```bash
# 准备发布页面
# 1. Version Information
#    - Version: 1.0.0
#    - What's New in This Version: 版本更新说明
# 
# 2. App Store Metadata
#    - Description: 应用描述
#    - Keywords: 关键词（最多100字符）
#    - Support URL: 支持链接
#    - Marketing URL: 营销链接（可选）
```

## 9. TestFlight配置

### 9.1 内部测试

```bash
# 1. 在App Store Connect中
# 2. TestFlight -> Internal Testing
# 3. 添加内部测试人员（最多100人）
# 4. 上传构建版本后自动分发
```

### 9.2 外部测试

```bash
# 1. TestFlight -> External Testing
# 2. 创建测试组
# 3. 添加外部测试人员（最多10000人）
# 4. 提交Beta Review（首次需要）
# 5. 审核通过后分发给测试人员
```

### 9.3 TestFlight自动上传配置

创建 `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Upload to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "./build"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      skip_submission: true
    )
  end
end
```

## 10. 验证配置

### 10.1 构建测试

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 安装iOS依赖
cd ios && pod install && cd ..

# 构建Debug版本（模拟器）
flutter build ios --debug --simulator

# 构建Release版本（真机）
flutter build ios --release

# 构建IPA文件
flutter build ipa --release
```

### 10.2 模拟器测试

```bash
# 启动模拟器
open -a Simulator

# 运行应用到模拟器
flutter run -d ios

# 指定特定模拟器
flutter run -d "iPhone 15 Pro"
```

### 10.3 真机测试

```bash
# 连接iPhone到Mac
# 确保设备已信任此电脑

# 列出连接的设备
flutter devices

# 运行到真机
flutter run -d ios --release

# 或使用设备ID
flutter run -d [device-id]
```

### 10.4 Archive构建

```bash
# 在Xcode中
# 1. 选择 "Any iOS Device" 作为目标
# 2. Product -> Archive
# 3. 等待构建完成
# 4. 在Organizer中管理Archive

# 或使用命令行
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/Runner.xcarchive \
  archive
```

## 11. 常见问题

### 11.1 证书和签名问题

**问题**: "No signing certificate found"
```bash
# 解决方案
# 1. 检查Apple Developer账号状态
# 2. 在Xcode中重新下载证书
# 3. 确保Bundle ID匹配
# 4. 检查Provisioning Profile是否有效
```

**问题**: "Code signing is required for product type 'Application'"
```bash
# 解决方案
# 1. 在Xcode中启用自动签名管理
# 2. 选择正确的开发团队
# 3. 确保有有效的开发者账号
```

### 11.2 构建问题

**问题**: "CocoaPods not installed"
```bash
# 解决方案
sudo gem install cocoapods
cd ios && pod install
```

**问题**: "Architecture arm64 not supported"
```bash
# 解决方案（仅Intel Mac + M1模拟器）
# 在Build Settings中的Excluded Architectures添加arm64
# 仅在Debug + Any iOS Simulator SDK中添加
```

**问题**: "Module 'xxx' not found"
```bash
# 解决方案
cd ios
pod deintegrate
pod clean
pod install
```

### 11.3 App Store问题

**问题**: "Invalid Bundle Structure"
```bash
# 解决方案
# 1. 检查Info.plist配置
# 2. 确保所有必需的键值对存在
# 3. 验证Bundle Identifier格式
# 4. 检查版本号格式
```

**问题**: "Missing Compliance"
```bash
# 解决方案
# 在App Store Connect中完成出口合规性问卷
# 大多数应用选择"No"（不使用加密）
```

### 11.4 版本管理问题

**问题**: "CFBundleVersion Duplicate"
```bash
# 解决方案
# 确保每次上传的Build Number都是递增的
# 在flutter build ipa时使用 --build-number参数
flutter build ipa --build-number=123
```

**问题**: "Invalid Version Number"
```bash
# 解决方案
# 版本号格式必须是X.Y.Z格式
# 例如：1.0.0, 2.1.3
# 构建号可以是任意递增的整数
```

## 相关资源

### 官方文档
- [iOS Developer Documentation](https://developer.apple.com/documentation/ios/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

### 工具和服务
- [Xcode](https://developer.apple.com/xcode/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [TestFlight](https://developer.apple.com/testflight/)
- [Fastlane](https://fastlane.tools/)

### 证书和签名
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 