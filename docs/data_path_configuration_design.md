# 数据路径配置功能设计文档

## 项目概述

本文档描述了为"字字珠玑"应用实现用户可配置数据路径功能的设计方案。该功能允许用户自定义应用数据存储位置，并支持路径切换后的应用重启机制。

## 需求分析

### 功能需求

1. **默认数据路径调整**：将默认数据路径从 `getApplicationDocumentsDirectory()` 调整为 `getApplicationSupportDirectory()/charasgem`
2. **用户自定义路径**：在设置界面提供路径配置子面板，允许用户自行设定新的数据存储路径
3. **路径切换重启**：用户设置新路径后，提示重启并实现应用重启功能
4. **配置文件管理**：在默认数据路径下的 `config.json` 中保存自定义路径配置
5. **启动路径检测**：应用启动时检测配置文件，决定使用哪个路径作为数据路径
6. **数据版本管理**：在每个数据路径下维护 `version.json` 文件，记录数据版本信息
7. **版本兼容性检查**：切换数据路径时检查版本兼容性，必要时执行数据升级

## 当前项目架构分析

### 存储系统现状

基于代码分析，当前项目的存储架构如下：

1. **存储接口层**：`IStorage` 接口定义基础存储操作
2. **存储实现层**：`LocalStorage` 类实现本地文件系统操作
3. **存储服务层**：各种专用存储服务（`WorkStorageService`、`PracticeStorageService` 等）
4. **Provider管理层**：使用 Riverpod 管理存储服务实例

### 当前存储初始化流程

```dart
// lib/infrastructure/providers/storage_providers.dart
final storageProvider = FutureProvider<IStorage>((ref) async {
  // 1. 获取存储路径
  final appDir = await getApplicationDocumentsDirectory();
  final storagePath = path.join(appDir.path, 'storage');

  // 2. 创建存储服务实例
  final storage = LocalStorage(basePath: storagePath);

  // 3. 初始化目录结构
  await _initializeStorageStructure(storage);

  return storage;
});
```

## 设计方案

### 1. 数据路径配置服务（DataPathConfigService）

