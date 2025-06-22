# 鸿蒙OS 平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: HarmonyOS

## 目录
- [1. 环境要求](#1-环境要求)
- [2. DevEco Studio安装](#2-deveco-studio安装)
- [3. 鸿蒙SDK配置](#3-鸿蒙sdk配置)
- [4. Flutter鸿蒙配置](#4-flutter鸿蒙配置)
- [5. 项目配置](#5-项目配置)
- [6. HAP包构建配置](#6-hap包构建配置)
- [7. 签名配置](#7-签名配置)
- [8. AppGallery发布](#8-appgallery发布)
- [9. 验证配置](#9-验证配置)
- [10. 常见问题](#10-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **Windows**: Windows 10 (64-bit) 或更高版本
- **macOS**: macOS 10.15 或更高版本
- **Linux**: Ubuntu 18.04 LTS 或更高版本

### 1.2 硬件要求
- **内存**: 最少8GB RAM（推荐16GB）
- **存储**: 至少100GB可用空间
- **处理器**: Intel/AMD 64位处理器或Apple Silicon

### 1.3 必需软件版本
- **DevEco Studio**: 4.0 或更高版本
- **HarmonyOS SDK**: API Level 8 或更高版本
- **Node.js**: 16.x 或更高版本
- **Flutter**: 3.13.0 或更高版本（支持鸿蒙）

### 1.4 开发者账号要求
- **华为开发者账号**: 免费注册
- **企业开发者认证**: 商业应用发布需要
- **个人开发者认证**: 个人应用发布

## 2. DevEco Studio安装

### 2.1 下载DevEco Studio

```bash
# 访问华为开发者官网
https://developer.harmonyos.com/cn/develop/deveco-studio

# 下载对应系统版本的安装包
# Windows: deveco-studio-windows-xxx.exe
# macOS: deveco-studio-mac-xxx.dmg
# Linux: deveco-studio-linux-xxx.tar.gz
```

### 2.2 Windows安装

```powershell
# 1. 运行安装程序
deveco-studio-windows-4.0.exe

# 2. 选择安装目录（建议不要有中文和空格）
# 默认: C:\Users\{username}\AppData\Local\Huawei\DevEco Studio

# 3. 配置环境变量
$env:DEVECO_SDK_HOME = "C:\Users\{username}\Huawei\Sdk"
[Environment]::SetEnvironmentVariable("DEVECO_SDK_HOME", $env:DEVECO_SDK_HOME, "User")

# 4. 验证安装
deveco-studio --version
```

### 2.3 macOS安装

```bash
# 1. 挂载DMG文件
hdiutil attach deveco-studio-mac-4.0.dmg

# 2. 拖拽到Applications文件夹
cp -R "/Volumes/DevEco Studio/DevEco Studio.app" /Applications/

# 3. 首次启动可能需要允许未知开发者
sudo spctl --master-disable

# 4. 配置环境变量
echo 'export DEVECO_SDK_HOME="$HOME/Huawei/Sdk"' >> ~/.zshrc
echo 'export PATH="$PATH:$DEVECO_SDK_HOME/toolchains"' >> ~/.zshrc
source ~/.zshrc
```

### 2.4 Linux安装

```bash
# 1. 解压安装包
tar -xzf deveco-studio-linux-4.0.tar.gz

# 2. 移动到/opt目录
sudo mv deveco-studio /opt/

# 3. 创建桌面快捷方式
cat > ~/.local/share/applications/deveco-studio.desktop << EOF
[Desktop Entry]
Name=DevEco Studio
Comment=The official IDE for HarmonyOS development
Exec=/opt/deveco-studio/bin/deveco-studio.sh
Icon=/opt/deveco-studio/bin/deveco-studio.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

# 4. 配置环境变量
echo 'export DEVECO_SDK_HOME="$HOME/Huawei/Sdk"' >> ~/.bashrc
echo 'export PATH="$PATH:$DEVECO_SDK_HOME/toolchains"' >> ~/.bashrc
source ~/.bashrc
```

## 3. 鸿蒙SDK配置

### 3.1 首次启动配置

```bash
# 1. 启动DevEco Studio
# 2. 在欢迎界面选择"Configure" -> "SDK Manager"
# 3. 或在菜单中选择 File -> Settings -> Appearance & Behavior -> System Settings -> HarmonyOS SDK
```

### 3.2 SDK组件安装

必需安装的SDK组件：

```bash
# HarmonyOS SDK Platform
- HarmonyOS 4.0 (API Level 10)
- HarmonyOS 3.1 (API Level 9) 
- HarmonyOS 3.0 (API Level 8)

# HarmonyOS SDK Tools
- DevEco Testing
- HarmonyOS SDK Tools
- Previewer
- Simulator

# HarmonyOS Build Tools
- HarmonyOS Build Tools 4.0
- HarmonyOS Build Tools 3.1

# 可选组件
- HarmonyOS Emulator System Images
- HarmonyOS Documentation
```

### 3.3 命令行工具配置

```bash
# 配置hdc工具路径
export HDC_PATH="$DEVECO_SDK_HOME/toolchains/hdc"
export PATH="$PATH:$HDC_PATH"

# 验证hdc安装
hdc version

# 配置ohpm包管理器
export OHPM_PATH="$DEVECO_SDK_HOME/toolchains/ohpm"
export PATH="$PATH:$OHPM_PATH"

# 验证ohpm安装
ohpm --version
```

## 4. Flutter鸿蒙配置

### 4.1 获取Flutter鸿蒙版本

```bash
# 注意：Flutter官方对鸿蒙的支持还在开发中
# 可以使用华为提供的Flutter fork或第三方适配

# 方式1：使用华为Flutter fork（推荐）
git clone https://github.com/flutter-dev/flutter-harmony.git
cd flutter-harmony
export PATH="$PWD/bin:$PATH"

# 方式2：使用官方Flutter + 鸿蒙插件
flutter channel master
flutter upgrade
flutter config --enable-harmony-desktop
```

### 4.2 安装鸿蒙开发工具链

```bash
# 安装鸿蒙工具链
flutter precache --harmony

# 验证鸿蒙支持
flutter doctor --verbose
# 应该看到 HarmonyOS toolchain

# 检查可用设备
flutter devices
# 应该看到鸿蒙设备或模拟器
```

### 4.3 创建鸿蒙项目

```bash
# 为现有项目添加鸿蒙支持
flutter create --platforms harmony .

# 或创建新的多平台项目
flutter create --platforms android,ios,harmony,web demo_app

# 进入项目目录
cd demo_app

# 检查鸿蒙平台文件
ls -la harmony/
```

## 5. 项目配置

### 5.1 鸿蒙目录结构

```
harmony/
├── AppScope/                   # 应用全局配置
│   └── app.json5              # 应用配置文件
├── entry/                     # 主模块
│   ├── src/main/
│   │   ├── ets/               # ArkTS源码
│   │   ├── resources/         # 资源文件
│   │   └── module.json5       # 模块配置
│   ├── build-profile.json5    # 构建配置
│   └── hvigorfile.ts         # 构建脚本
├── build-profile.json5        # 项目构建配置
├── hvigorfile.ts             # 项目构建脚本
└── local.properties          # 本地配置
```

### 5.2 配置应用信息

编辑 `harmony/AppScope/app.json5`:

```json5
{
  "app": {
    "bundleName": "com.example.demo",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name",
    "description": "$string:app_description",
    "minAPIVersion": 8,
    "targetAPIVersion": 10,
    "apiReleaseType": "Release",
    "debug": false,
    "distributedNotificationEnabled": true
  }
}
```

编辑 `harmony/entry/src/main/module.json5`:

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_description",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.CAMERA"
      },
      {
        "name": "ohos.permission.MICROPHONE"
      }
    ]
  }
}
```

### 5.3 配置资源文件

创建 `harmony/entry/src/main/resources/base/element/string.json`:

```json
{
  "string": [
    {
      "name": "app_name",
      "value": "Demo App"
    },
    {
      "name": "app_description", 
      "value": "Flutter Demo Application for HarmonyOS"
    },
    {
      "name": "EntryAbility_desc",
      "value": "Entry ability for Demo App"
    },
    {
      "name": "EntryAbility_label",
      "value": "Demo App"
    },
    {
      "name": "module_description",
      "value": "Demo App main module"
    }
  ]
}
```

创建 `harmony/entry/src/main/resources/zh_CN/element/string.json`:

```json
{
  "string": [
    {
      "name": "app_name",
      "value": "演示应用"
    },
    {
      "name": "app_description", 
      "value": "鸿蒙OS Flutter演示应用"
    },
    {
      "name": "EntryAbility_desc",
      "value": "演示应用入口"
    },
    {
      "name": "EntryAbility_label",
      "value": "演示应用"
    },
    {
      "name": "module_description",
      "value": "演示应用主模块"
    }
  ]
}
```

### 5.4 配置应用图标

```bash
# 准备不同尺寸的图标
# 复制图标文件到资源目录
cp assets/images/app_icon.png harmony/entry/src/main/resources/base/media/app_icon.png

# 创建不同密度的图标
# ldpi: 36x36, mdpi: 48x48, hdpi: 72x72, xhdpi: 96x96, xxhdpi: 144x144
mkdir -p harmony/entry/src/main/resources/base/media/
mkdir -p harmony/entry/src/main/resources/hdpi/media/
mkdir -p harmony/entry/src/main/resources/xhdpi/media/
mkdir -p harmony/entry/src/main/resources/xxhdpi/media/
```

## 6. HAP包构建配置

### 6.1 构建配置

编辑 `harmony/build-profile.json5`:

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "strictMode": {
      "caseSensitiveCheck": true,
      "useNormalizedOHMUrl": true
    }
  },
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": true,
            "files": ["obfuscation-rules.txt"]
          },
          "consumerFiles": ["consumer-rules.txt"]
        }
      }
    }
  ],
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    }
  ],
  "products": [
    {
      "name": "default",
      "signingConfig": "default",
      "compatibleSdkVersion": "4.0.0(10)",
      "runtimeOS": "HarmonyOS"
    }
  ],
  "signingConfigs": [
    {
      "name": "default",
      "type": "HarmonyOS",
      "material": {
        "certpath": "build/default.p7b",
        "storePassword": "0000001B9C5AA9E57C6A1E01EBD4A486F3991FFF6B5A77D2F5527B08A5B7AAF10B46",
        "keyAlias": "debugKey",
        "keyPassword": "debugKeyPassword"
      }
    }
  ]
}
```

### 6.2 配置混淆规则

创建 `harmony/obfuscation-rules.txt`:

```txt
# 保持Flutter相关类不被混淆
-keep class io.flutter.** { *; }
-keep class org.** { *; }

# 保持应用主类
-keep class com.example.demo.** { *; }

# 保持native方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保持序列化相关
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
```

### 6.3 构建命令

```bash
# 构建Debug版本HAP
flutter build harmony --debug

# 构建Release版本HAP
flutter build harmony --release

# 构建指定架构
flutter build harmony --target-arch arm64

# 查看构建产物
ls -la build/harmony/outputs/hap/entry/build/default/
```

## 7. 签名配置

### 7.1 生成调试证书

```bash
# 在DevEco Studio中生成调试证书
# 1. File -> Project Structure -> Project -> Signing Configs
# 2. 点击"Generate Signing Certificate"
# 3. 填写证书信息并生成

# 或使用命令行生成
cd harmony/
keytool -genkey -v -keystore debug.keystore -alias debugkey -keyalg RSA -keysize 2048 -validity 10000
```

### 7.2 配置发布证书

```bash
# 1. 登录华为开发者联盟
# https://developer.huawei.com/consumer/cn/

# 2. 进入"管理中心" -> "证书管理"
# 3. 创建证书签名请求(CSR)
# 4. 下载证书文件(.cer)
# 5. 创建Profile文件

# 6. 配置签名信息
# 在build-profile.json5中配置signingConfigs
```

### 7.3 自动签名脚本

创建 `scripts/sign_harmony.sh`:

```bash
#!/bin/bash

HAP_PATH="$1"
KEYSTORE_PATH="harmony/release.keystore"
KEYSTORE_PASSWORD="your_keystore_password"
KEY_ALIAS="releasekey"
KEY_PASSWORD="your_key_password"

if [ -z "$HAP_PATH" ]; then
    echo "Usage: $0 <path-to-hap>"
    exit 1
fi

# 使用DevEco Studio签名工具
$DEVECO_SDK_HOME/toolchains/lib/hap-sign-tool.jar \
    -mode localjks \
    -privatekey $KEY_ALIAS \
    -inputFile "$HAP_PATH" \
    -outputFile "${HAP_PATH%.*}_signed.hap" \
    -keystore $KEYSTORE_PATH \
    -keystorepasswd $KEYSTORE_PASSWORD \
    -keypasswd $KEY_PASSWORD

if [ $? -eq 0 ]; then
    echo "HAP签名成功: ${HAP_PATH%.*}_signed.hap"
else
    echo "HAP签名失败"
    exit 1
fi
```

## 8. AppGallery发布

### 8.1 注册开发者账号

```bash
# 1. 访问华为开发者联盟
https://developer.huawei.com/consumer/cn/

# 2. 注册并完成开发者认证
# - 个人开发者：身份证认证
# - 企业开发者：营业执照认证

# 3. 创建应用
# - 进入"管理中心" -> "应用管理"
# - 点击"创建应用"
# - 填写应用基本信息
```

### 8.2 配置应用信息

```bash
# 1. 应用基本信息
# - 应用名称：Demo App
# - 应用包名：com.example.demo
# - 应用分类：生产力工具
# - 目标用户：全年龄段

# 2. 版本信息
# - 版本号：1.0.0
# - 版本名称：首个正式版本
# - 支持设备：手机、平板、2in1

# 3. 应用介绍
# - 应用简介：Flutter演示应用
# - 应用描述：展示跨平台开发能力
# - 应用截图：准备5-8张应用截图
# - 应用图标：512x512高清图标
```

### 8.3 上传HAP包

```bash
# 1. 构建发布版本
flutter build harmony --release

# 2. 在AppGallery Connect中上传HAP
# - 进入"应用管理" -> 选择应用 -> "版本信息"
# - 点击"上传"上传signed HAP文件
# - 填写版本更新说明

# 3. 配置发布信息
# - 选择发布国家/地区
# - 设置发布时间
# - 配置分发策略
```

### 8.4 应用审核

```bash
# 1. 提交审核
# - 检查所有信息完整性
# - 点击"提交审核"

# 2. 审核流程
# - 自动检测：包安全扫描
# - 人工审核：功能和内容审核
# - 审核时间：通常1-3个工作日

# 3. 发布上线
# - 审核通过后自动发布
# - 或设置定时发布
```

## 9. 验证配置

### 9.1 本地测试

```bash
# 1. 启动鸿蒙模拟器
# 在DevEco Studio中: Tools -> Device Manager -> Create Device

# 2. 运行应用
flutter run -d harmony

# 3. 热重载测试
# 修改代码后按 'r' 进行热重载

# 4. 检查应用功能
# - 界面显示正常
# - 功能操作正常
# - 性能表现良好
```

### 9.2 真机测试

```bash
# 1. 启用开发者模式
# 设置 -> 系统和更新 -> 开发者选项 -> 开启"开发者选项"
# 开启"USB调试"

# 2. 连接设备
hdc list targets

# 3. 安装应用
hdc install build/harmony/outputs/hap/entry/build/default/entry-default-signed.hap

# 4. 启动应用
hdc shell aa start -a com.example.demo.EntryAbility -b com.example.demo
```

### 9.3 性能测试

```bash
# 1. 使用DevEco Studio Profiler
# - CPU使用率监控
# - 内存使用监控
# - 网络请求监控

# 2. 使用命令行工具
# 内存使用情况
hdc shell hidumper -s 3008 -a "-m"

# CPU使用情况
hdc shell top -n 1

# 应用启动时间
hdc shell aa start -a com.example.demo.EntryAbility -b com.example.demo -T
```

## 10. 常见问题

### 10.1 安装问题

**问题**: "DevEco Studio无法启动"
```bash
# 解决方案
# 1. 检查Java环境
java -version

# 2. 检查系统环境变量
echo $DEVECO_SDK_HOME

# 3. 重新安装DevEco Studio
# 4. 检查系统权限设置
```

**问题**: "SDK下载失败"
```bash
# 解决方案
# 1. 检查网络连接
# 2. 配置代理设置（如果需要）
# 3. 使用官网下载离线SDK包
# 4. 手动解压到SDK目录
```

### 10.2 构建问题

**问题**: "Flutter鸿蒙支持不可用"
```bash
# 解决方案
# 1. 确认使用支持鸿蒙的Flutter版本
flutter channel master
flutter upgrade

# 2. 检查工具链安装
flutter doctor --verbose

# 3. 重新安装鸿蒙工具链
flutter precache --harmony
```

**问题**: "HAP构建失败"
```bash
# 解决方案
# 1. 检查项目配置文件语法
# 2. 清理构建缓存
flutter clean
ohpm cache clean

# 3. 重新获取依赖
flutter pub get
ohpm install

# 4. 检查SDK版本兼容性
```

### 10.3 运行时问题

**问题**: "应用启动崩溃"
```bash
# 解决方案
# 1. 查看崩溃日志
hdc shell hilog -x

# 2. 检查权限配置
# module.json5中的requestPermissions

# 3. 检查资源文件路径
# 确认图标、字符串等资源存在

# 4. 调试模式运行
flutter run -d harmony --debug
```

**问题**: "设备连接失败"
```bash
# 解决方案
# 1. 检查USB调试开启
# 2. 安装设备驱动
# 3. 更换USB数据线
# 4. 重启adb服务
hdc kill-server
hdc start-server
```

### 10.4 发布问题

**问题**: "应用审核被拒"
```bash
# 解决方案
# 1. 检查应用内容合规性
# 2. 完善应用描述和截图
# 3. 确保功能完整可用
# 4. 移除调试代码和日志
# 5. 根据审核意见修改后重新提交
```

**问题**: "签名验证失败"
```bash
# 解决方案
# 1. 检查证书有效期
# 2. 确认包名与证书匹配
# 3. 重新生成签名文件
# 4. 使用正确的签名工具版本
```

## 相关资源

### 官方文档
- [HarmonyOS开发者官网](https://developer.harmonyos.com/)
- [DevEco Studio使用指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/ohos-deveco-studio-overview-0000001263280421)
- [HAP包开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/hap-package-overview-0000001218440634)

### 开发工具
- [DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio)
- [HarmonyOS SDK](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/ohos-sdk-overview-0000001263280421)
- [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)

### 分发平台
- [华为应用市场](https://appgallery.huawei.com/)
- [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
- [华为开发者联盟](https://developer.huawei.com/consumer/cn/)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 