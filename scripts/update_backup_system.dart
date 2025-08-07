#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';

/// 配置更新脚本
/// 用于更新项目配置，集成新的备份系统
void main() async {
  print('开始更新项目配置以集成新的备份系统...');

  try {
    // 1. 检查必要的依赖
    await _checkDependencies();

    // 2. 更新 pubspec.yaml
    await _updatePubspec();

    // 3. 创建示例配置
    await _createSampleConfig();

    print('✅ 项目配置更新完成！');
    print('\n📋 接下来的步骤：');
    print('1. 运行 flutter pub get 获取新的依赖');
    print('2. 在主应用中初始化新的备份服务');
    print('3. 更新现有的备份相关代码以使用 EnhancedBackupService');
    print('4. 在设置界面添加备份位置设置和数据路径管理');
  } catch (e) {
    print('❌ 配置更新失败: $e');
    exit(1);
  }
}

Future<void> _checkDependencies() async {
  print('📦 检查依赖...');

  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    throw Exception('未找到 pubspec.yaml 文件');
  }

  final content = await pubspecFile.readAsString();

  final requiredDeps = [
    'shared_preferences',
    'file_picker',
    'path',
    'crypto',
  ];

  final missingDeps = <String>[];
  for (final dep in requiredDeps) {
    if (!content.contains(dep)) {
      missingDeps.add(dep);
    }
  }

  if (missingDeps.isNotEmpty) {
    print('⚠️  缺少以下依赖: ${missingDeps.join(', ')}');
    print('   这些依赖将在下一步中添加');
  }
}

Future<void> _updatePubspec() async {
  print('📝 更新 pubspec.yaml...');

  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();

  // 检查是否需要添加依赖
  final dependencies = [
    'shared_preferences: ^2.2.2',
    'file_picker: ^6.1.1',
    'crypto: ^3.0.3',
  ];

  final lines = content.split('\n');
  final dependencyStartIndex =
      lines.indexWhere((line) => line.trim() == 'dependencies:');

  if (dependencyStartIndex == -1) {
    throw Exception('在 pubspec.yaml 中未找到 dependencies 部分');
  }

  final newLines = <String>[];
  bool inDependencies = false;
  bool dependenciesAdded = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    newLines.add(line);

    if (line.trim() == 'dependencies:') {
      inDependencies = true;
    } else if (inDependencies && line.trim().isEmpty && !dependenciesAdded) {
      // 在 dependencies 部分的末尾添加新依赖
      for (final dep in dependencies) {
        if (!content.contains(dep.split(':')[0])) {
          newLines.add('  $dep');
        }
      }
      dependenciesAdded = true;
      inDependencies = false;
    } else if (inDependencies && line.startsWith('dev_dependencies:')) {
      // 遇到 dev_dependencies，在此之前添加依赖
      if (!dependenciesAdded) {
        for (final dep in dependencies) {
          if (!content.contains(dep.split(':')[0])) {
            newLines.insert(newLines.length - 1, '  $dep');
          }
        }
        dependenciesAdded = true;
      }
      inDependencies = false;
    }
  }

  // 如果还没有添加依赖（文件末尾）
  if (inDependencies && !dependenciesAdded) {
    for (final dep in dependencies) {
      if (!content.contains(dep.split(':')[0])) {
        newLines.add('  $dep');
      }
    }
  }

  await pubspecFile.writeAsString(newLines.join('\n'));
  print('   ✅ pubspec.yaml 更新完成');
}

