import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/config/data_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import '../services/data_migration_service.dart';
import '../services/data_path_config_service.dart';

/// 数据路径配置Provider
/// 管理应用的数据路径配置状态
final dataPathConfigProvider =
    StateNotifierProvider<DataPathConfigNotifier, AsyncValue<DataPathConfig>>(
        (ref) {
  return DataPathConfigNotifier();
});

/// 数据路径配置状态管理器
class DataPathConfigNotifier extends StateNotifier<AsyncValue<DataPathConfig>> {
  DataPathConfigNotifier() : super(const AsyncValue.loading()) {
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      state = const AsyncValue.loading();
      final config = await DataPathConfigService.readConfig();
      state = AsyncValue.data(config);
      AppLogger.info('数据路径配置加载成功', tag: 'DataPathProvider');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppLogger.error('数据路径配置加载失败',
          error: e, stackTrace: stack, tag: 'DataPathProvider');
    }
  }

  /// 设置自定义数据路径
  Future<bool> setCustomDataPath(String newPath) async {
    try {
      // 验证路径
      final validationResult =
          await DataPathConfigService.validatePath(newPath);
      if (!validationResult.isValid) {
        AppLogger.warning('路径验证失败: ${validationResult.errorMessage}',
            tag: 'DataPathProvider');
        return false;
      }

      // 检查数据兼容性
      final compatibilityResult =
          await DataPathConfigService.checkDataCompatibility(newPath);

      // 根据兼容性结果决定是否继续
      switch (compatibilityResult.status) {
        case DataCompatibilityStatus.incompatible:
        case DataCompatibilityStatus.needsAppUpgrade:
          AppLogger.warning('数据路径不兼容: ${compatibilityResult.status}',
              tag: 'DataPathProvider');
          return false;
        case DataCompatibilityStatus.compatible:
        case DataCompatibilityStatus.upgradable:
        case DataCompatibilityStatus.newDataPath:
          break;
        case DataCompatibilityStatus.unknownState:
          AppLogger.warning('数据路径状态未知: ${compatibilityResult.message}',
              tag: 'DataPathProvider');
          return false;
      }

      // 创建新配置
      final newConfig = DataPathConfig.withCustomPath(newPath);

      // 保存配置
      await DataPathConfigService.writeConfig(newConfig);

      // 如果是新数据路径，写入版本信息
      if (compatibilityResult.status == DataCompatibilityStatus.newDataPath) {
        await DataPathConfigService.writeDataVersion(newPath);
      }

      // 数据迁移（如果需要）
      final currentConfig = state.value;
      if (currentConfig != null && !currentConfig.useDefaultPath) {
        final currentPath = await currentConfig.getActualDataPath();
        if (currentPath != newPath) {
          final migrationResult = await DataMigrationService.migrateData(
            currentPath,
            newPath,
            moveData: false, // 复制而不是移动
          );

          if (!migrationResult.isSuccess) {
            AppLogger.error('数据迁移失败: ${migrationResult.errorMessage}',
                tag: 'DataPathProvider');
            return false;
          }
        }
      }

      // 更新状态
      state = AsyncValue.data(newConfig);

      AppLogger.info('自定义数据路径设置成功: $newPath', tag: 'DataPathProvider');
      return true;
    } catch (e, stack) {
      AppLogger.error('设置自定义数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathProvider');
      return false;
    }
  }

  /// 重置为默认路径
  Future<bool> resetToDefaultPath() async {
    try {
      final defaultConfig = DataPathConfig.defaultConfig();

      // 保存配置
      await DataPathConfigService.writeConfig(defaultConfig);

      // 获取默认路径并写入版本信息
      final defaultPath = await DataPathConfigService.getDefaultDataPath();
      await DataPathConfigService.writeDataVersion(defaultPath);

      // 数据迁移（如果需要）
      final currentConfig = state.value;
      if (currentConfig != null && !currentConfig.useDefaultPath) {
        final currentPath = await currentConfig.getActualDataPath();
        if (currentPath != defaultPath) {
          final migrationResult = await DataMigrationService.migrateData(
            currentPath,
            defaultPath,
            moveData: false, // 复制而不是移动
          );

          if (!migrationResult.isSuccess) {
            AppLogger.error('数据迁移失败: ${migrationResult.errorMessage}',
                tag: 'DataPathProvider');
            return false;
          }
        }
      }

      // 更新状态
      state = AsyncValue.data(defaultConfig);

      AppLogger.info('重置为默认数据路径成功', tag: 'DataPathProvider');
      return true;
    } catch (e, stack) {
      AppLogger.error('重置默认数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathProvider');
      return false;
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadConfig();
  }

  /// 验证路径
  Future<PathValidationResult> validatePath(String path) async {
    return DataPathConfigService.validatePath(path);
  }

  /// 检查数据兼容性
  Future<DataCompatibilityResult> checkDataCompatibility(String path) async {
    return DataPathConfigService.checkDataCompatibility(path);
  }
}

/// 当前实际数据路径Provider
/// 基于配置返回当前应该使用的数据路径
final actualDataPathProvider = FutureProvider<String>((ref) async {
  final configAsync = ref.watch(dataPathConfigProvider);

  return configAsync.when(
    data: (config) => config.getActualDataPath(),
    loading: () => DataPathConfigService.getDefaultDataPath(),
    error: (_, __) => DataPathConfigService.getDefaultDataPath(),
  );
});

/// 路径配置状态Provider
/// 提供路径配置的各种状态信息
final dataPathStatusProvider = Provider<DataPathStatus>((ref) {
  final configAsync = ref.watch(dataPathConfigProvider);

  return configAsync.when(
    data: (config) => DataPathStatus(
      isLoading: false,
      isCustomPath: !config.useDefaultPath,
      hasError: false,
      errorMessage: null,
    ),
    loading: () => const DataPathStatus(
      isLoading: true,
      isCustomPath: false,
      hasError: false,
      errorMessage: null,
    ),
    error: (error, _) => DataPathStatus(
      isLoading: false,
      isCustomPath: false,
      hasError: true,
      errorMessage: error.toString(),
    ),
  );
});

/// 数据路径状态信息
class DataPathStatus {
  final bool isLoading;
  final bool isCustomPath;
  final bool hasError;
  final String? errorMessage;

  const DataPathStatus({
    required this.isLoading,
    required this.isCustomPath,
    required this.hasError,
    this.errorMessage,
  });
}
