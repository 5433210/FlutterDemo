import 'package:flutter/foundation.dart';

import '../../domain/models/config/config_item.dart';
import '../../domain/services/config_service.dart';
import '../repositories/config_repository.dart';

/// 配置数据初始化器
class ConfigDataInitializer {
  final ConfigRepository _repository;

  ConfigDataInitializer(this._repository);

  /// 检查并初始化配置数据
  Future<void> ensureConfigData() async {
    try {
      debugPrint('🔧 ConfigDataInitializer: 开始检查配置数据');

      await _ensureStyleConfig();
      await _ensureToolConfig();

      debugPrint('✅ ConfigDataInitializer: 配置数据检查完成');
    } catch (e, stack) {
      debugPrint('❌ ConfigDataInitializer: 初始化配置数据失败: $e');
      debugPrint('❌ 堆栈: $stack');
      rethrow;
    }
  }

  /// 确保书法风格配置存在
  Future<void> _ensureStyleConfig() async {
    debugPrint('🎨 检查书法风格配置...');

    final existing =
        await _repository.getConfigCategory(ConfigCategories.style);
    if (existing != null && existing.items.isNotEmpty) {
      debugPrint('✅ 书法风格配置已存在，包含 ${existing.items.length} 个配置项');
      return;
    }

    debugPrint('🔧 创建默认书法风格配置...');

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
      ],
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(styleConfig);
    debugPrint('✅ 书法风格配置创建完成');
  }

  /// 确保书写工具配置存在
  Future<void> _ensureToolConfig() async {
    debugPrint('🖊️ 检查书写工具配置...');

    final existing = await _repository.getConfigCategory(ConfigCategories.tool);
    if (existing != null && existing.items.isNotEmpty) {
      debugPrint('✅ 书写工具配置已存在，包含 ${existing.items.length} 个配置项');
      return;
    }

    debugPrint('🔧 创建默认书写工具配置...');

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
          key: 'pen',
          displayName: '硬笔',
          sortOrder: 2,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Pen', 'zh': '硬笔'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'pencil',
          displayName: '铅笔',
          sortOrder: 3,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Pencil', 'zh': '铅笔'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
        ConfigItem(
          key: 'marker',
          displayName: '马克笔',
          sortOrder: 4,
          isSystem: true,
          isActive: true,
          localizedNames: {'en': 'Marker', 'zh': '马克笔'},
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        ),
      ],
      updateTime: DateTime.now(),
    );

    await _repository.saveConfigCategory(toolConfig);
    debugPrint('✅ 书写工具配置创建完成');
  }
}
