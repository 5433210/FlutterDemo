# 版本号格式标准

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **状态**: 正式版本

## 1. 版本号格式规范

### 1.1 基础格式

本项目采用语义化版本控制（Semantic Versioning 2.0.0）规范，版本号格式为：

```
MAJOR.MINOR.PATCH-BUILD
```

**示例**: `1.2.3-20250620001`

### 1.2 版本号组成说明

#### MAJOR（主版本号）
- **范围**: 1-999
- **递增条件**: 
  - 重大功能变更或架构调整
  - 不向后兼容的API更改
  - 重大UI/UX改版
- **初始值**: 1
- **示例**: 1.x.x → 2.x.x

#### MINOR（次版本号）
- **范围**: 0-999
- **递增条件**:
  - 新增功能特性
  - 向后兼容的API增加
  - 显著的性能改进
  - 新平台支持
- **重置规则**: MAJOR递增时重置为0
- **示例**: 1.2.x → 1.3.x

#### PATCH（修订版本号）
- **范围**: 0-999
- **递增条件**:
  - Bug修复
  - 安全补丁
  - 小幅优化改进
  - 文档更新
- **重置规则**: MAJOR或MINOR递增时重置为0
- **示例**: 1.2.3 → 1.2.4

#### BUILD（构建号）
- **格式**: YYYYMMDDXXX
- **说明**:
  - YYYY: 4位年份
  - MM: 2位月份（01-12）
  - DD: 2位日期（01-31）
  - XXX: 3位序号（001-999）
- **示例**: 20250620001
- **递增规则**: 每次构建自动递增

## 2. 预发布版本规范

### 2.1 预发布标识符

预发布版本在PATCH后添加预发布标识符：

```
MAJOR.MINOR.PATCH-PRERELEASE-BUILD
```

#### 支持的预发布类型

| 类型 | 标识符 | 说明 | 示例 |
|------|--------|------|------|
| **开发版** | `dev` | 开发过程中的版本 | `1.2.3-dev-20250620001` |
| **Alpha版** | `alpha` | 内部测试版本 | `1.2.3-alpha-20250620001` |
| **Beta版** | `beta` | 公开测试版本 | `1.2.3-beta-20250620001` |
| **候选版** | `rc` | 发布候选版本 | `1.2.3-rc-20250620001` |

### 2.2 预发布版本序号

预发布版本可以添加序号：

```
1.2.3-alpha.1-20250620001
1.2.3-alpha.2-20250620002
1.2.3-beta.1-20250620003
```

## 3. 平台特定版本映射

### 3.1 Android平台

```gradle
// build.gradle.kts
android {
    defaultConfig {
        versionCode = 20250620001        // BUILD号
        versionName = "1.2.3"           // MAJOR.MINOR.PATCH
    }
}
```

### 3.2 iOS平台

```xml
<!-- Info.plist -->
<key>CFBundleShortVersionString</key>
<string>1.2.3</string>                  <!-- MAJOR.MINOR.PATCH -->
<key>CFBundleVersion</key>
<string>20250620001</string>            <!-- BUILD号 -->
```

### 3.3 鸿蒙OS平台

```json5
// app.json5
{
  "app": {
    "versionCode": 20250620001,         // BUILD号
    "versionName": "1.2.3"             // MAJOR.MINOR.PATCH
  }
}
```

### 3.4 Web平台

```json
// manifest.json
{
  "version": "1.2.3",                  // MAJOR.MINOR.PATCH
  "version_name": "1.2.3-20250620001" // 完整版本号
}
```

### 3.5 Windows平台

```rc
// Runner.rc
FILEVERSION 1,2,3,20250620001          // MAJOR,MINOR,PATCH,BUILD
PRODUCTVERSION 1,2,3,20250620001       // MAJOR,MINOR,PATCH,BUILD
VALUE "FileVersion", "1.2.3.20250620001"
VALUE "ProductVersion", "1.2.3.20250620001"
```

### 3.6 macOS平台

