import 'package:charasgem/domain/models/config/config_item.dart';

void main() {
  // 测试本地化显示名称
  const styleItem = ConfigItem(
    key: 'regular',
    displayName: '楷书',
    sortOrder: 1,
    isSystem: true,
    isActive: true,
    localizedNames: {
      'en': 'Regular Script',
      'zh': '楷书',
    },
  );

  const toolItem = ConfigItem(
    key: 'brush',
    displayName: '毛笔',
    sortOrder: 1,
    isSystem: true,
    isActive: true,
    localizedNames: {
      'en': 'Brush',
      'zh': '毛笔',
    },
  );

  // 测试不同语言场景
  print('=== 测试配置项本地化功能 ===');
  print('风格项目 - 原始displayName: ${styleItem.displayName}');
  print('风格项目 - 中文 (zh): ${styleItem.getDisplayName('zh')}');
  print('风格项目 - 英文 (en): ${styleItem.getDisplayName('en')}');
  print('风格项目 - 未知语言 (fr): ${styleItem.getDisplayName('fr')}');
  print('风格项目 - 空locale: ${styleItem.getDisplayName()}');

  print('\n书写工具 - 原始displayName: ${toolItem.displayName}');
  print('书写工具 - 中文 (zh): ${toolItem.getDisplayName('zh')}');
  print('书写工具 - 英文 (en): ${toolItem.getDisplayName('en')}');
  print('书写工具 - 未知语言 (fr): ${toolItem.getDisplayName('fr')}');
  print('书写工具 - 空locale: ${toolItem.getDisplayName()}');

  // 测试没有本地化名称的情况
  const noLocalizedItem = ConfigItem(
    key: 'test',
    displayName: '测试项目',
    sortOrder: 1,
    isSystem: true,
    isActive: true,
    localizedNames: {},
  );

  print('\n无本地化名称项目 - 原始displayName: ${noLocalizedItem.displayName}');
  print('无本地化名称项目 - 英文 (en): ${noLocalizedItem.getDisplayName('en')}');
  print('无本地化名称项目 - 中文 (zh): ${noLocalizedItem.getDisplayName('zh')}');

  print('\n✅ 本地化功能测试完成');
}
