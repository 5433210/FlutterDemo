# 统一升级系统设计文档

## 1. 概述

### 1.1 设计目标

- 统一处理数据备份恢复和应用升级中的版本兼容性问题
- 支持跨版本数据升级（如 v1→v3）的链式处理
- 与现有 migrations.dart 数据库脚本机制保持兼容
- 提供可扩展的升级框架，支持预处理、重启、后处理三阶段

### 1.2 核心原则

- **数据版本独立**: 使用独立的数据版本管理，减少维护复杂度
- **链式升级**: 支持跨版本升级链（v1→v2→v3）
- **兼容现有机制**: 与现有 migrations.dart 无缝集成
- **三阶段处理**: 预处理→重启→后处理的完整流程

## 2. 数据版本管理体系

### 2.1 数据版本定义

```dart
class DataVersionDefinition {
  static const Map<String, DataVersionInfo> versions = {
    'v1': DataVersionInfo(
      version: 'v1',
      description: '基础数据结构',
      appVersions: ['1.0.0', '1.0.1', '1.0.2'],
      databaseVersion: 5,  // 对应 migrations.dart 中的版本
      features: ['基础作品管理', '字符收集'],
    ),
    'v2': DataVersionInfo(
      version: 'v2', 
      description: '练习功能',
      appVersions: ['1.1.0', '1.1.1', '1.2.0'],
      databaseVersion: 10,
      features: ['练习模式', '用户偏好设置'],
    ),
    'v3': DataVersionInfo(
      version: 'v3',
      description: '增强作品管理',
      appVersions: ['1.3.0', '1.3.5', '1.3.6'],
      databaseVersion: 15,
      features: ['高级作品管理', '元数据支持'],
    ),
    'v4': DataVersionInfo(
      version: 'v4',
      description: '高级功能',
      appVersions: ['1.4.0', '1.5.0'],
      databaseVersion: 18,
      features: ['库管理', '高级导出'],
    ),
  };
}
```

### 2.2 统一的backup_info.json结构

```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "description": "用户描述或自动生成",
  "appVersion": "1.3.5",
  "dataVersion": "v3",
  "platform": "windows",
  "dataIntegrity": {
    "checksum": "sha256_hash",
    "fileCount": 1234,
    "totalSize": 567890
  }
}
```

### 2.3 版本映射服务

```dart
class DataVersionMappingService {
  /// 获取应用版本对应的数据版本
  static String getDataVersion(String appVersion) {
    for (final entry in DataVersionDefinition.versions.entries) {
      if (entry.value.appVersions.contains(appVersion)) {
        return entry.key;
      }
    }
    return 'unknown';
  }
  
  /// 获取数据版本对应的数据库版本
  static int getDatabaseVersion(String dataVersion) {
    return DataVersionDefinition.versions[dataVersion]?.databaseVersion ?? 0;
  }
  
  /// 获取升级路径
  static List<String> getUpgradePath(String fromVersion, String toVersion) {
    final versions = ['v1', 'v2', 'v3', 'v4'];
    final fromIndex = versions.indexOf(fromVersion);
    final toIndex = versions.indexOf(toVersion);
    
    if (fromIndex == -1 || toIndex == -1 || fromIndex >= toIndex) {
      return [];
    }
    
    return versions.sublist(fromIndex, toIndex + 1);
  }
}
```

## 3. 兼容性矩阵系统

### 3.1 基于数据版本的兼容性矩阵

```text
当前数据版本 \ 备份数据版本   v1    v2    v3    v4
v1                        C     A     A     A
v2                        D     C     A     A
v3                        D     D     C     A
v4                        N     D     D     C
```

**说明**:

- **C (Compatible)**: 完全兼容，直接使用
- **D (Data Upgrade)**: 需要数据升级，支持链式升级
- **A (App Upgrade)**: 需要升级应用
- **N (Not Compatible)**: 不兼容，不再支持

### 3.2 兼容性检查服务

```dart
class UnifiedCompatibilityService {
  /// 检查数据版本兼容性
  static CompatibilityResult checkDataVersionCompatibility(
    String currentDataVersion,
    String backupDataVersion,
  ) {
    // 实现兼容性矩阵逻辑
    if (currentDataVersion == backupDataVersion) {
      return CompatibilityResult.compatible();
    }
    
    final upgradePath = DataVersionMappingService.getUpgradePath(
      backupDataVersion, 
      currentDataVersion
    );
    
    if (upgradePath.isEmpty) {
      return CompatibilityResult.incompatible();
    }
    
    if (upgradePath.length > 3) {
      return CompatibilityResult.notSupported(); // v1->v4 跨度太大
    }
    
    return CompatibilityResult.needsUpgrade(upgradePath);
  }
}
```

