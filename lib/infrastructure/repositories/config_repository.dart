import 'dart:convert';

import '../../domain/models/config/config_item.dart';
import '../../domain/services/config_service.dart';
import '../persistence/database_interface.dart';

/// 配置仓储实现
class ConfigRepository {
  final DatabaseInterface _database;

  ConfigRepository(this._database);

  /// 获取配置分类
  Future<ConfigCategory?> getConfigCategory(String category) async {
    try {
      final result = await _database.rawQuery(
        'SELECT * FROM settings WHERE key = ? LIMIT 1',
        ['${category}_configs'],
      );

      if (result.isEmpty) return null;

      final configData = jsonDecode(result.first['value'] as String);
      return ConfigCategory.fromJson(configData);
    } catch (e) {
      throw ConfigException(
        'Failed to get config category: $e',
        category: category,
        originalError: e,
      );
    }
  }
  /// 保存配置分类
  Future<void> saveConfigCategory(ConfigCategory category) async {
    try {
      final configJson = jsonEncode(category.toJson());
      
      await _database.rawUpdate(
        'INSERT OR REPLACE INTO settings (key, value, updateTime) VALUES (?, ?, ?)',
        [
          '${category.category}_configs',
          configJson,
          DateTime.now().toIso8601String(),
        ],
      );
    } catch (e) {
      throw ConfigException(
        'Failed to save config category: $e',
        category: category.category,
        originalError: e,
      );
    }
  }
  /// 删除配置分类
  Future<void> deleteConfigCategory(String category) async {
    try {
      await _database.rawDelete(
        'DELETE FROM settings WHERE key = ?',
        ['${category}_configs'],
      );
    } catch (e) {
      throw ConfigException(
        'Failed to delete config category: $e',
        category: category,
        originalError: e,
      );
    }
  }
  /// 获取所有配置分类
  Future<List<ConfigCategory>> getAllConfigCategories() async {
    try {
      final result = await _database.rawQuery(
        'SELECT * FROM settings WHERE key LIKE ?',
        ['%_configs'],
      );

      final categories = <ConfigCategory>[];
      for (final row in result) {
        try {
          final configData = jsonDecode(row['value'] as String);
          categories.add(ConfigCategory.fromJson(configData));
        } catch (e) {
          // 记录解析失败的配置，但不中断整个操作
          print('Failed to parse config for key: ${row['key']}, error: $e');
        }
      }

      return categories;
    } catch (e) {
      throw ConfigException(
        'Failed to get all config categories: $e',
        originalError: e,
      );
    }
  }
  /// 初始化默认配置（用于首次启动或重置）
  Future<void> initializeDefaultConfigs() async {
    // 初始化书法风格配置
    await initializeStyleConfigs();
    
    // 初始化书写工具配置
    await initializeToolConfigs();
  }
  /// 初始化书法风格默认配置
  Future<void> initializeStyleConfigs() async {
    final styleConfig = ConfigCategory(
      category: ConfigCategories.style,
      displayName: '书法风格',
      items: [
        ConfigItem(
          key: 'regular',
          displayName: '楷书',
          sortOrder: 1,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Regular Script', 'zh': '楷书'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'running',
          displayName: '行书',
          sortOrder: 2,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Running Script', 'zh': '行书'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'cursive',
          displayName: '草书',
          sortOrder: 3,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Cursive Script', 'zh': '草书'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'clerical',
          displayName: '隶书',
          sortOrder: 4,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Clerical Script', 'zh': '隶书'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'seal',
          displayName: '篆书',
          sortOrder: 5,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Seal Script', 'zh': '篆书'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'other',
          displayName: '其他',
          sortOrder: 6,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Other', 'zh': '其他'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
      ],
      updateTime: DateTime.now(),
    );

    await saveConfigCategory(styleConfig);
  }
  /// 初始化书写工具默认配置
  Future<void> initializeToolConfigs() async {
    final toolConfig = ConfigCategory(
      category: ConfigCategories.tool,
      displayName: '书写工具',
      items: [
        ConfigItem(
          key: 'brush',
          displayName: '毛笔',
          sortOrder: 1,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Brush', 'zh': '毛笔'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'hardPen',
          displayName: '硬笔',
          sortOrder: 2,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Hard Pen', 'zh': '硬笔'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'other',
          displayName: '其他',
          sortOrder: 3,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Other', 'zh': '其他'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
      ],
      updateTime: DateTime.now(),
    );

    await saveConfigCategory(toolConfig);
  }

  /// 验证配置数据完整性
  Future<ConfigValidationResult> validateConfig(String category) async {
    try {
      final config = await getConfigCategory(category);
      if (config == null) {
        return const ConfigValidationResult(
          isValid: false,
          errors: ['Configuration category not found'],
        );
      }

      final errors = <String>[];
      final warnings = <String>[];

      // 验证分类基本信息
      if (config.category.isEmpty) {
        errors.add('Category name is empty');
      }

      if (config.displayName.isEmpty) {
        errors.add('Category display name is empty');
      }

      // 验证配置项
      final keys = <String>{};
      final sortOrders = <int>{};

      for (final item in config.items) {
        // 检查重复键
        if (keys.contains(item.key)) {
          errors.add('Duplicate item key: ${item.key}');
        } else {
          keys.add(item.key);
        }

        // 检查重复排序
        if (sortOrders.contains(item.sortOrder)) {
          warnings.add('Duplicate sort order: ${item.sortOrder}');
        } else {
          sortOrders.add(item.sortOrder);
        }

        // 验证配置项数据
        if (!item.isValid) {
          errors.add('Invalid item: ${item.key}');
        }
      }

      // 检查是否有激活的配置项
      if (config.activeItems.isEmpty) {
        warnings.add('No active items found');
      }

      return ConfigValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return ConfigValidationResult(
        isValid: false,
        errors: ['Validation failed: $e'],
      );
    }
  }

  /// 清理无效配置数据
  Future<void> cleanupInvalidConfigs() async {
    try {
      final categories = await getAllConfigCategories();
      
      for (final category in categories) {
        final validationResult = await validateConfig(category.category);
          if (!validationResult.isValid) {
          // 如果配置完全无效，重置为默认配置
          if (category.category == ConfigCategories.style) {
            await initializeStyleConfigs();
          } else if (category.category == ConfigCategories.tool) {
            await initializeToolConfigs();
          }
        }
      }
    } catch (e) {
      throw ConfigException(
        'Failed to cleanup invalid configs: $e',
        originalError: e,
      );
    }
  }
}
