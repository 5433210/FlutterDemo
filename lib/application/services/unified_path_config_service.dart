import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/config/unified_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import 'backup_registry_manager.dart';
import 'data_path_config_service.dart';

/// 统一路径配置服务
///
/// 负责管理应用的数据存储路径和备份路径配置，包括：
/// - 读取和写入配置
/// - 路径有效性验证
/// - 版本兼容性检查
/// - 历史路径管理
class UnifiedPathConfigService {
  static const String _configKey = PathConfigConstants.unifiedPathConfigKey;
  static const String _backupPathKey = 'current_backup_path'; // 用于向后兼容
  static const String _oldConfigFileName = 'config.json'; // 用于迁移旧配置

  // 添加迁移标志，防止递归迁移
  static bool _migrationInProgress = false;

  /// 读取统一路径配置
  static Future<UnifiedPathConfig> readConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 检查SharedPreferences中是否已有统一配置
      if (prefs.containsKey(_configKey)) {
        final configJson = prefs.getString(_configKey);
        if (configJson != null) {
          final config = UnifiedPathConfig.fromJson(
              jsonDecode(configJson) as Map<String, dynamic>);

          // 验证配置
          if (config.backupPath.path.isEmpty) {
            // 如果备份路径为空，尝试从旧配置获取
            final oldBackupPath =
                await BackupRegistryManager.getCurrentBackupPath();
            if (oldBackupPath != null) {
              final updatedConfig = config.copyWith(
                backupPath: config.backupPath.copyWith(
                  path: oldBackupPath,
                ),
              );
              await writeConfig(updatedConfig);
              return updatedConfig;
            }
          }

          AppLogger.debug('从SharedPreferences读取统一路径配置成功',
              tag: 'UnifiedPathConfig');
          return config;
        }
      }

      // 如果SharedPreferences中没有配置，尝试从旧配置迁移
      AppLogger.debug('SharedPreferences中无统一配置，尝试从旧配置迁移',
          tag: 'UnifiedPathConfig');

      // 防止递归迁移
      if (_migrationInProgress) {
        AppLogger.warning('检测到迁移过程正在进行，返回默认配置', tag: 'UnifiedPathConfig');
        return UnifiedPathConfig.defaultConfig();
      }

