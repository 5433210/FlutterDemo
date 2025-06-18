import '../models/config/config_item.dart';

/// 配置服务接口
abstract class ConfigService {
  /// 获取指定分类的配置
  Future<ConfigCategory?> getConfigCategory(String category);

  /// 获取所有配置分类
  Future<List<ConfigCategory>> getAllConfigCategories();

  /// 保存配置分类
  Future<void> saveConfigCategory(ConfigCategory category);

  /// 删除配置分类
  Future<void> deleteConfigCategory(String category);

  /// 获取指定分类下的所有激活配置项
  Future<List<ConfigItem>> getActiveConfigItems(String category);

  /// 获取指定分类下的所有配置项
  Future<List<ConfigItem>> getAllConfigItems(String category);

  /// 添加配置项
  Future<void> addConfigItem(String category, ConfigItem item);

  /// 更新配置项
  Future<void> updateConfigItem(String category, ConfigItem item);

  /// 删除配置项
  Future<void> deleteConfigItem(String category, String itemKey);

  /// 批量更新配置项排序
  Future<void> reorderConfigItems(String category, List<String> keyOrder);

  /// 切换配置项激活状态
  Future<void> toggleConfigItemActive(String category, String itemKey);

  /// 检查配置项key是否已存在
  Future<bool> isConfigItemKeyExists(String category, String key);

  /// 重置配置为默认值
  Future<void> resetConfigToDefault(String category);

  /// 导出配置为JSON
  Future<Map<String, dynamic>> exportConfig(String category);

  /// 从JSON导入配置
  Future<void> importConfig(String category, Map<String, dynamic> config);

  /// 验证配置数据完整性
  Future<bool> validateConfig(String category);

  /// 清理无效配置数据
  Future<void> cleanupInvalidConfigs();
}

/// 预定义配置分类常量
abstract class ConfigCategories {
  /// 书法风格
  static const String style = 'style';
  
  /// 书写工具
  static const String tool = 'tool';
}

/// 配置事件类型
enum ConfigEventType {
  /// 配置项添加
  itemAdded,
  
  /// 配置项更新
  itemUpdated,
  
  /// 配置项删除
  itemDeleted,
  
  /// 配置项重排序
  itemReordered,
  
  /// 配置项激活状态变更
  itemActiveToggled,
  
  /// 分类重置
  categoryReset,
  
  /// 配置导入
  configImported,
  
  /// 配置导出
  configExported,
}

/// 配置变更事件
class ConfigChangeEvent {
  final ConfigEventType type;
  final String category;
  final String? itemKey;
  final ConfigItem? item;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ConfigChangeEvent({
    required this.type,
    required this.category,
    this.itemKey,
    this.item,
    required this.timestamp,
    this.metadata,
  });

  @override
  String toString() {
    return 'ConfigChangeEvent{type: $type, category: $category, itemKey: $itemKey, timestamp: $timestamp}';
  }
}

/// 配置异常类
class ConfigException implements Exception {
  final String message;
  final String? category;
  final String? itemKey;
  final dynamic originalError;

  const ConfigException(
    this.message, {
    this.category,
    this.itemKey,
    this.originalError,
  });

  @override
  String toString() {
    var msg = 'ConfigException: $message';
    if (category != null) msg += ' (category: $category)';
    if (itemKey != null) msg += ' (itemKey: $itemKey)';
    if (originalError != null) msg += ' (original: $originalError)';
    return msg;
  }
}

/// 配置验证结果
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasIssues => hasErrors || hasWarnings;

  @override
  String toString() {
    return 'ConfigValidationResult{isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length}}';
  }
}
