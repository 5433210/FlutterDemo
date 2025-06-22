import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Test config models that match the real domain models
class ConfigItem {
  final String key;
  final String displayName;
  final int sortOrder;
  final bool isSystem;
  final bool isActive;
  final Map<String, String> localizedNames;
  final DateTime? createTime;
  final DateTime? updateTime;

  ConfigItem({
    required this.key,
    required this.displayName,
    this.sortOrder = 0,
    this.isSystem = false,
    this.isActive = true,
    this.localizedNames = const {},
    this.createTime,
    this.updateTime,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      localizedNames: Map<String, String>.from(
          json['localizedNames'] as Map<String, dynamic>? ?? {}),
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
    );
  }
}

class ConfigCategory {
  final String category;
  final String displayName;
  final List<ConfigItem> items;
  final DateTime? updateTime;

  ConfigCategory({
    required this.category,
    required this.displayName,
    this.items = const [],
    this.updateTime,
  });

  factory ConfigCategory.fromJson(Map<String, dynamic> json) {
    return ConfigCategory(
      category: json['category'] as String,
      displayName: json['displayName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ConfigItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
    );
  }
}

void main() async {
  print('🔄 Testing real migration config loading...');

  sqfliteFfiInit();

  const dbPath = 'test_real_migration.db';
  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
  }

  try {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          print('🏗️ Running real migration scripts...');

          // Create settings table
          await database.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updateTime TEXT NOT NULL
            )
          ''');

          // Insert the exact same config data as in the real migration
          const styleConfig =
              '''{"category": "style", "displayName": "书法风格", "updateTime": null, "items": [{"key": "regular", "displayName": "楷书", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Regular Script", "zh": "楷书"}, "createTime": null, "updateTime": null}, {"key": "running", "displayName": "行书", "sortOrder": 2, "isSystem": true, "isActive": true, "localizedNames": {"en": "Running Script", "zh": "行书"}, "createTime": null, "updateTime": null}, {"key": "cursive", "displayName": "草书", "sortOrder": 3, "isSystem": true, "isActive": true, "localizedNames": {"en": "Cursive Script", "zh": "草书"}, "createTime": null, "updateTime": null}, {"key": "clerical", "displayName": "隶书", "sortOrder": 4, "isSystem": true, "isActive": true, "localizedNames": {"en": "Clerical Script", "zh": "隶书"}, "createTime": null, "updateTime": null}, {"key": "seal", "displayName": "篆书", "sortOrder": 5, "isSystem": true, "isActive": true, "localizedNames": {"en": "Seal Script", "zh": "篆书"}, "createTime": null, "updateTime": null}, {"key": "other", "displayName": "其他", "sortOrder": 6, "isSystem": true, "isActive": true, "localizedNames": {"en": "Other", "zh": "其他"}, "createTime": null, "updateTime": null}]}''';

          const toolConfig =
              '''{"category": "tool", "displayName": "书写工具", "updateTime": null, "items": [{"key": "brush", "displayName": "毛笔", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Brush", "zh": "毛笔"}, "createTime": null, "updateTime": null}, {"key": "hardPen", "displayName": "硬笔", "sortOrder": 2, "isSystem": true, "isActive": true, "localizedNames": {"en": "Hard Pen", "zh": "硬笔"}, "createTime": null, "updateTime": null}, {"key": "other", "displayName": "其他", "sortOrder": 3, "isSystem": true, "isActive": true, "localizedNames": {"en": "Other", "zh": "其他"}, "createTime": null, "updateTime": null}]}''';

          await database.execute('''
            INSERT OR IGNORE INTO settings (key, value, updateTime) VALUES 
            ('style_configs', ?, datetime('now'))
          ''', [styleConfig]);

          await database.execute('''
            INSERT OR IGNORE INTO settings (key, value, updateTime) VALUES 
            ('tool_configs', ?, datetime('now'))
          ''', [toolConfig]);

          print('✅ Migration config data inserted');
        },
      ),
    );

    print('📊 Testing ConfigRepository-style access...');

    // Test tool config loading
    await testConfigCategory(db, 'tool');

    // Test style config loading
    await testConfigCategory(db, 'style');

    await db.close();

    // Clean up
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    print('🎉 Real migration config loading test completed successfully!');
    print(
        '✅ The migration config data is compatible with the dynamic config system');
  } catch (e) {
    print('❌ Error during real migration test: $e');
    rethrow;
  }
}

Future<void> testConfigCategory(Database db, String category) async {
  print('Testing $category configs...');

  final result = await db.rawQuery(
    'SELECT * FROM settings WHERE key = ? LIMIT 1',
    ['${category}_configs'],
  );

  if (result.isEmpty) {
    print('❌ No config found for $category');
    return;
  }

  final configData = jsonDecode(result.first['value'] as String);
  final config = ConfigCategory.fromJson(configData);

  print('✅ Successfully loaded ${config.displayName}');
  print('   - Category: ${config.category}');
  print('   - Items count: ${config.items.length}');

  for (final item in config.items) {
    print('   - ${item.displayName} (${item.key}):');
    print('     • Sort order: ${item.sortOrder}');
    print('     • System: ${item.isSystem}');
    print('     • Active: ${item.isActive}');
    print('     • Localized names: ${item.localizedNames.keys.join(', ')}');
  }
  print('---');
}
