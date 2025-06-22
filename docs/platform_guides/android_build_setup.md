# Android 平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: Android

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Java开发环境](#2-java开发环境)
- [3. Android SDK安装](#3-android-sdk安装)
- [4. Flutter Android配置](#4-flutter-android配置)
- [5. 签名配置](#5-签名配置)
- [6. 构建工具配置](#6-构建工具配置)
- [7. 混淆配置](#7-混淆配置)
- [8. Google Play配置](#8-google-play配置)
- [9. 验证配置](#9-验证配置)
- [10. 常见问题](#10-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **Windows**: Windows 10 (64-bit) 或更高版本
- **macOS**: macOS 10.14 或更高版本
- **Linux**: Ubuntu 18.04 LTS 或更高版本

### 1.2 硬件要求
- **内存**: 最少8GB RAM（推荐16GB）
- **存储**: 至少50GB可用空间
- **处理器**: Intel/AMD 64位处理器

### 1.3 必需软件版本
- **Java**: JDK 11 或 JDK 17
- **Android SDK**: API Level 21-34
- **Gradle**: 8.0 或更高版本
- **Flutter**: 3.13.0 或更高版本

## 2. Java开发环境

### 2.1 安装 JDK

#### Windows
```bash
# 下载并安装 OpenJDK 17
# 访问: https://adoptium.net/temurin/releases/
# 下载 Windows x64 MSI 安装包并运行

# 或使用 Chocolatey
choco install temurin17
```

#### macOS
```bash
# 使用 Homebrew
brew install openjdk@17

# 添加到 PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### Linux (Ubuntu)
```bash
# 安装 OpenJDK 17
sudo apt update
sudo apt install openjdk-17-jdk

# 设置 JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 2.2 验证 Java 安装
```bash
java -version
javac -version
echo $JAVA_HOME
```

## 3. Android SDK安装

### 3.1 方式一：通过 Android Studio

1. **下载 Android Studio**
   ```
   https://developer.android.com/studio
   ```

2. **安装 Android Studio**
   - Windows: 运行下载的 `.exe` 文件
   - macOS: 拖拽到 Applications 文件夹
   - Linux: 解压并运行 `studio.sh`

3. **初始配置**
   ```
   1. 启动 Android Studio
   2. 选择 "Standard" 安装类型
   3. 下载并安装必要的 SDK 组件
   4. 配置 Android SDK 路径
   ```

### 3.2 方式二：仅安装 Command Line Tools

#### Windows
```powershell
# 下载 Command Line Tools
# https://developer.android.com/studio#command-tools

# 创建目录
mkdir C:\android-sdk\cmdline-tools
cd C:\android-sdk\cmdline-tools

# 解压下载的工具包到 latest 目录
# 设置环境变量
setx ANDROID_HOME "C:\android-sdk"
setx PATH "%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools"
```

#### macOS/Linux
```bash
# 下载 Command Line Tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip

# 创建目录
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools

# 解压
unzip ~/Downloads/commandlinetools-linux-*_latest.zip
mv cmdline-tools latest

# 设置环境变量
echo 'export ANDROID_HOME=~/android-sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 3.3 安装必需的 SDK 组件

```bash
# 接受许可协议
sdkmanager --licenses

# 安装必需组件
sdkmanager "platform-tools"
sdkmanager "platforms;android-21"
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
sdkmanager "build-tools;33.0.2"

# 安装 NDK（如果需要）
sdkmanager "ndk;25.1.8937393"

# 安装模拟器（可选）
sdkmanager "emulator"
sdkmanager "system-images;android-34;google_apis;x86_64"
```

## 4. Flutter Android配置

### 4.1 配置 Flutter

```bash
# 检查 Flutter 配置
flutter doctor

# 配置 Android SDK 路径（如果需要）
flutter config --android-sdk /path/to/android-sdk

# 检查 Android 设置
flutter doctor --android-licenses
```

### 4.2 项目 Android 配置

编辑 `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.example.demo"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.demo"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
            isMinifyEnabled = false
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
        }
        
        create("production") {
            dimension = "environment"
        }
    }
}
```

## 5. 签名配置

### 5.1 生成签名密钥

```bash
# 生成 Release 签名密钥
keytool -genkey -v -keystore ~/demo-release-key.keystore \
  -alias demo-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# 生成 Debug 签名密钥（可选，Flutter会自动生成）
keytool -genkey -v -keystore ~/demo-debug-key.keystore \
  -alias demo-debug \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 5.2 配置签名

创建 `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=demo-release
storeFile=/path/to/demo-release-key.keystore
```

更新 `android/app/build.gradle.kts`:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## 6. 构建工具配置

### 6.1 Gradle 配置

编辑 `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
```

编辑 `android/build.gradle.kts`:

```kotlin
buildscript {
    ext.kotlin_version = '1.9.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### 6.2 多渠道打包配置

```kotlin
android {
    flavorDimensions += listOf("version", "environment")
    
    productFlavors {
        create("free") {
            dimension = "version"
            applicationIdSuffix = ".free"
            versionNameSuffix = "-free"
        }
        
        create("paid") {
            dimension = "version"
            applicationIdSuffix = ".paid"
            versionNameSuffix = "-paid"
        }
        
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        
        create("production") {
            dimension = "environment"
        }
    }
}
```

## 7. 混淆配置

### 7.1 创建 ProGuard 规则

创建 `android/app/proguard-rules.pro`:

```proguard
# Flutter相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart相关
-keep class ** { *; }
-keepattributes *Annotation*
-dontwarn dart.**

# 网络请求相关
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# JSON解析
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 保留实体类
-keep class com.example.demo.models.** { *; }

# Firebase相关（如果使用）
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
```

### 7.2 R8 优化配置

在 `android/app/build.gradle.kts` 中添加：

```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## 8. Google Play配置

### 8.1 生成上传密钥

```bash
# 生成上传密钥
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# 转换为PEPK格式（用于Play App Signing）
java -jar pepk.jar --keystore=upload-keystore.jks \
  --alias=upload --output=output.zip \
  --encryptionkey=eb10fe8f7c7c9df715022017b00c6471f8ba8170b13049a11e6c09ffe3056a104a3bbe4ac5a955f4ba4fe93fc8cef27558a3eb9d2a529a2092761fb833b656cd48b9de6a
```

### 8.2 配置 AAB 打包

在 `android/app/build.gradle.kts` 中：

```kotlin
android {
    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}
```

### 8.3 Play Console API配置

1. **创建服务账号**
   ```
   1. 访问 Google Cloud Console
   2. 创建新项目或选择现有项目
   3. 启用 Google Play Developer API
   4. 创建服务账号并下载JSON密钥
   ```

2. **配置上传脚本**
   ```bash
   # 安装 Google API 客户端
   pip install google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2
   ```

## 9. 验证配置

### 9.1 构建测试

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 检查Android配置
flutter doctor

# 构建Debug版本
flutter build apk --debug

# 构建Release版本
flutter build apk --release

# 构建AAB包
flutter build appbundle --release

# 构建特定渠道
flutter build apk --flavor production --release
```

### 9.2 签名验证

```bash
# 验证APK签名
jarsigner -verify -verbose -certs app-release.apk

# 查看签名信息
keytool -printcert -jarfile app-release.apk

# 使用apksigner验证
apksigner verify --verbose app-release.apk
```

### 9.3 安装测试

```bash
# 列出连接的设备
adb devices

# 安装APK
adb install app-release.apk

# 卸载应用
adb uninstall com.example.demo

# 查看日志
adb logcat | grep Flutter
```

## 10. 常见问题

### 10.1 构建问题

**问题**: `JAVA_HOME` 未设置
```bash
# 解决方案
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

**问题**: Gradle构建失败
```bash
# 清理Gradle缓存
./gradlew clean
rm -rf ~/.gradle/caches/
```

**问题**: SDK许可未接受
```bash
# 接受所有许可
flutter doctor --android-licenses
```

### 10.2 签名问题

**问题**: 签名文件不存在
```bash
# 检查路径是否正确
ls -la /path/to/keystore/file
```

**问题**: 密钥别名错误
```bash
# 列出密钥库中的别名
keytool -list -v -keystore your-keystore.jks
```

### 10.3 版本问题

**问题**: MinSdkVersion不匹配
```kotlin
// 在build.gradle.kts中统一设置
defaultConfig {
    minSdk = 21
}
```

**问题**: 64位架构支持
```kotlin
// 确保支持64位架构
android {
    splits {
        abi {
            enable true
            reset()
            include "x86", "x86_64", "arm64-v8a", "armeabi-v7a"
            universalApk false
        }
    }
}
```

## 相关资源

### 官方文档
- [Android Developer Guide](https://developer.android.com/guide)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Gradle Build System](https://gradle.org/docs/)

### 工具下载
- [Android Studio](https://developer.android.com/studio)
- [Command Line Tools](https://developer.android.com/studio#command-tools)
- [OpenJDK](https://adoptium.net/temurin/releases/)

### 签名和发布
- [App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console/)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 