      return await _migrateFromOldConfig();
    } catch (e, stack) {
      AppLogger.error('读取统一路径配置失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      // 发生错误时返回默认配置
      return UnifiedPathConfig.defaultConfig();
    }
  }

  /// 从旧配置迁移到新的统一配置
  static Future<UnifiedPathConfig> _migrateFromOldConfig() async {
    // 设置迁移标志，防止递归调用
    if (_migrationInProgress) {
      AppLogger.warning('迁移过程已在进行中，避免重复迁移', tag: 'UnifiedPathConfig');
      return UnifiedPathConfig.defaultConfig();
    }

    _migrationInProgress = true;

    try {
      AppLogger.info('开始从旧配置迁移到统一配置', tag: 'UnifiedPathConfig');

      // 1. 获取旧的数据路径配置
      final oldDataConfig = await DataPathConfigService.readConfig();

      // 2. 获取旧的备份路径
      final oldBackupPath = await BackupRegistryManager.getCurrentBackupPath();
      final historyBackupPaths =
          await BackupRegistryManager.getHistoryBackupPaths();

      // 3. 创建新的统一配置
      final dataSection = DataPathSection(
        useDefaultPath: oldDataConfig.useDefaultPath,
        customPath: oldDataConfig.customPath,
        historyPaths: oldDataConfig.historyPaths,
        requiresRestart: oldDataConfig.requiresRestart,
      );

      final backupSection = BackupPathSection(
        path: oldBackupPath ?? '',
        historyPaths: historyBackupPaths,
        createdTime: DateTime.now(),
        description: '从旧配置迁移的备份路径',
      );

      final unifiedConfig = UnifiedPathConfig(
        dataPath: dataSection,
        backupPath: backupSection,
        lastUpdated: DateTime.now(),
      );

      // 4. 保存新配置
      await writeConfig(unifiedConfig);

      // 5. 尝试删除旧的配置文件
      await _tryDeleteOldConfigFile();

      AppLogger.info('成功从旧配置迁移到统一配置', tag: 'UnifiedPathConfig');
      return unifiedConfig;
    } catch (e, stack) {
      AppLogger.error('从旧配置迁移失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return UnifiedPathConfig.defaultConfig();
    } finally {
      // 无论成功失败，都重置迁移标志
      _migrationInProgress = false;
    }
  }

  /// 尝试删除旧的配置文件
  static Future<void> _tryDeleteOldConfigFile() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final oldConfigPath =
          path.join(appSupportDir.path, 'charasgem', _oldConfigFileName);
      final oldConfigFile = File(oldConfigPath);

      if (await oldConfigFile.exists()) {
        await oldConfigFile.delete();
        AppLogger.info('已删除旧的配置文件: $oldConfigPath', tag: 'UnifiedPathConfig');
      }
    } catch (e) {
      AppLogger.warning('删除旧配置文件失败，但这不影响功能',
          error: e, tag: 'UnifiedPathConfig');
    }
  }

  /// 写入统一路径配置
  static Future<void> writeConfig(UnifiedPathConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 将配置转换为JSON字符串
      final configJson = jsonEncode(config.toJson());

      // 保存到SharedPreferences
      await prefs.setString(_configKey, configJson);

      // 为了向后兼容，同时更新旧的备份路径配置
      if (config.backupPath.path.isNotEmpty) {
        await prefs.setString(_backupPathKey, config.backupPath.path);
      }

      AppLogger.info('统一路径配置写入SharedPreferences成功', tag: 'UnifiedPathConfig');
    } catch (e, stack) {
      AppLogger.error('写入统一路径配置失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      rethrow;
    }
  }

  /// 设置数据路径
  static Future<bool> setDataPath(String newPath,
      {bool isDefault = false}) async {
    try {
      // 验证路径
      if (!isDefault) {
        final validationResult = await validatePath(newPath);
        if (!validationResult.isValid) {
          AppLogger.warning('数据路径验证失败: ${validationResult.errorMessage}',
              tag: 'UnifiedPathConfig');
          return false;
        }
      }

      // 读取当前配置
      final config = await readConfig();
      final currentPath = await config.dataPath.getActualDataPath();

      // 创建新的数据路径配置
      DataPathSection newDataSection;
      if (isDefault) {
        // 添加当前自定义路径到历史记录（如果有）
        List<String> historyPaths = List.from(config.dataPath.historyPaths);
        if (!config.dataPath.useDefaultPath &&
            config.dataPath.customPath != null) {
          if (!historyPaths.contains(config.dataPath.customPath!)) {
            historyPaths.add(config.dataPath.customPath!);
          }
        }

        newDataSection = DataPathSection(
          useDefaultPath: true,
          customPath: null,
          historyPaths: historyPaths,
          requiresRestart: true,
        );
      } else {
        // 添加当前路径到历史记录（如果不是默认路径）
        List<String> historyPaths = List.from(config.dataPath.historyPaths);
        if (currentPath != newPath && !historyPaths.contains(currentPath)) {
          historyPaths.add(currentPath);
        }

        newDataSection = DataPathSection(
          useDefaultPath: false,
          customPath: newPath,
          historyPaths: historyPaths,
          requiresRestart: true,
        );
      }

      // 更新配置
      final newConfig = config.copyWith(
        dataPath: newDataSection,
        lastUpdated: DateTime.now(),
      );

      // 保存配置
      await writeConfig(newConfig);

      // 写入数据版本信息
      final actualPath = await newDataSection.getActualDataPath();
      await DataPathConfigService.writeDataVersion(actualPath);

      AppLogger.info('数据路径设置成功', tag: 'UnifiedPathConfig', data: {
        'isDefault': isDefault,
        'path': isDefault ? '默认路径' : newPath,
      });
      return true;
    } catch (e, stack) {
      AppLogger.error('设置数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return false;
    }
  }

  /// 设置备份路径
  static Future<bool> setBackupPath(String newPath) async {
    try {
      // 验证路径
      final validationResult = await validatePath(newPath);
      if (!validationResult.isValid) {
        AppLogger.warning('备份路径验证失败: ${validationResult.errorMessage}',
            tag: 'UnifiedPathConfig');
        return false;
      }

      // 读取当前配置
      final config = await readConfig();

      // 添加当前路径到历史记录（如果有）
      List<String> historyPaths = List.from(config.backupPath.historyPaths);
      if (config.backupPath.path.isNotEmpty &&
          config.backupPath.path != newPath &&
          !historyPaths.contains(config.backupPath.path)) {
        historyPaths.add(config.backupPath.path);
      }

      // 创建新的备份路径配置
      final newBackupSection = config.backupPath.copyWith(
        path: newPath,
        historyPaths: historyPaths,
        createdTime: DateTime.now(),
      );

      // 更新配置
      final newConfig = config.copyWith(
        backupPath: newBackupSection,
        lastUpdated: DateTime.now(),
      );

      // 保存配置
      await writeConfig(newConfig);

      // 为了向后兼容，同时调用旧的设置方法
      await BackupRegistryManager.setBackupLocation(newPath);

      AppLogger.info('备份路径设置成功: $newPath', tag: 'UnifiedPathConfig');
      return true;
    } catch (e, stack) {
      AppLogger.error('设置备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return false;
    }
  }

  /// 添加历史数据路径
  static Future<void> addHistoryDataPath(String path) async {
    try {
      if (path.isEmpty) return;

      final config = await readConfig();

      // 检查路径是否已在历史记录中
      if (config.dataPath.historyPaths.contains(path)) return;

      // 添加到历史记录
      final historyPaths = List<String>.from(config.dataPath.historyPaths)
        ..add(path);

      // 更新配置
      final newConfig = config.copyWith(
        dataPath: config.dataPath.copyWith(
          historyPaths: historyPaths,
        ),
        lastUpdated: DateTime.now(),
      );

      await writeConfig(newConfig);

      AppLogger.debug('添加历史数据路径: $path', tag: 'UnifiedPathConfig');
    } catch (e, stack) {
      AppLogger.error('添加历史数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
    }
  }

  /// 添加历史备份路径
  static Future<void> addHistoryBackupPath(String path) async {
    try {
      if (path.isEmpty) return;

      final config = await readConfig();

      // 检查路径是否已在历史记录中
      if (config.backupPath.historyPaths.contains(path)) return;

      // 添加到历史记录
      final historyPaths = List<String>.from(config.backupPath.historyPaths)
        ..add(path);

      // 更新配置
      final newConfig = config.copyWith(
        backupPath: config.backupPath.copyWith(
          historyPaths: historyPaths,
        ),
        lastUpdated: DateTime.now(),
      );

      await writeConfig(newConfig);

      // 为了向后兼容，同时更新旧的历史记录
      await BackupRegistryManager.addHistoryBackupPath(path);

      AppLogger.debug('添加历史备份路径: $path', tag: 'UnifiedPathConfig');
    } catch (e, stack) {
      AppLogger.error('添加历史备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
    }
  }

  /// 获取历史数据路径
  static Future<List<String>> getHistoryDataPaths() async {
    try {
      final config = await readConfig();
      return config.dataPath.historyPaths;
    } catch (e, stack) {
      AppLogger.error('获取历史数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return [];
    }
  }

  /// 获取历史备份路径
  static Future<List<String>> getHistoryBackupPaths() async {
    try {
      final config = await readConfig();
      return config.backupPath.historyPaths;
    } catch (e, stack) {
      AppLogger.error('获取历史备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return [];
    }
  }

  /// 清理历史数据路径
  static Future<bool> cleanHistoryDataPath(String path) async {
    try {
      final config = await readConfig();

      // 检查路径是否在历史记录中
      if (!config.dataPath.historyPaths.contains(path)) {
        return false;
      }

      // 从历史记录中移除
      final historyPaths = List<String>.from(config.dataPath.historyPaths)
        ..removeWhere((p) => p == path);

      // 更新配置
      final newConfig = config.copyWith(
        dataPath: config.dataPath.copyWith(
          historyPaths: historyPaths,
        ),
        lastUpdated: DateTime.now(),
      );

      await writeConfig(newConfig);

      AppLogger.info('清理历史数据路径: $path', tag: 'UnifiedPathConfig');
      return true;
    } catch (e, stack) {
      AppLogger.error('清理历史数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return false;
    }
  }

  /// 清理历史备份路径
  static Future<bool> cleanHistoryBackupPath(String path) async {
    try {
      final config = await readConfig();

      // 检查路径是否在历史记录中
      if (!config.backupPath.historyPaths.contains(path)) {
        return false;
      }

      // 从历史记录中移除
      final historyPaths = List<String>.from(config.backupPath.historyPaths)
        ..removeWhere((p) => p == path);

      // 更新配置
      final newConfig = config.copyWith(
        backupPath: config.backupPath.copyWith(
          historyPaths: historyPaths,
        ),
        lastUpdated: DateTime.now(),
      );

      await writeConfig(newConfig);

      // 为了向后兼容，同时更新旧的历史记录
      await BackupRegistryManager.removeHistoryBackupPath(path);

      AppLogger.info('清理历史备份路径: $path', tag: 'UnifiedPathConfig');
      return true;
    } catch (e, stack) {
      AppLogger.error('清理历史备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathConfig');
      return false;
    }
  }

  /// 验证路径是否可用
  static Future<PathValidationResult> validatePath(String pathStr) async {
    try {
      if (pathStr.trim().isEmpty) {
        return PathValidationResult.invalid('路径不能为空');
      }

      final directory = Directory(pathStr);

      // 检查路径是否存在
      if (!await directory.exists()) {
        // 尝试创建目录
        try {
          await directory.create(recursive: true);
        } catch (e) {
          return PathValidationResult.invalid('无法创建目录: $e');
        }
      }

      // 检查读写权限
      final testFile = File(path.join(pathStr, 'test_permission.tmp'));
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        return PathValidationResult.invalid('目录没有读写权限: $e');
      }

      return PathValidationResult.valid();
    } catch (e) {
      return PathValidationResult.invalid('路径验证失败: $e');
    }
  }
}

/// 路径验证结果
class PathValidationResult {
  final bool isValid;
  final String? errorMessage;

  const PathValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory PathValidationResult.valid() {
    return const PathValidationResult(isValid: true);
  }

  factory PathValidationResult.invalid(String message) {
    return PathValidationResult(isValid: false, errorMessage: message);
  }
}
