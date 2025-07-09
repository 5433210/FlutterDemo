# 数据路径配置功能使用指南

## 概述

数据路径配置功能允许用户自定义应用数据的存储位置，提供了灵活的数据管理能力。该功能包括路径验证、版本兼容性检查、数据迁移等完整的功能。

## 主要功能

### 1. 数据路径配置
- **默认路径**: `getApplicationSupportDirectory()/charasgem`
- **自定义路径**: 用户可以选择任何具有读写权限的目录
- **配置持久化**: 配置保存在默认路径下的 `config.json` 文件中

### 2. 版本兼容性管理
- **版本检查**: 自动检查数据版本与应用版本的兼容性
- **自动升级**: 同主版本内的数据可以自动升级
- **不兼容处理**: 跨主版本或降级时提供明确的错误提示

### 3. 数据迁移
- **智能迁移**: 支持文件复制和移动两种模式
- **进度显示**: 提供迁移进度的实时反馈
- **完整性验证**: 迁移完成后自动验证数据完整性

## 使用方法

### 在设置界面中使用

数据路径配置功能已集成到应用的设置页面中：

1. **打开设置页面**: 在主界面中点击设置按钮
2. **找到数据路径设置**: 在设置页面中找到"数据存储路径"选项
3. **更改路径**: 点击文件夹图标选择新的数据路径
4. **确认更改**: 系统会显示兼容性检查结果和确认对话框
5. **重启应用**: 更改后需要重启应用程序以使更改生效

### 代码示例

#### 1. 使用Provider访问数据路径配置

```dart
// 获取当前数据路径配置
Consumer(
  builder: (context, ref, child) {
    final configAsync = ref.watch(dataPathConfigProvider);
    return configAsync.when(
      data: (config) {
        return Text('当前路径: ${config.useDefaultPath ? "默认" : config.customPath}');
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('错误: $error'),
    );
  },
);

// 获取实际数据路径
Consumer(
  builder: (context, ref, child) {
    final pathAsync = ref.watch(actualDataPathProvider);
    return pathAsync.when(
      data: (path) => Text('实际路径: $path'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('错误: $error'),
    );
  },
);
```

#### 2. 程序化更改数据路径

```dart
// 设置自定义数据路径
Future<void> setCustomPath(WidgetRef ref, String newPath) async {
  final notifier = ref.read(dataPathConfigProvider.notifier);
  final success = await notifier.setCustomDataPath(newPath);
  
  if (success) {
    // 提示用户重启应用
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('需要重启'),
        content: Text('数据路径已更改，请重启应用程序'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await AppRestartService.restartApp(context);
            },
            child: Text('立即重启'),
          ),
        ],
      ),
    );
  } else {
    // 显示错误信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('设置数据路径失败')),
    );
  }
}

// 重置为默认路径
Future<void> resetToDefault(WidgetRef ref) async {
  final notifier = ref.read(dataPathConfigProvider.notifier);
  final success = await notifier.resetToDefaultPath();
  
  if (success) {
    // 提示重启
  }
}
```

#### 3. 路径验证和兼容性检查

```dart
// 验证路径
Future<void> validatePath(WidgetRef ref, String path) async {
  final notifier = ref.read(dataPathConfigProvider.notifier);
  final result = await notifier.validatePath(path);
  
  if (result.isValid) {
    print('路径有效');
  } else {
    print('路径无效: ${result.errorMessage}');
  }
}

// 检查数据兼容性
Future<void> checkCompatibility(WidgetRef ref, String path) async {
  final notifier = ref.read(dataPathConfigProvider.notifier);
  final result = await notifier.checkDataCompatibility(path);
  
  switch (result.status) {
    case DataCompatibilityStatus.compatible:
      print('数据兼容');
      break;
    case DataCompatibilityStatus.upgradable:
      print('数据可升级');
      break;
    case DataCompatibilityStatus.incompatible:
      print('数据不兼容');
      break;
    case DataCompatibilityStatus.newDataPath:
      print('新数据路径');
      break;
    default:
      print('未知状态');
  }
}
```

#### 4. 数据迁移