## 4. 跨版本升级处理

### 4.1 升级链管理器

```dart
class UpgradeChainManager {
  /// 执行跨版本升级链
  Future<bool> executeUpgradeChain(
    List<String> upgradePath,
    String dataPath,
  ) async {
    try {
      // 创建数据快照
      final snapshot = await _createDataSnapshot(dataPath);
      
      // 执行升级链
      for (int i = 0; i < upgradePath.length - 1; i++) {
        final fromVersion = upgradePath[i];
        final toVersion = upgradePath[i + 1];
        
        final adapter = _getAdapter(fromVersion, toVersion);
        if (adapter == null) {
          throw Exception('找不到适配器: $fromVersion -> $toVersion');
        }
        
        // 执行单步升级
        final success = await _executeSingleUpgrade(adapter, dataPath);
        if (!success) {
          await _restoreFromSnapshot(snapshot);
          return false;
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('升级链执行失败', error: e);
      return false;
    }
  }
}
```

### 4.2 单步升级适配器

```dart
abstract class DataVersionAdapter {
  /// 源数据版本
  String get sourceDataVersion;

  /// 目标数据版本
  String get targetDataVersion;

  /// 预处理阶段
  Future<PreProcessResult> preProcess(String dataPath);

  /// 后处理阶段（重启后执行）
  Future<PostProcessResult> postProcess(String dataPath);

  /// 验证适配结果
  Future<bool> validateAdaptation(String dataPath);

  /// 与现有数据库迁移集成
  Future<void> integrateDatabaseMigration(String dataPath);
}

/// 预处理结果
class PreProcessResult {
  final bool success;
  final bool needsRestart;
  final Map<String, dynamic> stateData;
  final String? errorMessage;

  const PreProcessResult({
    required this.success,
    this.needsRestart = false,
    this.stateData = const {},
    this.errorMessage,
  });
}

/// 后处理结果
class PostProcessResult {
  final bool success;
  final List<String> executedSteps;
  final String? errorMessage;

  const PostProcessResult({
    required this.success,
    this.executedSteps = const [],
    this.errorMessage,
  });
}
```

## 5. 与现有 migrations.dart 的集成

### 5.1 数据库升级集成策略

```dart
class DatabaseMigrationIntegration {
  /// 集成现有迁移机制
  static Future<void> integrateWithExistingMigrations(
    String fromDataVersion,
    String toDataVersion,
    String databasePath,
  ) async {
    final fromDbVersion = DataVersionMappingService.getDatabaseVersion(fromDataVersion);
    final toDbVersion = DataVersionMappingService.getDatabaseVersion(toDataVersion);
    
    if (fromDbVersion >= toDbVersion) {
      return; // 无需数据库升级
    }
    
    // 使用现有的 SQLite onUpgrade 机制
    final db = await openDatabase(
      databasePath,
      version: toDbVersion,
      onUpgrade: (db, oldVersion, newVersion) async {
        // 执行现有的迁移脚本
        for (var i = oldVersion; i < newVersion; i++) {
          await db.execute(migrations[i]);
        }
      },
    );
    
    await db.close();
  }
}
```

### 5.2 保持兼容性的策略

**选择方案**: **保持兼容并扩展**

**理由**:

1. 现有 migrations.dart 机制已经稳定运行
2. 数据库版本号与数据版本有明确映射关系
3. 可以在现有基础上添加数据版本适配层

**实现方式**:

- 保留现有 migrations.dart 的所有脚本
- 添加数据版本到数据库版本的映射
- 在数据版本适配器中调用现有的数据库升级逻辑
- 扩展处理文件结构、配置等非数据库升级

## 6. 三阶段升级流程

### 6.1 完整升级流程

