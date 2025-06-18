import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 修复配置数据格式问题的脚本
Future<void> main() async {
  // 初始化sqflite_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    // 查找数据库文件
    final dbPath = await findDatabasePath();
    if (dbPath == null) {
      print('❌ 未找到数据库文件');
      return;
    }

    print('✅ 找到数据库文件: $dbPath');

    // 打开数据库
    final db = await openDatabase(dbPath);

    // 检查当前配置数据
    print('\n📋 当前配置数据:');
    final settingsResult = await db.rawQuery('SELECT * FROM settings');
    for (final row in settingsResult) {
      print('  ${row['key']}: ${row['value']}');
    }

    // 删除所有配置数据
    await db.delete('settings');
    print('\n🗑️ 已清除所有配置数据');

    // 重新插入正确格式的配置数据
    await insertDefaultConfigs(db);

    // 验证插入的数据
    print('\n✅ 重新插入的配置数据:');
    final newSettingsResult = await db.rawQuery('SELECT * FROM settings');
    for (final row in newSettingsResult) {
      print('  ${row['key']}: ${row['value']}');
    }

    await db.close();
    print('\n🎉 配置数据修复完成！');
  } catch (e, stackTrace) {
    print('❌ 修复配置数据时发生错误: $e');
    print('堆栈跟踪: $stackTrace');
  }
}

/// 查找数据库文件路径
Future<String?> findDatabasePath() async {
  final possiblePaths = [
    'app_database.db',
    './app_database.db',
    '../app_database.db',
    './charasgem.db',
    '../charasgem.db',
  ];

  for (final path in possiblePaths) {
    if (await File(path).exists()) {
      return path;
    }
  }
  return null;
}

/// 插入默认配置数据
Future<void> insertDefaultConfigs(Database db) async {
  // 书法风格配置
  final styleConfig = {
    'category': 'style',
    'displayName': '书法风格',
    'items': [
      {
        'key': 'regular_script',
        'displayName': '楷书',
        'isActive': true,
        'sortOrder': 1,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'running_script',
        'displayName': '行书',
        'isActive': true,
        'sortOrder': 2,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'cursive_script',
        'displayName': '草书',
        'isActive': true,
        'sortOrder': 3,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'seal_script',
        'displayName': '篆书',
        'isActive': true,
        'sortOrder': 4,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'clerical_script',
        'displayName': '隶书',
        'isActive': true,
        'sortOrder': 5,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
    ],
    'updateTime': DateTime.now().toIso8601String(),
  };

  // 书写工具配置
  final toolConfig = {
    'category': 'tool',
    'displayName': '书写工具',
    'items': [
      {
        'key': 'writing_brush',
        'displayName': '毛笔',
        'isActive': true,
        'sortOrder': 1,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'hard_pen',
        'displayName': '硬笔',
        'isActive': true,
        'sortOrder': 2,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
      {
        'key': 'finger_writing',
        'displayName': '指书',
        'isActive': true,
        'sortOrder': 3,
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
      },
    ],
    'updateTime': DateTime.now().toIso8601String(),
  };

  // 插入配置数据
  await db.insert('settings', {
    'key': 'style_configs',
    'value': jsonEncode(styleConfig),
  });

  await db.insert('settings', {
    'key': 'tool_configs',
    'value': jsonEncode(toolConfig),
  });

  print('📥 已插入默认配置数据');
}
