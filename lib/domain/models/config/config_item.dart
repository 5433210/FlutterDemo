import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_item.freezed.dart';
part 'config_item.g.dart';

/// 配置项实体
@freezed
class ConfigItem with _$ConfigItem {
  const factory ConfigItem({
    /// 配置项的唯一键
    required String key,
    
    /// 显示名称
    required String displayName,
    
    /// 排序顺序
    @Default(0) int sortOrder,
    
    /// 是否为系统内置项（不可删除）
    @Default(false) bool isSystem,
    
    /// 是否激活状态
    @Default(true) bool isActive,
    
    /// 本地化名称映射
    @Default({}) Map<String, String> localizedNames,
    
    /// 扩展属性（JSON格式）
    @Default({}) Map<String, dynamic> metadata,
    
    /// 创建时间
    DateTime? createTime,
    
    /// 更新时间
    DateTime? updateTime,
  }) = _ConfigItem;

  factory ConfigItem.fromJson(Map<String, dynamic> json) =>
      _$ConfigItemFromJson(json);

  const ConfigItem._();

  /// 获取指定语言的显示名称
  String getDisplayName([String? locale]) {
    if (locale != null && localizedNames.containsKey(locale)) {
      return localizedNames[locale]!;
    }
    return displayName;
  }

  /// 复制并更新显示名称
  ConfigItem updateDisplayName(String newDisplayName) {
    return copyWith(
      displayName: newDisplayName,
      updateTime: DateTime.now(),
    );
  }

  /// 复制并更新排序顺序
  ConfigItem updateSortOrder(int newSortOrder) {
    return copyWith(
      sortOrder: newSortOrder,
      updateTime: DateTime.now(),
    );
  }

  /// 复制并切换激活状态
  ConfigItem toggleActive() {
    return copyWith(
      isActive: !isActive,
      updateTime: DateTime.now(),
    );
  }

  /// 复制并更新本地化名称
  ConfigItem updateLocalizedName(String locale, String name) {
    final updatedNames = Map<String, String>.from(localizedNames);
    updatedNames[locale] = name;
    return copyWith(
      localizedNames: updatedNames,
      updateTime: DateTime.now(),
    );
  }

  /// 验证配置项数据完整性
  bool get isValid {
    return key.isNotEmpty && displayName.isNotEmpty;
  }
}

/// 配置项分类
@freezed
class ConfigCategory with _$ConfigCategory {
  const factory ConfigCategory({
    /// 分类标识
    required String category,
    
    /// 分类显示名称
    required String displayName,
    
    /// 配置项列表
    @Default([]) List<ConfigItem> items,
    
    /// 更新时间
    DateTime? updateTime,
  }) = _ConfigCategory;

  factory ConfigCategory.fromJson(Map<String, dynamic> json) =>
      _$ConfigCategoryFromJson(json);

  const ConfigCategory._();

  /// 根据key查找配置项
  ConfigItem? findItemByKey(String key) {
    try {
      return items.firstWhere((item) => item.key == key);
    } catch (e) {
      return null;
    }
  }

  /// 获取激活的配置项
  List<ConfigItem> get activeItems {
    return items.where((item) => item.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 获取所有配置项（按排序顺序）
  List<ConfigItem> get sortedItems {
    return List<ConfigItem>.from(items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 添加配置项
  ConfigCategory addItem(ConfigItem item) {
    if (items.any((existing) => existing.key == item.key)) {
      return this; // 键重复，不添加
    }
    return copyWith(
      items: [...items, item],
      updateTime: DateTime.now(),
    );
  }

  /// 更新配置项
  ConfigCategory updateItem(ConfigItem item) {
    final index = items.indexWhere((existing) => existing.key == item.key);
    if (index == -1) return this;

    final updatedItems = List<ConfigItem>.from(items);
    updatedItems[index] = item;
    
    return copyWith(
      items: updatedItems,
      updateTime: DateTime.now(),
    );
  }

  /// 删除配置项
  ConfigCategory removeItem(String key) {
    final item = findItemByKey(key);
    if (item == null || item.isSystem) {
      return this; // 不存在或系统项不可删除
    }

    return copyWith(
      items: items.where((item) => item.key != key).toList(),
      updateTime: DateTime.now(),
    );
  }

  /// 重新排序配置项
  ConfigCategory reorderItems(List<String> keyOrder) {
    final itemMap = {for (var item in items) item.key: item};
    final reorderedItems = <ConfigItem>[];
    
    // 按指定顺序添加
    for (int i = 0; i < keyOrder.length; i++) {
      final key = keyOrder[i];
      final item = itemMap[key];
      if (item != null) {
        reorderedItems.add(item.copyWith(sortOrder: i + 1));
        itemMap.remove(key);
      }
    }
    
    // 添加剩余项目
    reorderedItems.addAll(itemMap.values);
    
    return copyWith(
      items: reorderedItems,
      updateTime: DateTime.now(),
    );
  }

  /// 验证分类数据完整性
  bool get isValid {
    return category.isNotEmpty && 
           displayName.isNotEmpty && 
           items.every((item) => item.isValid);
  }
}