```dart
/// 版本兼容性检查结果
enum VersionCompatibilityResult {
  /// 兼容或可以升级，可以直接使用
  compatible,
  /// 不兼容，无法使用
  incompatible,
  /// 新数据路径，没有现有数据
  newData,
  /// 未知状态
  unknown,
}

class DataPathConfigService {
  static const String _configFileName = 'config.json';
  static const String _versionFileName = 'version.json';
  static const String _customPathKey = 'customDataPath';
  
  /// 获取配置文件路径（始终在默认路径下）
  Future<String> getConfigFilePath() async {
    final defaultDir = await getApplicationSupportDirectory();
    final configDir = path.join(defaultDir.path, 'charasgem');
    await Directory(configDir).create(recursive: true);
    return path.join(configDir, _configFileName);
  }
  
  /// 获取当前应该使用的数据路径
  Future<String> getCurrentDataPath() async {
    try {
      final configPath = await getConfigFilePath();
      final configFile = File(configPath);
      
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = jsonDecode(content) as Map<String, dynamic>;
        final customPath = config[_customPathKey] as String?;
        
        if (customPath != null && await Directory(customPath).exists()) {
          return customPath;
        }
      }
    } catch (e) {
      AppLogger.warning('读取配置文件失败，使用默认路径', error: e);
    }
    
    // 返回默认路径
    return await getDefaultDataPath();
  }
  
  /// 获取默认数据路径
  Future<String> getDefaultDataPath() async {
    final defaultDir = await getApplicationSupportDirectory();
    return path.join(defaultDir.path, 'charasgem');
  }
  
  /// 设置新的数据路径
  Future<void> setCustomDataPath(String newPath) async {
    final configPath = await getConfigFilePath();
    final config = {_customPathKey: newPath};
    
    await File(configPath).writeAsString(jsonEncode(config));
    AppLogger.info('数据路径配置已更新', data: {'newPath': newPath});
  }
  
  /// 重置为默认路径
  Future<void> resetToDefaultPath() async {
    final configPath = await getConfigFilePath();
    final configFile = File(configPath);
    
    if (await configFile.exists()) {
      await configFile.delete();
    }
    
    AppLogger.info('数据路径已重置为默认');
  }
  
  /// 迁移数据到新路径
  Future<void> migrateDataToNewPath(String oldPath, String newPath) async {
    final oldDir = Directory(oldPath);
    final newDir = Directory(newPath);
    
    if (!await oldDir.exists()) return;
    
    await newDir.create(recursive: true);
    
    // 递归复制所有文件和目录
    await for (final entity in oldDir.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: oldPath);
      final newEntityPath = path.join(newPath, relativePath);
      
      if (entity is File) {
        await entity.copy(newEntityPath);
      } else if (entity is Directory) {
        await Directory(newEntityPath).create(recursive: true);
      }
    }
    
    AppLogger.info('数据迁移完成', data: {
      'from': oldPath,
      'to': newPath,
    });
  }
  
  /// 获取数据路径的版本文件路径
  String getVersionFilePath(String dataPath) {
    return path.join(dataPath, _versionFileName);
  }
  
  /// 检查数据路径是否存在旧数据
  Future<bool> hasExistingData(String dataPath) async {
    final versionFile = File(getVersionFilePath(dataPath));
    return await versionFile.exists();
  }
  
  /// 获取数据路径的版本信息
  Future<Map<String, dynamic>?> getDataVersionInfo(String dataPath) async {
    try {
      final versionFile = File(getVersionFilePath(dataPath));
      
      if (await versionFile.exists()) {
        final content = await versionFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.warning('读取数据版本信息失败', error: e, data: {
        'dataPath': dataPath,
      });
    }
    return null;
  }
  
  /// 更新数据路径的版本信息
  Future<void> updateDataVersionInfo(String dataPath) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionInfo = {
        'appVersion': packageInfo.version, // 应用版本（也是数据版本）
        'lastUpdateTime': DateTime.now().toIso8601String(),
        'createdTime': DateTime.now().toIso8601String(),
      };
      
      final versionFile = File(getVersionFilePath(dataPath));
      await versionFile.writeAsString(jsonEncode(versionInfo));
      
      AppLogger.info('数据版本信息已更新', data: {
        'dataPath': dataPath,
        'appVersion': versionInfo['appVersion'],
      });
    } catch (e) {
      AppLogger.error('更新数据版本信息失败', error: e, data: {
        'dataPath': dataPath,
      });
      rethrow;
    }
  }
  
  /// 检查数据版本兼容性
  Future<VersionCompatibilityResult> checkVersionCompatibility(String dataPath) async {
    final versionInfo = await getDataVersionInfo(dataPath);
    
    if (versionInfo == null) {
      // 没有版本文件，可能是新的数据路径
      return VersionCompatibilityResult.newData;
    }
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentAppVersion = Version.parse(packageInfo.version);
      final dataAppVersion = Version.parse(versionInfo['appVersion'] as String);
      
      // 检查版本兼容性（调整后的策略）
      if (currentAppVersion.major == dataAppVersion.major && 
          currentAppVersion >= dataAppVersion) {
        // 同主版本号且当前版本 >= 数据版本，兼容
        return VersionCompatibilityResult.compatible;
      } else {
        // 其他所有情况都视为不兼容
        return VersionCompatibilityResult.incompatible;
      }
    } catch (e) {
      AppLogger.warning('版本兼容性检查失败', error: e, data: {
        'dataPath': dataPath,
        'versionInfo': versionInfo,
      });
      return VersionCompatibilityResult.unknown;
    }
  }
  
  /// 升级数据版本
  Future<bool> upgradeDataVersion(String dataPath) async {
    try {
      final versionInfo = await getDataVersionInfo(dataPath);
      if (versionInfo == null) return false;
      
      final packageInfo = await PackageInfo.fromPlatform();
      
      AppLogger.info('开始升级数据版本', data: {
        'dataPath': dataPath,
        'oldAppVersion': versionInfo['appVersion'],
        'newAppVersion': packageInfo.version,
      });
      
      // 这里可以添加具体的数据升级逻辑
      // 例如：数据库结构迁移、文件格式转换等
      
      // 更新版本信息，保留原创建时间
      final updatedVersionInfo = {
        'appVersion': packageInfo.version,
        'lastUpdateTime': DateTime.now().toIso8601String(),
        'createdTime': versionInfo['createdTime'] ?? DateTime.now().toIso8601String(),
      };
      
      final versionFile = File(getVersionFilePath(dataPath));
      await versionFile.writeAsString(jsonEncode(updatedVersionInfo));
      
      AppLogger.info('数据版本升级完成', data: {
        'dataPath': dataPath,
        'newAppVersion': packageInfo.version,
      });
      
      return true;
    } catch (e) {
      AppLogger.error('数据版本升级失败', error: e, data: {
        'dataPath': dataPath,
      });
      return false;
    }
  }
}
```

### 6. 数据备份与恢复的版本管理集成

考虑到现有的数据备份与恢复功能，需要将版本管理机制完全集成到备份恢复流程中：

