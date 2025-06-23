plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.time.LocalDateTime
import java.io.FileInputStream

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// 读取签名配置
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Git相关函数
fun getGitCommit(): String {
    return try {
        val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
            .directory(rootDir)
            .start()
        process.inputStream.bufferedReader().readText().trim()
    } catch (e: Exception) {
        "unknown"
    }
}

fun getBuildTypeName(): String {
    return "android"
}

android {
    namespace = "com.example.demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    
    // 指定 buildToolsVersion 为已安装的版本
    buildToolsVersion = "34.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    // 启用BuildConfig功能
    buildFeatures {
        buildConfig = true
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.demo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode
        versionName = flutterVersionName

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // 多语言支持
        resourceConfigurations.addAll(listOf("zh", "en"))
        
        // 构建配置字段
        buildConfigField("String", "BUILD_TIME", "\"${LocalDateTime.now()}\"")
        buildConfigField("String", "GIT_COMMIT", "\"${getGitCommit()}\"")
        buildConfigField("String", "BUILD_TYPE_NAME", "\"${getBuildTypeName()}\"")
    }

    // 签名配置
    signingConfigs {
        // debug签名使用Flutter默认配置，不需要自定义
        
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { path -> file(path as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    // 构建类型配置
    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
            isMinifyEnabled = false
            // 使用Flutter默认的debug签名
            
            buildConfigField("Boolean", "IS_DEBUG", "true")
            buildConfigField("String", "API_BASE_URL", "\"https://api-dev.example.com\"")
            
            // 开发环境特定配置
            manifestPlaceholders["app_name"] = "Demo Debug"
            manifestPlaceholders["app_icon"] = "@mipmap/ic_launcher_debug"
        }
        
        getByName("release") {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
            
            buildConfigField("Boolean", "IS_DEBUG", "false")
            buildConfigField("String", "API_BASE_URL", "\"https://api.example.com\"")
            
            // 生产环境配置
            manifestPlaceholders["app_name"] = "Demo"
            manifestPlaceholders["app_icon"] = "@mipmap/ic_launcher"
        }
        
        getByName("profile") {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // 使用Flutter默认的debug签名
            matchingFallbacks.addAll(listOf("debug", "release"))
            
            buildConfigField("Boolean", "IS_DEBUG", "false")
            buildConfigField("String", "API_BASE_URL", "\"https://api-staging.example.com\"")
        }
    }

    // 多渠道配置
    flavorDimensions.add("channel")
    productFlavors {
        create("googleplay") {
            dimension = "channel"
            applicationIdSuffix = ".googleplay"
            versionNameSuffix = "-gp"
            
            buildConfigField("String", "CHANNEL", "\"GooglePlay\"")
            manifestPlaceholders["channel_name"] = "GooglePlay"
        }
        
        create("huawei") {
            dimension = "channel"
            applicationIdSuffix = ".huawei"
            versionNameSuffix = "-hw"
            
            buildConfigField("String", "CHANNEL", "\"Huawei\"")
            manifestPlaceholders["channel_name"] = "Huawei"
        }
        
        create("xiaomi") {
            dimension = "channel"
            applicationIdSuffix = ".xiaomi"
            versionNameSuffix = "-mi"
            
            buildConfigField("String", "CHANNEL", "\"Xiaomi\"")
            manifestPlaceholders["channel_name"] = "Xiaomi"
        }
        
        create("direct") {
            dimension = "channel"
            applicationIdSuffix = ".direct"
            versionNameSuffix = "-direct"
            
            buildConfigField("String", "CHANNEL", "\"Direct\"")
            manifestPlaceholders["channel_name"] = "Direct"
        }
    }

    // Bundle配置（AAB）
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    // Lint配置
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable.add("InvalidPackage")
    }

    // 打包配置
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

// 自定义任务
tasks.register("printVersionInfo") {
    doLast {
        println("Version Code: ${android.defaultConfig.versionCode}")
        println("Version Name: ${android.defaultConfig.versionName}")
        println("Git Commit: ${getGitCommit()}")
        println("Build Time: ${LocalDateTime.now()}")
    }
}

// 构建完成后的任务
tasks.whenTaskAdded {
    if (name.startsWith("assemble") && name.contains("Release")) {
        doLast {
            println("Release build completed for $name")
            // 可以在这里添加构建完成后的处理逻辑
        }
    }
}
