# 鸿蒙OS平台配置

## 概述

此目录包含鸿蒙OS平台的基础配置结构，为Flutter应用适配鸿蒙OS做准备。

## 目录结构

```
ohos/
├── app/
│   ├── app.json5                    # 应用级配置文件
│   └── build-profile.json5         # 应用构建配置
├── entry/
│   ├── src/main/
│   │   ├── config.json             # 入口模块配置（版本信息在此）
│   │   ├── ets/                    # ArkTS源码目录
│   │   │   ├── Application/
│   │   │   │   └── MyAbilityStage.ts
│   │   │   └── MainAbility/
│   │   │       └── MainAbility.ts
│   │   └── resources/              # 资源文件目录
│   │       ├── base/profile/
│   │       │   └── main_pages.json
│   │       ├── zh_CN/element/
│   │       │   └── string.json     # 中文字符串资源
│   │       └── en_US/element/
│   │           └── string.json     # 英文字符串资源
│   └── build-profile.json5         # 入口模块构建配置
├── build-profile.json5             # 项目级构建配置
├── hvigorfile.ts                   # 构建脚本
└── README.md                       # 本文档
```

## 版本信息位置

### 主要配置文件

1. **`app/app.json5`** - 应用级版本配置
   ```json5
   {
     "app": {
       "versionCode": 20250620001,    // 构建号
       "versionName": "1.0.0"         // 版本名称
     }
   }
   ```

2. **`entry/src/main/config.json`** - 入口模块版本配置
   ```json
   {
     "app": {
       "versionCode": 20250620001,
       "versionName": "1.0.0",
       "minCompatibleVersionCode": 20250620001
     }
   }
   ```

## 版本管理集成

### 自动更新脚本

我们的版本管理脚本 `scripts/generate_version_info.py` 已经包含了鸿蒙平台支持：

```python
# 支持的平台配置
'ohos': {
    'versionName': version_string,
    'versionCode': int(build)
}
```

### 手动更新版本

1. 修改 `version.yaml` 中的版本信息
2. 运行版本生成脚本：
   ```bash
   python scripts/generate_version_info.py
   ```

### 构建应用

当Flutter正式支持鸿蒙后，可以使用：

```bash
# 构建调试版本
flutter build harmonyos --debug

# 构建发布版本  
flutter build harmonyos --release
```

## 开发环境要求

### 鸿蒙开发工具

1. **DevEco Studio** - 鸿蒙官方IDE
2. **HarmonyOS SDK** - 鸿蒙系统SDK
3. **Node.js** - 用于hvigor构建工具

### Flutter鸿蒙支持

目前Flutter对鸿蒙的支持状态：
- ⏳ **官方支持**: 开发中，预计2024年下半年
- ✅ **第三方支持**: 可使用OpenHarmony Flutter
- ✅ **配置准备**: 已完成基础配置结构

## 应用签名

### 调试签名

使用默认的调试签名配置：
- 证书: `build/default/intermediates/signing/debug/cert.pem`
- 密钥库: `build/default/intermediates/signing/debug/ohos_app_debug.p12`

### 发布签名

发布时需要：
1. 申请鸿蒙开发者证书
2. 配置正式签名文件
3. 更新 `build-profile.json5` 中的签名配置

## 应用商店发布

### AppGallery Connect

1. 注册华为开发者账号
2. 创建应用项目
3. 配置应用信息和版本
4. 上传HAP文件进行审核

### 版本发布流程

```bash
# 1. 更新版本号
python scripts/generate_version_info.py --increment patch

# 2. 构建发布版本
cd ohos
hvigor build --mode release

# 3. 签名HAP文件
hap-sign-tool sign-app --keystore release.p12 --inFile entry.hap

# 4. 上传到AppGallery Connect
python scripts/publish_to_appgallery.py
```

## 注意事项

### 当前限制

1. **Flutter支持**: 官方Flutter鸿蒙支持尚未完全就绪
2. **API兼容性**: 部分Flutter插件可能需要适配
3. **测试设备**: 需要鸿蒙设备或模拟器进行测试

### 后续计划

1. 等待Flutter官方鸿蒙支持发布
2. 集成到CI/CD流程
3. 完善自动化构建和发布

## 相关文档

- [鸿蒙应用开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/start-overview-0000001478061421)
- [DevEco Studio用户指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/tools_overview-0000001053582387)
- [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)

---

**创建时间**: 2025年6月20日  
**版本**: 1.0.0  
**状态**: 基础配置完成，等待Flutter官方支持 