```dart
// 扩展 DataPathConfigService 以支持备份恢复
extension DataPathConfigServiceBackup on DataPathConfigService {
  
  /// 创建带版本信息的备份
  Future<String> createVersionedBackup(String dataPath, String backupPath) async {
    try {
      // 1. 获取当前数据版本信息
      final versionInfo = await getDataVersionInfo(dataPath);
      
      // 2. 创建备份元数据
      final backupMetadata = {
        'backupTime': DateTime.now().toIso8601String(),
        'appVersion': versionInfo?['appVersion'] ?? 'unknown',
      };
      
      // 3. 创建备份目录结构
      final backupDir = Directory(backupPath);
      await backupDir.create(recursive: true);
      
      // 4. 复制数据文件
      await _copyDataFiles(dataPath, backupPath);
      
      // 5. 保存备份元数据
      final metadataFile = File(path.join(backupPath, 'backup_metadata.json'));
      await metadataFile.writeAsString(jsonEncode(backupMetadata));
      
      AppLogger.info('版本化备份创建完成', data: {
        'dataPath': dataPath,
        'backupPath': backupPath,
        'metadata': backupMetadata,
      });
      
      return backupPath;
    } catch (e) {
      AppLogger.error('创建版本化备份失败', error: e, data: {
        'dataPath': dataPath,
        'backupPath': backupPath,
      });
      rethrow;
    }
  }
  
  /// 检查备份的版本兼容性
  Future<BackupCompatibilityResult> checkBackupCompatibility(String backupPath) async {
    try {
      final metadataFile = File(path.join(backupPath, 'backup_metadata.json'));
      
      if (!await metadataFile.exists()) {
        // 旧版本备份，没有元数据文件
        return BackupCompatibilityResult.legacyBackup;
      }
      
      final content = await metadataFile.readAsString();
      final metadata = jsonDecode(content) as Map<String, dynamic>;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentAppVersion = Version.parse(packageInfo.version);
      final backupAppVersion = Version.parse(metadata['appVersion'] as String);
      
      // 检查版本兼容性
      if (currentAppVersion.major == backupAppVersion.major && 
          currentAppVersion >= backupAppVersion) {
        return BackupCompatibilityResult.compatible;
      } else {
        return BackupCompatibilityResult.incompatible;
      }
    } catch (e) {
      AppLogger.warning('备份兼容性检查失败', error: e, data: {
        'backupPath': backupPath,
      });
      return BackupCompatibilityResult.unknown;
    }
  }
  
  /// 恢复数据并处理版本升级
  Future<bool> restoreDataWithVersionHandling(
    String backupPath, 
    String targetDataPath, {
    bool forceUpgrade = false,
  }) async {
    try {
      // 1. 检查备份兼容性
      final compatibility = await checkBackupCompatibility(backupPath);
      
      switch (compatibility) {
        case BackupCompatibilityResult.incompatible:
          if (!forceUpgrade) {
            AppLogger.error('备份数据不兼容，无法恢复', data: {
              'backupPath': backupPath,
              'targetPath': targetDataPath,
            });
            return false;
          }
          break;
          
        case BackupCompatibilityResult.compatible:
        case BackupCompatibilityResult.legacyBackup:
        case BackupCompatibilityResult.unknown:
          // 可以继续恢复
          break;
      }
      
      // 2. 创建目标目录
      final targetDir = Directory(targetDataPath);
      await targetDir.create(recursive: true);
      
      // 3. 恢复数据文件
      await _restoreDataFiles(backupPath, targetDataPath);
      
      // 4. 处理版本升级（如果需要）
      if (compatibility == BackupCompatibilityResult.legacyBackup) {
        await _upgradeRestoredData(targetDataPath);
      }
      
      // 5. 更新目标路径的版本信息
      await updateDataVersionInfo(targetDataPath);
      
      AppLogger.info('数据恢复完成', data: {
        'backupPath': backupPath,
        'targetPath': targetDataPath,
        'compatibility': compatibility.toString(),
      });
      
      return true;
    } catch (e) {
      AppLogger.error('数据恢复失败', error: e, data: {
        'backupPath': backupPath,
        'targetPath': targetDataPath,
      });
      return false;
    }
  }
  
  /// 获取备份的元数据信息
  Future<Map<String, dynamic>?> getBackupMetadata(String backupPath) async {
    try {
      final metadataFile = File(path.join(backupPath, 'backup_metadata.json'));
      
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.warning('读取备份元数据失败', error: e, data: {
        'backupPath': backupPath,
      });
    }
    return null;
  }
  
  /// 复制数据文件（排除临时文件和缓存）
  Future<void> _copyDataFiles(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    
    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: sourcePath);
      
      // 跳过临时文件和缓存文件
      if (_shouldSkipFile(relativePath)) continue;
      
      final targetEntityPath = path.join(targetPath, relativePath);
      
      if (entity is File) {
        await Directory(path.dirname(targetEntityPath)).create(recursive: true);
        await entity.copy(targetEntityPath);
      } else if (entity is Directory) {
        await Directory(targetEntityPath).create(recursive: true);
      }
    }
  }
  
  /// 恢复数据文件
  Future<void> _restoreDataFiles(String backupPath, String targetPath) async {
    final backupDir = Directory(backupPath);
    
    await for (final entity in backupDir.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: backupPath);
      
      // 跳过备份元数据文件
      if (relativePath == 'backup_metadata.json') continue;
      
      final targetEntityPath = path.join(targetPath, relativePath);
      
      if (entity is File) {
        await Directory(path.dirname(targetEntityPath)).create(recursive: true);
        await entity.copy(targetEntityPath);
      } else if (entity is Directory) {
        await Directory(targetEntityPath).create(recursive: true);
      }
    }
  }
  
  /// 升级恢复的数据
  Future<void> _upgradeRestoredData(String dataPath) async {
    // 这里实现具体的数据升级逻辑
    // 例如：数据库结构迁移、文件格式转换等
    
    AppLogger.info('开始升级恢复的数据', data: {
      'dataPath': dataPath,
    });
    
    // 示例：升级数据库文件
    // await _upgradeDatabaseFiles(dataPath);
    
    // 示例：转换配置文件格式
    // await _upgradeConfigFiles(dataPath);
    
    AppLogger.info('数据升级完成', data: {
      'dataPath': dataPath,
    });
  }
  
  /// 检查是否应该跳过某个文件
  bool _shouldSkipFile(String relativePath) {
    final skipPatterns = [
      'temp/',
      'cache/',
      '.tmp',
      '.lock',
      'logs/',
    ];
    
    return skipPatterns.any((pattern) => relativePath.contains(pattern));
  }
}

/// 备份兼容性检查结果
enum BackupCompatibilityResult {
  /// 兼容，可以直接恢复
  compatible,
  /// 不兼容，无法恢复
  incompatible,
  /// 旧版本备份（没有版本信息）
  legacyBackup,
  /// 未知状态
  unknown,
}
```

