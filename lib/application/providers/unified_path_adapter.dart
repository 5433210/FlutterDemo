import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/config/data_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import '../services/unified_path_config_service.dart';
import 'data_path_provider.dart';
import 'unified_path_provider.dart';

/// 数据路径配置适配器Provider
/// 将统一路径配置转换为旧格式的数据路径配置
final dataPathConfigAdapterProvider = Provider<AsyncValue<DataPathConfig>>((ref) {
  final unifiedConfigAsync = ref.watch(unifiedPathConfigProvider);
  
  return unifiedConfigAsync.when(
    data: (unifiedConfig) => AsyncValue.data(DataPathConfig(
      useDefaultPath: unifiedConfig.dataPath.useDefaultPath,
      customPath: unifiedConfig.dataPath.customPath,
      historyPaths: unifiedConfig.dataPath.historyPaths,
      lastUpdated: unifiedConfig.lastUpdated,
      requiresRestart: unifiedConfig.dataPath.requiresRestart,
    )),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// 数据路径配置状态适配器Provider
/// 提供与旧Provider兼容的数据路径状态信息
final dataPathStatusAdapterProvider = Provider<DataPathStatus>((ref) {
  final unifiedStatusAsync = ref.watch(pathStatusProvider);
  
  return DataPathStatus(
    isLoading: unifiedStatusAsync.isLoading,
    isCustomPath: unifiedStatusAsync.isCustomDataPath,
    hasError: unifiedStatusAsync.hasError,
    errorMessage: unifiedStatusAsync.errorMessage,
  );
});

/// 数据路径配置Notifier适配器
/// 提供与旧Notifier兼容的操作方法
final dataPathConfigNotifierAdapterProvider = Provider<DataPathConfigNotifierAdapter>((ref) {
  return DataPathConfigNotifierAdapter(ref);
});

/// 数据路径配置Notifier适配器
class DataPathConfigNotifierAdapter {
  final Ref _ref;
  
  DataPathConfigNotifierAdapter(this._ref);
  
  /// 设置自定义数据路径
  Future<bool> setCustomDataPath(String newPath) async {
    try {
      return await _ref.read(unifiedPathConfigProvider.notifier).setCustomDataPath(newPath);
    } catch (e, stack) {
      AppLogger.error('适配器设置自定义数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathAdapter');
      return false;
    }
  }
  
  /// 重置为默认路径
  Future<bool> resetToDefaultPath() async {
    try {
      return await _ref.read(unifiedPathConfigProvider.notifier).resetToDefaultPath();
    } catch (e, stack) {
      AppLogger.error('适配器重置默认数据路径失败',
          error: e, stackTrace: stack, tag: 'UnifiedPathAdapter');
      return false;
    }
  }
  
  /// 验证路径
  Future<PathValidationResult> validatePath(String path) async {
    return await _ref.read(unifiedPathConfigProvider.notifier).validatePath(path);
  }
  
  /// 重新加载配置
  Future<void> reload() async {
    await _ref.read(unifiedPathConfigProvider.notifier).reload();
  }
}

/// 备份路径Provider适配器
/// 提供与旧的备份路径获取方法兼容的Provider
final backupPathAdapterProvider = FutureProvider<String?>((ref) async {
  return ref.watch(backupPathProvider);
}); 