```xml
<!-- Info.plist -->
<key>CFBundleShortVersionString</key>
<string>1.2.3</string>                  <!-- MAJOR.MINOR.PATCH -->
<key>CFBundleVersion</key>
<string>20250620001</string>            <!-- BUILD号 -->
```

### 3.7 Linux平台

```cpp
// 应用内版本定义
#define APP_VERSION_MAJOR 1
#define APP_VERSION_MINOR 2
#define APP_VERSION_PATCH 3
#define APP_BUILD_NUMBER "20250620001"
#define APP_VERSION_STRING "1.2.3-20250620001"
```

## 4. 版本号递增规则

### 4.1 自动递增规则

| 触发条件 | MAJOR | MINOR | PATCH | BUILD |
|----------|-------|-------|-------|-------|
| 主版本发布 | +1 | 0 | 0 | 自动生成 |
| 功能版本发布 | 不变 | +1 | 0 | 自动生成 |
| 修复版本发布 | 不变 | 不变 | +1 | 自动生成 |
| 每次构建 | 不变 | 不变 | 不变 | +1 |

### 4.2 手动递增规则

开发人员可以通过以下方式手动指定版本号：

```bash
# 指定完整版本号
flutter build --build-name=1.2.3 --build-number=20250620001

# 使用脚本指定
python scripts/set_version.py --major=1 --minor=2 --patch=3
```

## 5. 构建号生成规则

### 5.1 日期格式构建号

**格式**: `YYYYMMDDXXX`

**生成规则**:
1. 获取当前日期（YYYYMMDD）
2. 查询当日已有构建号的最大序号
3. 序号+1，不足3位前补0

**示例**:
```
2025年6月20日第1次构建: 20250620001
2025年6月20日第2次构建: 20250620002
2025年6月20日第999次构建: 20250620999
```

### 5.2 序号重置规则

- **每日重置**: 每天序号从001开始
- **跨日处理**: 新的一天自动重置为001
- **最大限制**: 单日最多999次构建

### 5.3 特殊情况处理

#### 时区处理
- 统一使用UTC+8（北京时间）
- 避免跨时区构建号冲突

#### 回滚处理
- 允许指定历史构建号
- 不允许使用未来日期构建号

## 6. 版本比较规则

### 6.1 版本优先级

版本比较按以下优先级进行：

1. **MAJOR**: 数值大的版本更新
2. **MINOR**: MAJOR相同时，数值大的版本更新
3. **PATCH**: MAJOR和MINOR相同时，数值大的版本更新
4. **PRERELEASE**: 正式版本 > 预发布版本
5. **BUILD**: 其他都相同时，数值大的构建更新

### 6.2 预发布版本比较

预发布版本优先级（从低到高）：
```
dev < alpha < beta < rc < 正式版
```

### 6.3 比较示例

```
1.0.0-dev-20250620001 < 1.0.0-alpha-20250620002 < 1.0.0-beta-20250620003 < 1.0.0-rc-20250620004 < 1.0.0-20250620005 < 1.0.1-20250620006
```

## 7. 版本标签规范

### 7.1 Git标签格式

```bash
# 正式版本
git tag v1.2.3

# 预发布版本
git tag v1.2.3-alpha.1
git tag v1.2.3-beta.1
git tag v1.2.3-rc.1
```

### 7.2 分支命名规范

```bash
# 主分支
main                    # 主开发分支
release/1.2.3          # 发布分支
hotfix/1.2.4           # 热修复分支

# 功能分支
feature/version-management
feature/multi-platform-build
```

## 8. 配置文件管理

### 8.1 版本配置文件

创建 `version.yaml` 统一管理版本信息：

```yaml
# version.yaml
version:
  major: 1
  minor: 2
  patch: 3
  prerelease: ""        # dev, alpha, beta, rc 或空字符串
  build: 20250620001

# 平台特定配置
platforms:
  android:
    min_sdk: 21
    target_sdk: 34
  ios:
    min_version: "12.0"
    target_version: "17.0"
  web:
    pwa_version: "1.2.3"
```