### 7. 备份恢复界面的版本管理集成

需要在现有的备份恢复界面中集成版本管理功能：

```dart
// lib/presentation/pages/settings/components/backup_settings.dart

class BackupSettings extends ConsumerStatefulWidget {
  const BackupSettings({super.key});

  @override
  ConsumerState<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends ConsumerState<BackupSettings> {
  
  /// 创建版本化备份
  Future<void> _createVersionedBackup() async {
    final configService = ref.read(dataPathConfigServiceProvider);
    final l10n = AppLocalizations.of(context);
    
    try {
      // 1. 选择备份位置
      final backupPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectBackupLocation,
      );
      
      if (backupPath == null) return;
      
      // 2. 获取当前数据路径
      final currentDataPath = await configService.getCurrentDataPath();
      
      // 3. 生成带时间戳的备份目录名
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupDir = path.join(backupPath, 'charasgem_backup_$timestamp');
      
      // 4. 显示进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.creatingBackup),
            ],
          ),
        ),
      );
      
      // 5. 创建版本化备份
      await configService.createVersionedBackup(currentDataPath, backupDir);
      
      Navigator.of(context).pop(); // 关闭进度对话框
      
      // 6. 显示成功信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupCreatedSuccessfully),
          action: SnackBarAction(
            label: l10n.openFolder,
            onPressed: () => _openBackupFolder(backupDir),
          ),
        ),
      );
      
    } catch (e) {
      Navigator.of(context).pop(); // 关闭进度对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.backupFailed}: $e')),
      );
    }
  }
  
  /// 恢复数据并处理版本冲突
  Future<void> _restoreDataWithVersionCheck() async {
    final configService = ref.read(dataPathConfigServiceProvider);
    final l10n = AppLocalizations.of(context);
    
    try {
      // 1. 选择备份文件夹
      final backupPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectBackupToRestore,
      );
      
      if (backupPath == null) return;
      
      // 2. 检查备份兼容性
      final compatibility = await configService.checkBackupCompatibility(backupPath);
      
      // 3. 根据兼容性结果显示不同的对话框
      switch (compatibility) {
        case BackupCompatibilityResult.incompatible:
          await _showIncompatibleBackupDialog(backupPath);
          return;
          
        case BackupCompatibilityResult.legacyBackup:
          final shouldContinue = await _showLegacyBackupDialog(backupPath);
          if (!shouldContinue) return;
          break;
          
        case BackupCompatibilityResult.compatible:
        case BackupCompatibilityResult.unknown:
          // 可以直接恢复
          break;
      }
      
      // 4. 确认恢复操作
      final confirmed = await _showRestoreConfirmDialog(backupPath);
      if (!confirmed) return;
      
      // 5. 选择恢复目标路径
      final targetPath = await _selectRestoreTarget();
      if (targetPath == null) return;
      
      // 6. 显示恢复进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.restoringData),
            ],
          ),
        ),
      );        // 7. 执行恢复
      final success = await configService.restoreDataWithVersionHandling(
        backupPath, 
        targetPath,
        forceUpgrade: compatibility == BackupCompatibilityResult.incompatible,
      );
      
      Navigator.of(context).pop(); // 关闭进度对话框
      
      if (success) {
        // 8. 询问是否切换到恢复的路径
        final shouldSwitch = await _showSwitchToRestoredPathDialog(targetPath);
        if (shouldSwitch) {
          await configService.setCustomDataPath(targetPath);
          await _showRestartDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailed)),
        );
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // 关闭进度对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.restoreFailed}: $e')),
      );
    }
  }
  
  /// 显示不兼容备份对话框
  Future<void> _showIncompatibleBackupDialog(String backupPath) async {
    final l10n = AppLocalizations.of(context);
    final metadata = await ref.read(dataPathConfigServiceProvider)
        .getBackupMetadata(backupPath);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.incompatibleBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.incompatibleBackupMessage),
            const SizedBox(height: 16),
            if (metadata != null) ...[
              Text('${l10n.backupVersion}: ${metadata['appVersion']}'),
              Text('${l10n.currentVersion}: ${await _getCurrentAppVersion()}'),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.incompatibleBackupWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.understand),
          ),
        ],
      ),
    );
  }
  
  /// 显示旧版本备份对话框
  Future<bool> _showLegacyBackupDialog(String backupPath) async {
    final l10n = AppLocalizations.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.legacyBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.legacyBackupMessage),
            const SizedBox(height: 16),
            Text(
              l10n.legacyBackupWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.continueRestore),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// 显示版本降级警告对话框
  Future<bool> _showDowngradeWarningDialog(String newPath) async {
    final l10n = AppLocalizations.of(context);
    final configService = ref.read(dataPathConfigServiceProvider);
    final dataVersionInfo = await configService.getDataVersionInfo(newPath);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionDowngradeWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.versionDowngradeWarningMessage),
            const SizedBox(height: 16),
            if (dataVersionInfo != null) ...[
              Text('${l10n.dataVersion}: ${dataVersionInfo['appVersion']}'),
              Text('${l10n.currentVersion}: ${await _getCurrentAppVersion()}'),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.versionDowngradeDataLossWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.continueAnyway),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// 获取当前应用版本
  Future<String> _getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  // ... 其他现有方法保持不变
}
```