```dart
// 估算迁移信息
Future<void> estimateMigration(String sourcePath) async {
  final estimate = await DataMigrationService.estimateMigration(sourcePath);
  
  print('文件数量: ${estimate.fileCount}');
  print('数据大小: ${estimate.formattedSize}');
  print('预计时间: ${estimate.formattedDuration}');
}

// 执行数据迁移
Future<void> migrateData(String sourcePath, String targetPath) async {
  final result = await DataMigrationService.migrateData(
    sourcePath,
    targetPath,
    moveData: false, // false表示复制，true表示移动
    onProgress: (processed, total) {
      print('进度: $processed/$total');
    },
  );
  
  if (result.isSuccess) {
    print('迁移成功，处理了 ${result.processedFiles} 个文件');
  } else {
    print('迁移失败: ${result.errorMessage}');
  }
}
```

## 文件结构

数据路径配置功能涉及以下文件：

```
lib/
├── domain/models/config/
│   └── data_path_config.dart                 # 数据路径配置模型
├── application/
│   ├── services/
│   │   ├── data_path_config_service.dart     # 数据路径配置服务
│   │   ├── data_migration_service.dart       # 数据迁移服务
│   │   └── app_initialization_service.dart   # 应用初始化服务
│   └── providers/
│       ├── data_path_provider.dart           # 数据路径Provider
│       └── app_initialization_provider.dart  # 应用初始化Provider
├── presentation/pages/settings/components/
│   └── data_path_settings.dart               # 数据路径设置UI
└── utils/
    └── app_restart_service.dart               # 应用重启服务
```

## 配置文件格式

### config.json
```json
{
  "useDefaultPath": false,
  "customPath": "C:\\Users\\UserName\\Documents\\CharAsGem",
  "lastUpdated": "2025-07-09T10:30:00.000Z",
  "requiresRestart": true
}
```

### data_version.json
```json
{
  "appVersion": "1.2.3",
  "lastModified": "2025-07-09T10:30:00.000Z"
}
```

## 版本兼容性规则

| 当前版本 | 数据版本 | 兼容性 | 处理方式 |
|---------|---------|--------|----------|
| 2.1.0 | 2.0.5 | ✅ 兼容 | 直接使用，自动升级版本信息 |
| 2.0.0 | 1.9.0 | ❌ 不兼容 | 拒绝使用，需要数据迁移工具 |
| 1.9.0 | 2.0.0 | ❌ 不兼容 | 拒绝使用，提示更新应用 |
| 2.1.0 | (无版本) | 🆕 新路径 | 创建版本文件 |

## 错误处理

### 常见错误及解决方案

1. **路径权限错误**
   - 错误信息：`目录没有读写权限`
   - 解决方案：选择具有完整读写权限的目录

2. **版本不兼容错误**
   - 错误信息：`数据版本不兼容`
   - 解决方案：使用数据迁移工具或更新应用版本

3. **迁移失败错误**
   - 错误信息：`数据迁移失败`
   - 解决方案：检查磁盘空间和文件权限

4. **配置文件损坏**
   - 错误信息：`读取配置文件失败`
   - 解决方案：删除配置文件，重新设置路径

## 最佳实践

1. **选择路径时**：
   - 选择有足够空间的磁盘
   - 避免选择系统目录或临时目录
   - 确保目录路径不会被其他程序占用

2. **备份数据**：
   - 在更改数据路径前备份重要数据
   - 定期创建数据备份

3. **网络存储**：
   - 避免使用网络驱动器作为数据路径
   - 如必须使用，确保网络连接稳定

4. **多用户环境**：
   - 为每个用户设置独立的数据路径
   - 避免路径冲突

## 故障排除

### 应用无法启动
1. 检查数据路径是否存在
2. 检查路径权限
3. 删除配置文件重新设置

### 数据丢失
1. 检查旧数据路径
2. 查看备份文件
3. 联系技术支持

### 性能问题
1. 检查磁盘速度
2. 优化数据路径位置
3. 清理临时文件

## 技术支持

如遇到问题，请提供以下信息：
- 应用版本号
- 操作系统版本
- 错误信息截图
- 数据路径配置信息

联系方式：[技术支持邮箱或链接]
