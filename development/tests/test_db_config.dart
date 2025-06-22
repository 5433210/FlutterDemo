import 'dart:async';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

// 简化的ConfigCategory类用于测试
class TestConfigCategory {
  final String category;
  final String displayName;
  final List<Map<String, dynamic>> items;
  final String? updateTime;

  TestConfigCategory({
    required this.category,
    required this.displayName,
    required this.items,
    this.updateTime,
  });

  factory TestConfigCategory.fromJson(Map<String, dynamic> json) {
    return TestConfigCategory(
      category: json['category'] as String,
      displayName: json['displayName'] as String,
      items: (json['items'] as List).cast<Map<String, dynamic>>(),
      updateTime: json['updateTime'] as String?,
    );
  }
}

void main() async {
  print('🧪 Testing database migration and config loading...');

  // 初始化 sqflite_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath = 'test_charasgem.db';

  try {
    // 删除现有数据库
    await databaseFactory.deleteDatabase(dbPath);
    print('🗑️ Deleted existing database');

    // 创建数据库并运行基本迁移
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        print('📊 Creating settings table...');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            createTime TEXT DEFAULT (datetime('now')),
            updateTime TEXT DEFAULT (datetime('now'))
          )
        ''');

        print('📝 Inserting test config data...');
        await db.insert('settings', {
          'key': 'tool_configs',
          'value': jsonEncode({
            'category': 'tool',
            'displayName': '书写工具',
            'updateTime': null,
            'items': [
              {
                'key': 'brush',
                'displayName': '毛笔',
                'sortOrder': 1,
                'isSystem': true,
                'isActive': true,
                'localizedNames': {'en': 'Brush', 'zh': '毛笔'},
                'createTime': null,
                'updateTime': null
              }
            ]
          }),
        });
        print('✅ Config data inserted');
      },
    );

    // 测试查询
    print('🔍 Querying config data...');
    final result = await db.rawQuery(
      'SELECT * FROM settings WHERE key = ? LIMIT 1',
      ['tool_configs'],
    );

    if (result.isEmpty) {
      print('❌ No data found');
      return;
    }

    print('📋 Raw result: ${result.first}');

    final configData = jsonDecode(result.first['value'] as String);
    print('📦 Decoded JSON: $configData');

    final category = TestConfigCategory.fromJson(configData);
    print('✅ ConfigCategory created successfully');
    print('📂 Category: ${category.category}');
    print('🏷️ Display Name: ${category.displayName}');
    print('📦 Items count: ${category.items.length}');

    await db.close();
    await databaseFactory.deleteDatabase(dbPath);
    print('🧹 Cleaned up test database');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('📍 Stack trace: $stackTrace');
  }
}