### 2. 存储Provider重构

```dart
// lib/infrastructure/providers/storage_providers.dart

/// 数据路径配置服务Provider
final dataPathConfigServiceProvider = Provider<DataPathConfigService>((ref) {
  return DataPathConfigService();
});

/// 当前数据路径Provider
final currentDataPathProvider = FutureProvider<String>((ref) async {
  final configService = ref.watch(dataPathConfigServiceProvider);
  return await configService.getCurrentDataPath();
});

/// 存储服务Provider（重构版）
final storageProvider = FutureProvider<IStorage>((ref) async {
  AppLogger.debug('初始化存储服务', tag: 'Storage');

  try {
    // 1. 获取当前应该使用的存储路径
    final storagePath = await ref.watch(currentDataPathProvider.future);

    // 2. 创建存储服务实例
    final storage = LocalStorage(basePath: storagePath);

    // 3. 初始化目录结构
    await _initializeStorageStructure(storage);

    // 4. 确保数据路径有版本文件
    final configService = ref.watch(dataPathConfigServiceProvider);
    await configService.updateDataVersionInfo(storagePath);

    AppLogger.info('存储服务初始化完成', tag: 'Storage', data: {
      'storagePath': storagePath,
    });
    return storage;
  } catch (e, stack) {
    AppLogger.error('存储服务初始化失败', error: e, stackTrace: stack, tag: 'Storage');
    rethrow;
  }
});
```

### 3. 数据路径设置界面

