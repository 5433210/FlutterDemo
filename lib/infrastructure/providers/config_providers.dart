import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/config/config_item.dart';
import '../../domain/services/config_service.dart';
import '../repositories/config_repository.dart';
import '../services/config_service_impl.dart';
import 'database_providers.dart';

/// 配置刷新触发器 - 用于手动刷新配置数据
final configRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 配置仓储提供者
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  final database = ref.watch(initializedDatabaseProvider);
  return ConfigRepository(database);
});

/// 配置服务提供者
final configServiceProvider = Provider<ConfigService>((ref) {
  final repository = ref.watch(configRepositoryProvider);
  return ConfigServiceImpl(repository);
});

/// 书法风格配置状态提供者 - 支持手动刷新
final styleConfigProvider = FutureProvider<ConfigCategory?>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfigCategory(ConfigCategories.style);
});

/// 书写工具配置状态提供者 - 支持手动刷新
final toolConfigProvider = FutureProvider<ConfigCategory?>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfigCategory(ConfigCategories.tool);
});

/// 激活的书法风格选项提供者 - 支持手动刷新
final activeStyleItemsProvider = FutureProvider<List<ConfigItem>>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  return await configService.getActiveConfigItems(ConfigCategories.style);
});

/// 激活的书写工具选项提供者 - 支持手动刷新
final activeToolItemsProvider = FutureProvider<List<ConfigItem>>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  return await configService.getActiveConfigItems(ConfigCategories.tool);
});

/// 书法风格显示名称映射提供者 - 支持手动刷新
final styleDisplayNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  final configServiceImpl = configService as ConfigServiceImpl;
  return await configServiceImpl.getDisplayNames(ConfigCategories.style);
});

/// 书写工具显示名称映射提供者 - 支持手动刷新
final toolDisplayNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  // 监听刷新触发器，当触发器变化时自动重新获取数据
  ref.watch(configRefreshTriggerProvider);
  final configService = ref.watch(configServiceProvider);
  final configServiceImpl = configService as ConfigServiceImpl;
  return await configServiceImpl.getDisplayNames(ConfigCategories.tool);
});

/// 配置管理通知器 - 用于管理配置状态的变更
class ConfigNotifier extends StateNotifier<AsyncValue<ConfigCategory?>> {
  final ConfigService _configService;
  final String _category;

  ConfigNotifier(this._configService, this._category)
      : super(const AsyncValue.loading()) {
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      state = const AsyncValue.loading();
      final config = await _configService.getConfigCategory(_category);
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadConfig();
  }

  /// 添加配置项
  Future<void> addItem(ConfigItem item) async {
    try {
      await _configService.addConfigItem(_category, item);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 更新配置项
  Future<void> updateItem(ConfigItem item) async {
    try {
      await _configService.updateConfigItem(_category, item);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 删除配置项
  Future<void> deleteItem(String itemKey) async {
    try {
      await _configService.deleteConfigItem(_category, itemKey);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 切换配置项激活状态
  Future<void> toggleItemActive(String itemKey) async {
    try {
      await _configService.toggleConfigItemActive(_category, itemKey);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 重新排序配置项
  Future<void> reorderItems(List<String> keyOrder) async {
    try {
      await _configService.reorderConfigItems(_category, keyOrder);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    try {
      await _configService.resetConfigToDefault(_category);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 导出配置
  Future<Map<String, dynamic>?> exportConfig() async {
    try {
      return await _configService.exportConfig(_category);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return null;
    }
  }

  /// 导入配置
  Future<void> importConfig(Map<String, dynamic> config) async {
    try {
      await _configService.importConfig(_category, config);
      await _loadConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// 书法风格配置管理器提供者
final styleConfigNotifierProvider =
    StateNotifierProvider<ConfigNotifier, AsyncValue<ConfigCategory?>>((ref) {
  final configService = ref.watch(configServiceProvider);
  return ConfigNotifier(configService, ConfigCategories.style);
});

/// 书写工具配置管理器提供者
final toolConfigNotifierProvider =
    StateNotifierProvider<ConfigNotifier, AsyncValue<ConfigCategory?>>((ref) {
  final configService = ref.watch(configServiceProvider);
  return ConfigNotifier(configService, ConfigCategories.tool);
});

/// 配置初始化提供者 - 确保默认配置已初始化
final configInitializationProvider = FutureProvider<bool>((ref) async {
  final configService = ref.watch(configServiceProvider);
  try {
    // 检查是否已有配置
    final styleConfig =
        await configService.getConfigCategory(ConfigCategories.style);
    final toolConfig =
        await configService.getConfigCategory(ConfigCategories.tool);

    // 如果没有配置，则初始化默认配置
    if (styleConfig == null || toolConfig == null) {
      await (configService as ConfigServiceImpl).initializeDefaultConfigs();
    }

    return true;
  } catch (e) {
    throw Exception('Failed to initialize configurations: $e');
  }
});

/// 配置刷新方法 - 在配置修改后调用此方法来刷新所有相关provider
void refreshConfigs(WidgetRef ref) {
  final currentTrigger = ref.read(configRefreshTriggerProvider);
  ref.read(configRefreshTriggerProvider.notifier).state = currentTrigger + 1;
}