```dart
class UnifiedUpgradeService {
  /// 执行完整升级流程
  Future<bool> executeUpgrade(
    String fromDataVersion,
    String toDataVersion,
    String dataPath,
  ) async {
    final upgradePath = DataVersionMappingService.getUpgradePath(
      fromDataVersion, 
      toDataVersion
    );
    
    if (upgradePath.isEmpty) {
      return false;
    }
    
    // 阶段1: 预处理
    final preProcessSuccess = await _executePreProcessPhase(upgradePath, dataPath);
    if (!preProcessSuccess) return false;
    
    // 阶段2: 检查是否需要重启
    final needsRestart = await _checkRestartRequired(upgradePath);
    if (needsRestart) {
      await _saveUpgradeState(upgradePath, dataPath);
      await _restartApplication();
      return true; // 重启后继续
    }
    
    // 阶段3: 后处理
    return await _executePostProcessPhase(upgradePath, dataPath);
  }
}
```

### 6.2 预处理阶段实现

```dart
class PreProcessPhase {
  Future<bool> _executePreProcessPhase(
    List<String> upgradePath,
    String dataPath,
  ) async {
    for (int i = 0; i < upgradePath.length - 1; i++) {
      final fromVersion = upgradePath[i];
      final toVersion = upgradePath[i + 1];

      final adapter = _getAdapter(fromVersion, toVersion);
      final result = await adapter.preProcess(dataPath);

      if (!result.success) {
        return false;
      }
    }
    return true;
  }
}
```

### 6.3 后处理阶段实现

```dart
class PostProcessPhase {
  Future<bool> _executePostProcessPhase(
    List<String> upgradePath,
    String dataPath,
  ) async {
    for (int i = 0; i < upgradePath.length - 1; i++) {
      final fromVersion = upgradePath[i];
      final toVersion = upgradePath[i + 1];

      final adapter = _getAdapter(fromVersion, toVersion);

      // 集成数据库迁移
      await adapter.integrateDatabaseMigration(dataPath);

      // 执行后处理
      final result = await adapter.postProcess(dataPath);

      if (!result.success) {
        return false;
      }
    }
    return true;
  }
}
```

## 7. 具体适配器实现示例

### 7.1 v1 到 v2 适配器

```dart
class DataAdapter_v1_to_v2 implements DataVersionAdapter {
  @override
  String get sourceDataVersion => 'v1';

  @override
  String get targetDataVersion => 'v2';

  @override
  Future<PreProcessResult> preProcess(String dataPath) async {
    try {
      // 预处理：创建练习功能所需的目录结构
      await Directory('$dataPath/practices').create(recursive: true);

      // 预处理：转换配置文件格式
      await _convertConfigForPractices(dataPath);

      return PreProcessResult(
        success: true,
        needsRestart: false, // v1->v2 不需要重启
      );
    } catch (e) {
      return PreProcessResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<PostProcessResult> postProcess(String dataPath) async {
    try {
      // 后处理：初始化练习数据
      await _initializePracticeData(dataPath);

      return PostProcessResult(success: true);
    } catch (e) {
      return PostProcessResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<bool> validateAdaptation(String dataPath) async {
    try {
      // 验证练习功能目录结构
      final practicesDir = Directory('$dataPath/practices');
      if (!await practicesDir.exists()) return false;

      // 验证配置文件格式
      final configFile = File('$dataPath/config.json');
      if (await configFile.exists()) {
        final config = jsonDecode(await configFile.readAsString());
        if (!config.containsKey('practiceSettings')) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> integrateDatabaseMigration(String dataPath) async {
    // 集成现有数据库迁移：v1(db版本5) -> v2(db版本10)
    await DatabaseMigrationIntegration.integrateWithExistingMigrations(
      'v1', 'v2', '$dataPath/app.db'
    );
  }
}
```

### 7.2 v2 到 v3 适配器