```dart
// lib/presentation/pages/settings/components/data_path_settings.dart

class DataPathSettings extends ConsumerStatefulWidget {
  const DataPathSettings({super.key});

  @override
  ConsumerState<DataPathSettings> createState() => _DataPathSettingsState();
}

class _DataPathSettingsState extends ConsumerState<DataPathSettings> {
  String? _currentPath;
  String? _defaultPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPaths();
  }

  Future<void> _loadCurrentPaths() async {
    final configService = ref.read(dataPathConfigServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final currentPath = await configService.getCurrentDataPath();
      final defaultPath = await configService.getDefaultDataPath();
      
      setState(() {
        _currentPath = currentPath;
        _defaultPath = defaultPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 处理错误
    }
  }

  Future<void> _selectNewPath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择数据存储位置',
    );
    
    if (result != null) {
      await _confirmPathChange(result);
    }
  }

  Future<void> _confirmPathChange(String newPath) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeDataPathTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.changeDataPathMessage),
            const SizedBox(height: 16),
            Text('${l10n.currentPath}: $_currentPath'),
            Text('${l10n.newPath}: $newPath'),
            const SizedBox(height: 16),
            Text(
              l10n.changeDataPathWarning,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _changeDataPath(newPath);
    }
  }

  Future<void> _changeDataPath(String newPath) async {
    final configService = ref.read(dataPathConfigServiceProvider);
    final l10n = AppLocalizations.of(context);
    
    setState(() => _isLoading = true);
    
    try {
      // 1. 检查新路径是否有现有数据
      if (await configService.hasExistingData(newPath)) {
        // 2. 检查版本兼容性
        final compatibility = await configService.checkVersionCompatibility(newPath);
        
        switch (compatibility) {
          case VersionCompatibilityResult.incompatible:
            setState(() => _isLoading = false);
            await _showIncompatibleDataDialog(newPath);
            return;
            
          case VersionCompatibilityResult.compatible:
          case VersionCompatibilityResult.newData:
          case VersionCompatibilityResult.unknown:
            // 可以继续操作
            break;
        }
      }
      
      // 3. 迁移数据（如果需要）
      if (_currentPath != null && _currentPath != newPath) {
        await configService.migrateDataToNewPath(_currentPath!, newPath);
      }
      
      // 4. 更新版本信息
      await configService.updateDataVersionInfo(newPath);
      
      // 5. 更新配置
      await configService.setCustomDataPath(newPath);
      
      // 6. 提示重启
      await _showRestartDialog();
      
    } catch (e) {
      setState(() => _isLoading = false);
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.operationFailed}: $e')),
      );
    }
  }

  Future<void> _showRestartDialog() async {
    final l10n = AppLocalizations.of(context);
    
    final shouldRestart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.restartRequiredTitle),
        content: Text(l10n.restartRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restartNow),
          ),
        ],
      ),
    );
    
    if (shouldRestart == true && mounted) {
      await AppRestartService.restartApp(context);
    }
  }

  Future<void> _showIncompatibleDataDialog(String newPath) async {
    final l10n = AppLocalizations.of(context);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.incompatibleDataTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.incompatibleDataMessage),
            const SizedBox(height: 16),
            Text('${l10n.path}: $newPath'),
            const SizedBox(height: 16),
            Text(
              l10n.incompatibleDataWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.understand),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDataUpgradeDialog(String newPath) async {
    final l10n = AppLocalizations.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dataUpgradeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dataUpgradeMessage),
            const SizedBox(height: 16),
            Text('${l10n.path}: $newPath'),
            const SizedBox(height: 16),
            Text(
              l10n.dataUpgradeWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.upgrade),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<bool> _showDowngradeWarningDialog(String newPath) async {
    final l10n = AppLocalizations.of(context);
    final configService = ref.read(dataPathConfigServiceProvider);
    final dataVersionInfo = await configService.getDataVersionInfo(newPath);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.versionDowngradeWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.versionDowngradeWarningMessage),
            const SizedBox(height: 16),
            if (dataVersionInfo != null) ...[
              Text('${l10n.dataVersion}: ${dataVersionInfo['appVersion']}'),
              Text('${l10n.currentVersion}: ${await _getCurrentAppVersion()}'),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.versionDowngradeDataLossWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.continueAnyway),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// 获取当前应用版本
  Future<String> _getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  // ... 其他现有方法保持不变
}
```

### 4. 设置页面集成

```dart
// lib/presentation/pages/settings/m3_settings_page.dart

Widget _buildSettingsContent(BuildContext context, WidgetRef ref) {
  return Padding(
    padding: const EdgeInsets.all(AppSizes.m),
    child: ListView(
      children: const [
        AppearanceSettings(),
        Divider(),
        LanguageSettings(),
        Divider(),
        ConfigurationSettings(),
        Divider(),
        DataPathSettings(), // 新增数据路径设置
        Divider(),
        StorageSettings(),
        Divider(),
        BackupSettings(),
        Divider(),
        CacheSettings(),
        Divider(),
        AppVersionSettings(),
      ],
    ),
  );
}
```

### 5. 应用重启服务扩展