Future<void> _createSampleConfig() async {
  print('📋 创建示例配置...');

  // 创建集成说明文档
  final integrationDoc = File('docs/备份系统集成说明.md');
  await integrationDoc.parent.create(recursive: true);

  const docContent = '''
# 备份系统集成说明

## 概述

本项目已集成新的备份系统，支持：
- 配置文件统一管理的备份
- 数据路径切换
- 旧数据路径管理
- 增强的备份功能

## 集成步骤

### 1. 初始化服务

在应用启动时初始化备份服务：

```dart
// 在 main.dart 或服务初始化代码中
final serviceLocator = ServiceLocator();
serviceLocator.initializeWithRepositories(
  workRepository: workRepository,
  workImageRepository: workImageRepository,
  characterRepository: characterRepository,
  practiceRepository: practiceRepository,
  storage: storage,
  database: database, // 添加数据库接口
);
```

### 2. 使用增强备份服务

替换现有的备份服务使用：

```dart
// 获取增强备份服务
final backupService = ServiceLocator().get<EnhancedBackupService>();

// 创建备份
await backupService.createBackup(description: '重要更新前的备份');

// 获取所有备份
final backups = await backupService.getBackups();

// 恢复备份
await backupService.restoreBackup(backupId);
```

### 3. 添加界面

在设置页面添加新的管理界面：

```dart
// 备份位置设置
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const BackupLocationSettings(),
));

// 备份管理
Navigator.push(context, MaterialPageRoute(
  builder: (context) => BackupManagementPage(
    backupService: ServiceLocator().get<EnhancedBackupService>(),
  ),
));

// 数据路径管理
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const DataPathManagementPage(),
));
```

### 4. 迁移现有代码

将现有的备份相关代码迁移到新系统：

1. **备份创建**: 使用 `EnhancedBackupService.createBackup()`
2. **备份列表**: 使用 `EnhancedBackupService.getBackups()`
3. **备份恢复**: 使用 `EnhancedBackupService.restoreBackup()`
4. **备份删除**: 使用 `EnhancedBackupService.deleteBackup()`

### 5. 配置路径

用户首次使用时，需要：
1. 设置备份存储路径
2. 可选：切换数据存储路径
3. 管理历史数据路径

## 文件结构

新增的文件：
- `lib/domain/models/backup_models.dart` - 备份数据模型
- `lib/application/services/backup_registry_manager.dart` - 备份注册管理器
- `lib/application/services/enhanced_backup_service.dart` - 增强备份服务
- `lib/application/services/data_path_switch_manager.dart` - 数据路径切换管理器
- `lib/application/services/legacy_data_path_manager.dart` - 旧数据路径管理器
- `lib/presentation/pages/backup_location_settings.dart` - 备份位置设置界面
- `lib/presentation/pages/backup_management_page.dart` - 备份管理界面
- `lib/presentation/pages/data_path_management_page.dart` - 数据路径管理界面
- `lib/utils/file_utils.dart` - 文件工具类

## 注意事项

1. **兼容性**: 新系统与现有备份系统完全兼容
2. **数据安全**: 切换路径前会建议用户创建备份
3. **配置文件**: 备份配置存储在 `backup_registry.json`
4. **错误处理**: 所有操作都有完整的错误处理和日志记录

## 故障排除

### 备份路径未设置
```dart
// 检查是否设置了备份路径
final path = await BackupRegistryManager.getCurrentBackupPath();
if (path == null) {
  // 引导用户设置备份路径
}
```

### 配置文件损坏
```dart
// 清理无效备份引用
final removedCount = await BackupRegistryManager.cleanupInvalidReferences();
```

### 权限问题
确保备份路径有写入权限，数据路径切换时会验证权限。
''';

  await integrationDoc.writeAsString(docContent);
  print('   ✅ 集成说明文档已创建: ${integrationDoc.path}');

  // 创建示例使用代码
  final exampleFile = File('example/backup_system_usage.dart');
  await exampleFile.parent.create(recursive: true);

  const exampleContent = '''
// 示例：如何使用新的备份系统

import 'package:flutter/material.dart';
// 导入必要的服务和模型
import '../lib/application/services/enhanced_backup_service.dart';
import '../lib/application/services/service_locator.dart';
import '../lib/presentation/pages/backup_management_page.dart';
import '../lib/presentation/pages/backup_location_settings.dart';
import '../lib/presentation/pages/data_path_management_page.dart';

class BackupSystemExample {
  /// 示例：创建备份
  static Future<void> createBackupExample() async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      await backupService.createBackup(description: '重要更新前的备份');
      print('备份创建成功');
    } catch (e) {
      print('备份创建失败: \$e');
    }
  }
  
  /// 示例：获取备份列表
  static Future<void> listBackupsExample() async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      final backups = await backupService.getBackups();
      
      for (final backup in backups) {
        print('备份: \${backup.filename}');
        print('  描述: \${backup.description}');
        print('  大小: \${backup.size} 字节');
        print('  创建时间: \${backup.createdTime}');
        print('  位置: \${backup.location}');
      }
    } catch (e) {
      print('获取备份列表失败: \$e');
    }
  }
  
  /// 示例：恢复备份
  static Future<void> restoreBackupExample(String backupId) async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      await backupService.restoreBackup(backupId);
      print('备份恢复成功');
    } catch (e) {
      print('备份恢复失败: \$e');
    }
  }
}

/// 示例：在设置页面添加备份管理入口
class SettingsPageExample extends StatelessWidget {
  const SettingsPageExample({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 其他设置项...
          
          const Divider(),
          const ListTile(
            title: Text('备份与恢复'),
            subtitle: Text('管理应用数据备份'),
          ),
          
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份管理'),
            subtitle: const Text('创建、恢复和管理备份'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BackupManagementPage(
                  backupService: ServiceLocator().get<EnhancedBackupService>(),
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('备份位置设置'),
            subtitle: const Text('设置备份文件存储位置'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BackupLocationSettings(),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('数据路径管理'),
            subtitle: const Text('管理应用数据存储位置'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DataPathManagementPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
''';

  await exampleFile.writeAsString(exampleContent);
  print('   ✅ 示例代码已创建: ${exampleFile.path}');
}
