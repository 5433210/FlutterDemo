# Android 构建脚本修复报告

## 修复的问题

### 1. 编码问题 (UnicodeDecodeError)
**问题描述：** 
- Python脚本在Windows环境下执行Flutter命令时遇到GBK编码错误
- 错误信息：`UnicodeDecodeError: 'gbk' codec can't decode byte 0xa2 in position 17`

**解决方案：**
- 在所有`subprocess.run()`调用中添加`encoding='utf-8', errors='ignore'`
- 统一使用UTF-8编码处理命令输出

### 2. Flutter命令检测失败
**问题描述：**
- Python脚本无法找到Flutter命令
- 错误信息：`[WinError 2] 系统找不到指定的文件`

**解决方案：**
- 添加多种Flutter命令调用方式：
  - `flutter --version`
  - `flutter.bat --version`
  - `cmd /c flutter --version`
  - `powershell -Command flutter --version`
  - Shell方式：`flutter --version` (shell=True)

### 3. 构建命令执行失败
**问题描述：**
- 直接使用列表形式的命令在Windows环境下不稳定

**解决方案：**
- 改用shell方式执行Flutter构建命令
- 将命令列表转换为字符串：`cmd_str = ' '.join(cmd)`
- 使用`shell=True`参数

## 修复后的功能

### 1. 环境检查 ✅
```bash
python scripts/android_build.py --check-env
```
- 自动检测Flutter、Android SDK、Java、Gradle
- 支持多种Flutter安装方式
- 详细的环境信息输出

### 2. APK构建 ✅
```bash
# 构建单个渠道
python scripts/android_build.py --flavor direct --build-type debug --format apk

# 构建所有渠道
python scripts/android_build.py --all-flavors --build-type debug --format apk
```

### 3. 构建产物整理 ✅
- 自动创建带版本号和时间戳的目录
- 复制APK文件到发布目录
- 生成构建信息JSON文件

## 新增简化版脚本

创建了`android_build_simple.py`作为轻量级替代方案：

### 特点
- 更简单的逻辑
- 更可靠的错误处理
- 专注于基本构建功能

### 使用方法
```bash
# 检查环境
python scripts/android_build_simple.py --check-only

# 构建调试版
python scripts/android_build_simple.py --build-type debug

# 构建profile版
python scripts/android_build_simple.py --build-type profile --flavor direct
```

## 构建产物示例

成功构建后的目录结构：
```
releases/android/v1.0.1_build20250623001_20250623_203125/
├── app-direct-debug.apk        (160.9 MB)
├── app-direct-profile.apk      (69.7 MB)
├── app-googleplay-debug.apk    (81.4 MB)
├── app-huawei-debug.apk        (81.4 MB)
├── app-xiaomi-debug.apk        (81.4 MB)
└── build_info.json
```

## 技术改进

### 1. 错误处理
- 添加了timeout机制防止命令卡死
- 详细的异常信息输出
- 优雅的错误恢复

### 2. 跨平台兼容性
- Windows特殊处理
- 多种命令调用方式
- 路径处理优化

### 3. 构建报告
- JSON格式的构建信息
- 时间戳和版本追踪
- 文件大小统计

## 使用建议

1. **推荐使用原始脚本**（android_build.py）用于生产环境
2. **使用简化脚本**（android_build_simple.py）用于快速测试
3. **定期清理构建缓存**：使用`--clean`参数
4. **检查环境**：构建前先运行`--check-env`

## 已知限制

1. **签名配置**：发布版构建需要配置`android/key.properties`
2. **NDK版本警告**：可以安全忽略或升级到推荐版本
3. **多渠道依赖**：某些Gradle任务可能存在依赖冲突

## 后续优化建议

1. 添加自动签名配置检查
2. 集成NDK版本自动升级
3. 支持增量构建
4. 添加构建性能监控 