```dart
// lib/utils/app_restart_service.dart

class AppRestartService {
  /// 重启应用（为数据路径更改优化）
  static Future<void> restartAppForDataPathChange(
    BuildContext context, {
    String? reason,
  }) async {
    final l10n = AppLocalizations.of(context);
    
    // 显示特定的重启对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.restartingForDataPath),
              if reason != null ...[
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // 等待一段时间，让UI更新
    await Future.delayed(const Duration(milliseconds: 500));

    AppLogger.info('正在重启应用（数据路径更改）', tag: 'AppRestart', data: {
      'reason': reason,
    });

    // 调用通用重启方法
    await restartApp(context);
  }
  
  // 保持现有的 restartApp 方法不变
  static Future<void> restartApp(BuildContext context) async {
    // ... 现有实现
  }
}
```

## 实施计划

### 阶段一：基础设施搭建（1-2天）
1. 创建 `DataPathConfigService` 服务类
2. 重构存储Provider以支持动态路径
3. 添加路径配置相关的本地化字符串

### 阶段二：UI界面开发（2-3天）
1. 创建 `DataPathSettings` 组件
2. 集成到设置页面
3. 实现路径选择和确认对话框

### 阶段三：功能完善（1-2天）
1. 实现数据迁移功能
2. 完善错误处理和用户反馈
3. 添加必要的日志记录

### 阶段四：测试和优化（1-2天）
1. 单元测试和集成测试
2. 用户体验优化
3. 性能测试和内存泄漏检查

## 风险分析

### 技术风险
1. **数据迁移失败**：提供回滚机制和备份选项
2. **权限问题**：检查目标路径的读写权限
3. **路径冲突**：验证新路径的唯一性和有效性

### 用户体验风险
1. **数据丢失担忧**：提供清晰的说明和确认流程
2. **操作复杂性**：简化界面设计，提供默认选项

### 兼容性风险
1. **不同平台行为差异**：针对各平台进行充分测试
2. **现有数据处理**：确保向后兼容性

## 测试策略

### 单元测试
- `DataPathConfigService` 的各个方法
- 路径验证和配置读写功能
- 数据迁移逻辑

### 集成测试
- 完整的路径更改流程
- 应用重启后的数据加载
- 错误场景的处理

### 用户验收测试
- 路径更改的端到端流程
- 各种边界情况的处理
- 用户界面的易用性

## 维护考虑

### 日志记录
- 路径配置的变更记录
- 数据迁移过程的详细日志
- 错误和异常的完整堆栈跟踪

### 性能监控
- 数据迁移的时间和进度
- 存储访问性能的影响
- 内存使用情况的监控

### 向后兼容
- 旧版本配置文件的兼容处理
- 数据格式变更的平滑升级
- 用户数据的安全保护

### 版本管理
- **数据版本控制**：每个数据路径下的version.json文件记录数据版本信息
- **应用升级检测**：通过比较应用版本和数据版本判断兼容性
- **自动数据升级**：主版本兼容时自动升级数据格式
- **版本隔离保护**：不兼容版本无法访问，防止数据损坏
- **升级日志记录**：详细记录数据升级过程和结果

### 备份恢复版本管理
- **备份元数据保存**：每个备份包含完整的版本信息和创建时间
- **恢复前兼容性检查**：恢复前自动检查备份与当前应用的版本兼容性
- **跨版本数据升级**：支持从旧版本备份恢复到新版本应用
- **旧版本备份支持**：向下兼容没有版本信息的旧备份文件
- **备份格式版本化**：备份文件格式本身也版本化，支持未来备份格式升级

## 配置文件结构

### config.json 示例

```json
{
  "customDataPath": "C:\\Users\\UserName\\Documents\\CharAsGem"
}
```

### version.json 示例（位于每个数据路径下）

```json
{
  "appVersion": "1.2.3",
  "lastUpdateTime": "2025-07-09T10:30:00.000Z",
  "createdTime": "2025-07-09T10:30:00.000Z"
}
```

### backup_metadata.json 示例（位于备份根目录）

```json
{
  "backupTime": "2025-07-09T10:30:00.000Z",
  "appVersion": "1.2.3"
}
```

### 字段说明

#### config.json 字段
- **customDataPath**: 用户自定义的数据存储路径

#### version.json 字段
- **appVersion**: 创建/最后更新此数据时的应用版本
- **lastUpdateTime**: 数据最后更新时间（ISO 8601格式）
- **createdTime**: 数据创建时间（ISO 8601格式）

#### backup_metadata.json 字段
- **backupTime**: 备份创建时间（ISO 8601格式）
- **appVersion**: 备份时的应用版本

### 版本兼容性规则

本设计采用**语义化版本**（Semantic Versioning）规范，版本号格式为：`MAJOR.MINOR.PATCH`

#### 版本号含义
- **MAJOR（主版本号）**：包含不兼容的数据结构变更
- **MINOR（次版本号）**：向后兼容的功能性新增
- **PATCH（补丁版本号）**：向后兼容的问题修正

#### 数据路径版本兼容性规则