### 8.2 自动同步机制

版本信息修改后，自动同步到所有平台配置文件：

1. 修改 `version.yaml`
2. 运行 `python scripts/sync_version.py`
3. 所有平台配置文件自动更新

## 9. 版本发布流程

### 9.1 开发版本流程

```bash
1. 开发功能 → 1.2.3-dev-YYYYMMDDXXX
2. 功能完成 → 合并到主分支
3. 创建发布分支 → release/1.2.3
4. 测试验证 → 1.2.3-alpha.1-YYYYMMDDXXX
5. 公开测试 → 1.2.3-beta.1-YYYYMMDDXXX
6. 发布候选 → 1.2.3-rc.1-YYYYMMDDXXX
7. 正式发布 → 1.2.3-YYYYMMDDXXX
```

### 9.2 热修复流程

```bash
1. 创建热修复分支 → hotfix/1.2.4
2. 修复问题 → 1.2.4-dev-YYYYMMDDXXX
3. 测试验证 → 1.2.4-rc.1-YYYYMMDDXXX
4. 紧急发布 → 1.2.4-YYYYMMDDXXX
```

## 10. 工具和脚本

### 10.1 版本管理脚本

| 脚本 | 功能 | 使用示例 |
|------|------|----------|
| `set_version.py` | 设置版本号 | `python scripts/set_version.py --minor` |
| `get_version.py` | 获取版本信息 | `python scripts/get_version.py` |
| `sync_version.py` | 同步版本到各平台 | `python scripts/sync_version.py` |
| `check_version.py` | 检查版本一致性 | `python scripts/check_version.py` |

### 10.2 CI/CD集成

```yaml
# .github/workflows/version.yml
- name: Generate Version
  run: python scripts/generate_version.py

- name: Check Version Consistency
  run: python scripts/check_version.py

- name: Update Build Number
  run: python scripts/update_build_number.py
```

## 11. 最佳实践

### 11.1 版本发布建议

1. **定期发布**: 建议每2-4周发布一个MINOR版本
2. **及时修复**: 重要Bug应在1周内发布PATCH版本
3. **预发布测试**: 重要版本应经过完整的预发布流程
4. **版本文档**: 每个版本都应有详细的变更日志

### 11.2 版本号使用注意事项

1. **不要跳跃**: 版本号应连续递增，不要跳过数字
2. **保持一致**: 所有平台版本号必须保持一致
3. **及时更新**: 版本号变更后及时同步到所有配置文件
4. **备份记录**: 重要版本发布前备份版本配置

## 12. 兼容性说明

### 12.1 向后兼容性

- **API兼容**: MINOR版本更新保证API向后兼容
- **数据兼容**: 数据格式变更需要提供迁移方案
- **配置兼容**: 配置文件格式变更需要向后兼容

### 12.2 升级策略

- **强制升级**: MAJOR版本可以要求强制升级
- **推荐升级**: MINOR版本推荐用户升级
- **自动升级**: PATCH版本可以自动升级

---

## 附录

### A. 版本号示例

| 版本类型 | 版本号示例 | 说明 |
|----------|------------|------|
| 初始版本 | `1.0.0-20250620001` | 项目首次发布 |
| 功能更新 | `1.1.0-20250625001` | 新增功能 |
| Bug修复 | `1.1.1-20250626001` | 修复问题 |
| 开发版本 | `1.2.0-dev-20250627001` | 开发中版本 |
| 测试版本 | `1.2.0-alpha.1-20250628001` | 内部测试 |
| 公测版本 | `1.2.0-beta.1-20250629001` | 公开测试 |
| 候选版本 | `1.2.0-rc.1-20250630001` | 发布候选 |
| 正式版本 | `1.2.0-20250701001` | 正式发布 |

### B. 相关工具链接

- [Semantic Versioning](https://semver.org/)
- [Flutter版本管理](https://docs.flutter.dev/deployment/flavors)
- [Git标签管理](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0*  
*审核状态: 待团队评审* 