```dart
class DataAdapter_v2_to_v3 implements DataVersionAdapter {
  @override
  String get sourceDataVersion => 'v2';

  @override
  String get targetDataVersion => 'v3';

  @override
  Future<PreProcessResult> preProcess(String dataPath) async {
    try {
      // 预处理：重组作品目录结构
      await _reorganizeWorksStructure(dataPath);

      // 预处理：准备元数据迁移
      await _prepareMetadataMigration(dataPath);

      return PreProcessResult(
        success: true,
        needsRestart: true, // v2->v3 需要重启以加载新的作品管理结构
        stateData: {'migrationTimestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      return PreProcessResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<PostProcessResult> postProcess(String dataPath) async {
    try {
      // 后处理：迁移作品元数据
      await _migrateWorksMetadata(dataPath);

      // 后处理：更新索引
      await _updateSearchIndexes(dataPath);

      return PostProcessResult(
        success: true,
        executedSteps: ['metadata_migration', 'index_update'],
      );
    } catch (e) {
      return PostProcessResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<bool> validateAdaptation(String dataPath) async {
    try {
      // 验证作品目录结构重组
      final worksDir = Directory('$dataPath/works');
      if (!await worksDir.exists()) return false;

      // 验证元数据文件
      await for (final entity in worksDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final workData = jsonDecode(await entity.readAsString());
          if (!workData.containsKey('metadata')) return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> integrateDatabaseMigration(String dataPath) async {
    // 集成现有数据库迁移：v2(db版本10) -> v3(db版本15)
    await DatabaseMigrationIntegration.integrateWithExistingMigrations(
      'v2', 'v3', '$dataPath/app.db'
    );
  }
}
```

### 7.3 跨版本升级示例（v1→v3）

```dart
class CrossVersionUpgradeExample {
  /// 演示 v1 -> v3 的跨版本升级
  static Future<bool> upgradeV1ToV3(String dataPath) async {
    final upgradePath = ['v1', 'v2', 'v3'];

    // 第一步：v1 -> v2
    final adapter_v1_v2 = DataAdapter_v1_to_v2();

    // 预处理阶段
    final preResult1 = await adapter_v1_v2.preProcess(dataPath);
    if (!preResult1.success) return false;

    // 数据库迁移：v1(db版本5) -> v2(db版本10)
    await adapter_v1_v2.integrateDatabaseMigration(dataPath);

    // 后处理阶段
    final postResult1 = await adapter_v1_v2.postProcess(dataPath);
    if (!postResult1.success) return false;

    // 第二步：v2 -> v3
    final adapter_v2_v3 = DataAdapter_v2_to_v3();

    // 预处理阶段
    final preResult2 = await adapter_v2_v3.preProcess(dataPath);
    if (!preResult2.success) return false;

    // 检查是否需要重启
    if (preResult2.needsRestart) {
      await _saveUpgradeState(['v2', 'v3'], dataPath);
      await _restartApplication();
      return true; // 重启后继续
    }

    // 数据库迁移：v2(db版本10) -> v3(db版本15)
    await adapter_v2_v3.integrateDatabaseMigration(dataPath);

    // 后处理阶段
    final postResult2 = await adapter_v2_v3.postProcess(dataPath);
    return postResult2.success;
  }
}
```

## 8. 应用升级集成

### 8.1 应用升级检查服务

```dart
class AppUpgradeService {
  /// 检查应用升级需求
  static Future<AppUpgradeResult> checkUpgradeNeeded() async {
    final currentAppVersion = await _getCurrentAppVersion();
    final dataPath = await _getDataPath();
    final dataVersionInfo = await _getDataVersionInfo(dataPath);

    if (dataVersionInfo == null) {
      return AppUpgradeResult.newInstallation();
    }

    final currentDataVersion = DataVersionMappingService.getDataVersion(currentAppVersion);
    final compatibility = UnifiedCompatibilityService.checkDataVersionCompatibility(
      currentDataVersion,
      dataVersionInfo.version,
    );

    switch (compatibility.type) {
      case CompatibilityType.compatible:
        return AppUpgradeResult.noUpgradeNeeded();
      case CompatibilityType.needsDataUpgrade:
        return AppUpgradeResult.dataUpgradeNeeded(compatibility.upgradePath);
      case CompatibilityType.needsAppUpgrade:
        return AppUpgradeResult.appUpgradeNeeded();
      case CompatibilityType.incompatible:
        return AppUpgradeResult.incompatible();
    }
  }

  /// 执行应用启动时的自动升级
  static Future<bool> executeStartupUpgrade() async {
    final upgradeResult = await checkUpgradeNeeded();

    switch (upgradeResult.type) {
      case AppUpgradeType.dataUpgradeNeeded:
        return await _executeDataUpgrade(upgradeResult.upgradePath);
      case AppUpgradeType.noUpgradeNeeded:
      case AppUpgradeType.newInstallation:
        return true;
      case AppUpgradeType.appUpgradeNeeded:
      case AppUpgradeType.incompatible:
        return false;
    }
  }
}
```

### 8.2 启动时升级集成