1. **兼容或可以升级** (`VersionCompatibilityResult.compatible`) ✅
   - 条件：`当前应用版本.major == 数据版本.major` 且 `当前应用版本 >= 数据版本`
   - 示例：当前应用 `2.1.0`，数据版本 `2.0.5` → 兼容
   - 处理：直接使用，如果数据版本较低则自动升级版本信息

2. **不兼容 - 无法直接升级** (`VersionCompatibilityResult.incompatible`) 🔄
   - 条件：`当前应用版本.major > 数据版本.major`
   - 示例：当前应用 `2.0.0`，数据版本 `1.9.0` → 不兼容
   - 处理：拒绝使用该数据路径，数据结构可能无法适配，需要使用额外的数据迁移工具

3. **不兼容 - 需要更新应用** (`VersionCompatibilityResult.incompatible`) 🔄
   - 条件：`当前应用版本 < 数据版本`（包括主版本号和次版本号）
   - 示例：
     - 当前应用 `1.9.0`，数据版本 `2.0.0` → 不兼容
     - 当前应用 `2.0.0`，数据版本 `2.1.0` → 不兼容
   - 处理：拒绝使用该数据路径，提示用户更新应用版本来适配数据版本

4. **新数据路径** (`VersionCompatibilityResult.newData`) 🆕
   - 条件：数据路径下没有 `version.json` 文件
   - 处理：创建新的版本文件，使用当前应用版本

5. **未知状态** (`VersionCompatibilityResult.unknown`) ❓
   - 条件：版本解析失败或其他异常情况
   - 处理：谨慎处理，可能需要用户手动确认

#### 备份恢复版本兼容性规则

1. **兼容或可以升级** (`BackupCompatibilityResult.compatible`) ✅
   - 条件：`当前应用版本.major == 备份版本.major` 且 `当前应用版本 >= 备份版本`
   - 处理：直接恢复，如果备份版本较低则自动升级版本信息

2. **不兼容 - 无法直接升级** (`BackupCompatibilityResult.incompatible`) 🔄
   - 条件：`当前应用版本.major > 备份版本.major`
   - 处理：拒绝恢复，备份数据结构可能无法适配，需要使用额外的数据迁移工具

3. **不兼容 - 需要更新应用** (`BackupCompatibilityResult.incompatible`) 🔄
   - 条件：`当前应用版本 < 备份版本`
   - 处理：拒绝恢复，提示用户更新应用版本来适配备份版本

4. **旧版本备份** (`BackupCompatibilityResult.legacyBackup`) 📦
   - 条件：备份中没有 `backup_metadata.json` 文件
   - 处理：提示用户这是旧版本备份，确认后按兼容版本处理

5. **未知状态** (`BackupCompatibilityResult.unknown`) ❓
   - 条件：备份元数据解析失败或其他异常情况
   - 处理：谨慎处理，可能需要用户手动确认

#### 实际应用示例

| 当前应用版本 | 数据/备份版本 | 兼容性结果 | 处理方式 |
|-------------|--------------|-----------|----------|
| 1.0.0 | 1.0.0 | compatible ✅ | 直接使用 |
| 1.2.0 | 1.0.5 | compatible ✅ | 直接使用，自动升级版本信息 |
| 1.0.0 | 1.2.0 | incompatible 🔄 | 拒绝使用，提示更新应用 |
| 2.0.0 | 1.9.0 | incompatible 🔄 | 拒绝使用，需要数据迁移工具 |
| 1.5.0 | 2.0.0 | incompatible 🔄 | 拒绝使用，提示更新应用 |
| 2.1.0 | (无版本文件) | newData 🆕 | 创建版本文件 |

#### 数据升级策略

1. **同主版本内自动升级**（如 2.0.x → 2.1.x）
   - 仅更新版本号和时间戳
   - 不执行数据迁移，保持数据结构不变
   - 自动完成，无需用户确认

2. **跨主版本迁移**（如 1.x → 2.x）
   - 不支持自动升级，视为不兼容
   - 需要使用专门的数据迁移工具
   - 可能包括文件格式转换、数据库结构变更等

3. **版本降级处理**
   - 一律视为不兼容，拒绝使用
   - 提示用户更新应用版本
   - 确保数据完整性和功能可用性

## 总结

本设计方案通过引入 `DataPathConfigService` 和重构存储Provider，实现了用户可配置的数据路径功能。该方案充分利用了现有的存储架构，最小化了对现有代码的影响，同时提供了完整的用户界面和错误处理机制。

关键特性：

- **无缝集成**：与现有存储系统完美融合
- **用户友好**：直观的设置界面和清晰的操作流程
- **数据安全**：完整的数据迁移和备份机制
- **平台兼容**：支持所有目标平台的特性
- **可维护性**：清晰的代码结构和完整的日志记录
