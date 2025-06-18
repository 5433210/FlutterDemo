import '../../domain/models/config/config_item.dart';
import '../../domain/services/config_service.dart';
import '../repositories/config_repository.dart';

/// 配置服务实现
class ConfigServiceImpl implements ConfigService {
  final ConfigRepository _repository;

  ConfigServiceImpl(this._repository);

  @override
  Future<ConfigCategory?> getConfigCategory(String category) async {
    return await _repository.getConfigCategory(category);
  }

  @override
  Future<List<ConfigCategory>> getAllConfigCategories() async {
    return await _repository.getAllConfigCategories();
  }

  @override
  Future<void> saveConfigCategory(ConfigCategory category) async {
    await _repository.saveConfigCategory(category);
  }

  @override
  Future<void> deleteConfigCategory(String category) async {
    await _repository.deleteConfigCategory(category);
  }

  @override
  Future<List<ConfigItem>> getActiveConfigItems(String category) async {
    final configCategory = await _repository.getConfigCategory(category);
    return configCategory?.activeItems ?? [];
  }

  @override
  Future<List<ConfigItem>> getAllConfigItems(String category) async {
    final configCategory = await _repository.getConfigCategory(category);
    return configCategory?.items ?? [];
  }

  @override
  Future<void> addConfigItem(String category, ConfigItem item) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }

    // 检查键是否已存在
    final exists = await isConfigItemKeyExists(category, item.key);
    if (exists) {
      throw ConfigException(
        'Configuration item with key "${item.key}" already exists',
        category: category,
        itemKey: item.key,
      );
    }

    // 添加新配置项
    final updatedItems = [...configCategory.items, item];
    final updatedCategory = configCategory.copyWith(
      items: updatedItems,
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(updatedCategory);
  }

  @override
  Future<void> updateConfigItem(String category, ConfigItem item) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }

    // 查找并更新配置项
    final itemIndex = configCategory.items
        .indexWhere((existing) => existing.key == item.key);
    
    if (itemIndex == -1) {
      throw ConfigException(
        'Configuration item with key "${item.key}" not found',
        category: category,
        itemKey: item.key,
      );
    }

    final updatedItems = [...configCategory.items];
    updatedItems[itemIndex] = item.copyWith(updateTime: DateTime.now());
    
    final updatedCategory = configCategory.copyWith(
      items: updatedItems,
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(updatedCategory);
  }

  @override
  Future<void> deleteConfigItem(String category, String itemKey) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }

    // 查找配置项
    final itemToDelete = configCategory.items
        .where((item) => item.key == itemKey)
        .firstOrNull;
    
    if (itemToDelete == null) {
      throw ConfigException(
        'Configuration item with key "$itemKey" not found',
        category: category,
        itemKey: itemKey,
      );
    }

    // 检查是否为系统配置项
    if (itemToDelete.isSystem) {
      throw ConfigException(
        'Cannot delete system configuration item: $itemKey',
        category: category,
        itemKey: itemKey,
      );
    }

    // 删除配置项
    final updatedItems = configCategory.items
        .where((item) => item.key != itemKey)
        .toList();
    
    final updatedCategory = configCategory.copyWith(
      items: updatedItems,
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(updatedCategory);
  }

  @override
  Future<void> reorderConfigItems(String category, List<String> keyOrder) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }

    // 验证所有键是否存在
    final existingKeys = configCategory.items.map((item) => item.key).toSet();
    final providedKeys = keyOrder.toSet();
    
    if (!existingKeys.containsAll(providedKeys) || 
        !providedKeys.containsAll(existingKeys)) {
      throw ConfigException(
        'Provided keys do not match existing configuration items',
        category: category,
      );
    }

    // 重新排序配置项
    final itemMap = {for (var item in configCategory.items) item.key: item};
    final reorderedItems = keyOrder
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final key = entry.value;
          final item = itemMap[key]!;
          return item.copyWith(
            sortOrder: index + 1,
            updateTime: DateTime.now(),
          );
        })
        .toList();

    final updatedCategory = configCategory.copyWith(
      items: reorderedItems,
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(updatedCategory);
  }

  @override
  Future<void> toggleConfigItemActive(String category, String itemKey) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }

    // 查找并切换配置项状态
    final itemIndex = configCategory.items
        .indexWhere((item) => item.key == itemKey);
    
    if (itemIndex == -1) {
      throw ConfigException(
        'Configuration item with key "$itemKey" not found',
        category: category,
        itemKey: itemKey,
      );
    }

    final updatedItems = [...configCategory.items];
    final currentItem = updatedItems[itemIndex];
    updatedItems[itemIndex] = currentItem.copyWith(
      isActive: !currentItem.isActive,
      updateTime: DateTime.now(),
    );
    
    final updatedCategory = configCategory.copyWith(
      items: updatedItems,
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(updatedCategory);
  }

  @override
  Future<bool> isConfigItemKeyExists(String category, String key) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) return false;
    
    return configCategory.items.any((item) => item.key == key);
  }
  @override
  Future<void> resetConfigToDefault(String category) async {
    if (category == ConfigCategories.style) {
      await _repository.initializeStyleConfigs();
    } else if (category == ConfigCategories.tool) {
      await _repository.initializeToolConfigs();
    } else {
      throw ConfigException(
        'Unknown configuration category: $category',
        category: category,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> exportConfig(String category) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) {
      throw ConfigException(
        'Configuration category not found: $category',
        category: category,
      );
    }    return {
      'category': configCategory.category,
      'displayName': configCategory.displayName,
      'items': configCategory.items.map((item) => item.toJson()).toList(),
      'updateTime': configCategory.updateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'exportTime': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  @override
  Future<void> importConfig(String category, Map<String, dynamic> config) async {
    try {
      // 验证配置格式
      if (!config.containsKey('category') || 
          !config.containsKey('items') ||
          config['category'] != category) {
        throw ConfigException(
          'Invalid configuration format',
          category: category,
        );
      }

      // 解析配置项
      final itemsList = config['items'] as List;
      final items = itemsList
          .map((itemJson) => ConfigItem.fromJson(itemJson as Map<String, dynamic>))
          .toList();

      // 创建新的配置分类
      final importedCategory = ConfigCategory(
        category: category,
        displayName: config['displayName'] as String? ?? category,
        items: items,
        updateTime: DateTime.now(),
      );

      await _repository.saveConfigCategory(importedCategory);
    } catch (e) {
      throw ConfigException(
        'Failed to import configuration: $e',
        category: category,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> validateConfig(String category) async {
    final validationResult = await _repository.validateConfig(category);
    return validationResult.isValid;
  }

  @override
  Future<void> cleanupInvalidConfigs() async {
    await _repository.cleanupInvalidConfigs();
  }

  /// Helper method to get a specific config item
  Future<ConfigItem?> getConfigItem(String category, String key) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) return null;

    try {
      return configCategory.items.firstWhere((item) => item.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Initialize default configurations
  Future<void> initializeDefaultConfigs() async {
    await _repository.initializeDefaultConfigs();
  }

  /// Get display names for all active items in a category
  Future<Map<String, String>> getDisplayNames(String category) async {
    final configCategory = await _repository.getConfigCategory(category);
    if (configCategory == null) return {};

    return {
      for (var item in configCategory.activeItems)
        item.key: item.displayName
    };
  }

  /// Get display name for a specific item
  Future<String> getDisplayName(String category, String key) async {
    final configItem = await getConfigItem(category, key);
    return configItem?.displayName ?? key;
  }
}
