import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/config/unified_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import '../services/data_migration_service.dart';
import '../services/unified_path_config_service.dart';

/// 统一路径配置Provider
/// 管理应用的数据路径和备份路径配置状态
final unifiedPathConfigProvider =
    StateNotifierProvider<UnifiedPathConfigNotifier, AsyncValue<UnifiedPathConfig>>(
        (ref) {
  return UnifiedPathConfigNotifier();
});

/// 统一路径配置状态管理器
class UnifiedPathConfigNotifier extends StateNotifier<AsyncValue<UnifiedPathConfig>> {
  UnifiedPathConfigNotifier() : super(const AsyncValue.loading()) {
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      state = const AsyncValue.loading();
      final config = await UnifiedPathConfigService.readConfig();
      state = AsyncValue.data(config);
      AppLogger.info('统一路径配置加载成功', tag: 'UnifiedPathProvider');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppLogger.error('统一路径配置加载失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
    }
  }

  /// 设置自定义数据路径
  Future<bool> setCustomDataPath(String newPath) async {
    try {
      // 调用服务设置数据路径
      final result = await UnifiedPathConfigService.setDataPath(newPath);
      if (result) {
        // 重新加载配置
        await _loadConfig();
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('设置自定义数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 重置为默认数据路径
  Future<bool> resetToDefaultPath() async {
    try {
      // 调用服务重置为默认路径
      final result = await UnifiedPathConfigService.setDataPath('', isDefault: true);
      if (result) {
        // 重新加载配置
        await _loadConfig();
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('重置默认数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 设置备份路径
  Future<bool> setBackupPath(String newPath) async {
    try {
      // 调用服务设置备份路径
      final result = await UnifiedPathConfigService.setBackupPath(newPath);
      if (result) {
        // 重新加载配置
        await _loadConfig();
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('设置备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 清理历史数据路径
  Future<bool> cleanHistoryDataPath(String path) async {
    try {
      // 调用服务清理历史数据路径
      final result = await UnifiedPathConfigService.cleanHistoryDataPath(path);
      if (result) {
        // 重新加载配置
        await _loadConfig();
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('清理历史数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 清理历史备份路径
  Future<bool> cleanHistoryBackupPath(String path) async {
    try {
      // 调用服务清理历史备份路径
      final result = await UnifiedPathConfigService.cleanHistoryBackupPath(path);
      if (result) {
        // 重新加载配置
        await _loadConfig();
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('清理历史备份路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 迁移数据
  Future<bool> migrateData(String fromPath, String toPath) async {
    try {
      final migrationResult = await DataMigrationService.migrateData(
        fromPath,
        toPath,
        moveData: false, // 复制而不是移动
      );

      return migrationResult.isSuccess;
    } catch (e, stack) {
      AppLogger.error('数据迁移失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadConfig();
  }

  /// 验证路径
  Future<PathValidationResult> validatePath(String path) async {
    return UnifiedPathConfigService.validatePath(path);
  }

  /// 检查配置是否已迁移到SharedPreferences
  static Future<bool> isConfigMigratedToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(PathConfigConstants.unifiedPathConfigKey);
    } catch (e) {
      AppLogger.error('检查配置迁移状态失败', 
          error: e, tag: 'UnifiedPathProvider');
      return false;
    }
  }

  /// 导出配置为JSON字符串（用于调试）
  Future<String> exportConfigAsJson() async {
    try {
      final config = state.value;
      if (config == null) {
        return '配置未加载';
      }
      return const JsonEncoder.withIndent('  ').convert(config.toJson());
    } catch (e) {
      return '导出配置失败: $e';
    }
  }

  /// 检查SharedPreferences中的所有键（用于调试）
  static Future<Map<String, dynamic>> getAllSharedPreferencesKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final result = <String, dynamic>{};
      
      for (final key in keys) {
        if (prefs.containsKey(key)) {
          if (key == PathConfigConstants.unifiedPathConfigKey) {
            // 对于统一配置，返回解析后的JSON对象
            final jsonStr = prefs.getString(key);
            if (jsonStr != null) {
              result[key] = jsonDecode(jsonStr);
            } else {
              result[key] = null;
            }
          } else {
            // 对于其他键，直接返回值
            if (prefs.getString(key) != null) {
              result[key] = prefs.getString(key);
            } else if (prefs.getBool(key) != null) {
              result[key] = prefs.getBool(key);
            } else if (prefs.getInt(key) != null) {
              result[key] = prefs.getInt(key);
            } else if (prefs.getDouble(key) != null) {
              result[key] = prefs.getDouble(key);
            } else if (prefs.getStringList(key) != null) {
              result[key] = prefs.getStringList(key);
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// 当前实际数据路径Provider
final actualDataPathProvider = FutureProvider<String>((ref) async {
  final configAsync = ref.watch(unifiedPathConfigProvider);

  return configAsync.when(
    data: (config) => config.dataPath.getActualDataPath(),
    loading: () async {
      final appSupportDir = await getApplicationSupportDirectory();
      return path.join(appSupportDir.path, PathConfigConstants.defaultDataSubDirectory);
    },
    error: (_, __) async {
      final appSupportDir = await getApplicationSupportDirectory();
      return path.join(appSupportDir.path, PathConfigConstants.defaultDataSubDirectory);
    },
  );
});

/// 当前备份路径Provider
final backupPathProvider = Provider<String?>((ref) {
  final configAsync = ref.watch(unifiedPathConfigProvider);

  return configAsync.when(
    data: (config) => config.backupPath.path.isEmpty ? null : config.backupPath.path,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 路径配置状态Provider
final pathStatusProvider = Provider<PathStatus>((ref) {
  final configAsync = ref.watch(unifiedPathConfigProvider);

  return configAsync.when(
    data: (config) => PathStatus(
      isLoading: false,
      isCustomDataPath: !config.dataPath.useDefaultPath,
      hasBackupPath: config.backupPath.path.isNotEmpty,
      hasError: false,
      errorMessage: null,
      dataHistoryCount: config.dataPath.historyPaths.length,
      backupHistoryCount: config.backupPath.historyPaths.length,
    ),
    loading: () => const PathStatus(
      isLoading: true,
      isCustomDataPath: false,
      hasBackupPath: false,
      hasError: false,
      errorMessage: null,
      dataHistoryCount: 0,
      backupHistoryCount: 0,
    ),
    error: (error, _) => PathStatus(
      isLoading: false,
      isCustomDataPath: false,
      hasBackupPath: false,
      hasError: true,
      errorMessage: error.toString(),
      dataHistoryCount: 0,
      backupHistoryCount: 0,
    ),
  );
});

/// 路径状态信息
class PathStatus {
  final bool isLoading;
  final bool isCustomDataPath;
  final bool hasBackupPath;
  final bool hasError;
  final String? errorMessage;
  final int dataHistoryCount;
  final int backupHistoryCount;

  const PathStatus({
    required this.isLoading,
    required this.isCustomDataPath,
    required this.hasBackupPath,
    required this.hasError,
    this.errorMessage,
    required this.dataHistoryCount,
    required this.backupHistoryCount,
  });
} 