```dart
class StartupUpgradeIntegration {
  /// 在应用初始化时集成升级检查
  static Future<void> integrateWithAppInitialization(WidgetRef ref) async {
    try {
      // 1. 检查是否需要升级
      final upgradeResult = await AppUpgradeService.checkUpgradeNeeded();

      // 2. 根据升级结果执行相应操作
      switch (upgradeResult.type) {
        case AppUpgradeType.dataUpgradeNeeded:
          AppLogger.info('检测到数据需要升级', data: {
            'upgradePath': upgradeResult.upgradePath,
          });

          final success = await AppUpgradeService.executeStartupUpgrade();
          if (!success) {
            throw Exception('数据升级失败');
          }
          break;

        case AppUpgradeType.appUpgradeNeeded:
          AppLogger.warning('应用版本过低，需要升级应用');
          // 可以显示升级提示或阻止应用启动
          break;

        case AppUpgradeType.incompatible:
          AppLogger.error('数据版本不兼容');
          throw Exception('数据版本不兼容，请使用对应版本的应用');

        case AppUpgradeType.noUpgradeNeeded:
        case AppUpgradeType.newInstallation:
          // 无需升级，正常启动
          break;
      }

    } catch (e) {
      AppLogger.error('启动升级检查失败', error: e);
      rethrow;
    }
  }
}
```

## 9. 错误处理和回滚机制

### 9.1 升级状态管理

```dart
class UpgradeStateManager {
  /// 保存升级状态
  static Future<void> saveUpgradeState(UpgradeState state) async {
    final stateFile = File('${state.dataPath}/.upgrade_state.json');
    await stateFile.writeAsString(jsonEncode(state.toJson()));
  }

  /// 加载升级状态
  static Future<UpgradeState?> loadUpgradeState(String dataPath) async {
    final stateFile = File('$dataPath/.upgrade_state.json');
    if (!await stateFile.exists()) return null;

    final content = await stateFile.readAsString();
    return UpgradeState.fromJson(jsonDecode(content));
  }

  /// 清理升级状态
  static Future<void> clearUpgradeState(String dataPath) async {
    final stateFile = File('$dataPath/.upgrade_state.json');
    if (await stateFile.exists()) {
      await stateFile.delete();
    }
  }
}
```

### 9.2 回滚机制

```dart
class UpgradeRollbackManager {
  /// 创建升级前快照
  static Future<String> createUpgradeSnapshot(String dataPath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final snapshotPath = '$dataPath/.snapshots/upgrade_$timestamp';

    await Directory(snapshotPath).create(recursive: true);

    // 复制关键数据
    await _copyDirectory(dataPath, snapshotPath, excludePatterns: ['.snapshots']);

    return snapshotPath;
  }

  /// 回滚到快照
  static Future<void> rollbackToSnapshot(String dataPath, String snapshotPath) async {
    // 清理当前数据
    await _cleanupDataPath(dataPath);

    // 恢复快照数据
    await _copyDirectory(snapshotPath, dataPath);

    // 清理快照
    await Directory(snapshotPath).delete(recursive: true);
  }
}
```

## 10. 扩展性和维护性

### 10.1 新数据版本添加指南

1. **定义新数据版本**: 在 `DataVersionDefinition` 中添加新版本信息
2. **创建适配器**: 实现从上一版本到新版本的适配器
3. **更新兼容性矩阵**: 在兼容性矩阵中添加新版本的兼容性规则
4. **添加数据库迁移**: 在 `migrations.dart` 中添加相应的数据库迁移脚本
5. **编写测试**: 为新适配器编写完整的单元测试和集成测试

### 10.2 维护最佳实践

- **版本号管理**: 使用语义化版本号，数据版本变更时递增数据版本
- **向后兼容**: 新版本应能处理旧版本数据，避免破坏性变更
- **测试覆盖**: 每个升级路径都应有对应的测试用例
- **文档同步**: 保持设计文档与实际实现的同步

### 10.3 与现有系统的集成点

1. **数据库迁移**: 完全兼容现有 `migrations.dart` 机制
2. **应用初始化**: 集成到现有的 `AppInitializationService`
3. **备份恢复**: 与现有备份恢复系统无缝集成
4. **错误处理**: 使用现有的 `AppLogger` 和错误处理机制

---

*文档生成时间: 2025-07-25*
*版本: 1.0*
*设计重点: 统一升级系统架构，支持跨版本升级和现有机制集成*
