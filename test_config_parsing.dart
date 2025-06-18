import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Minimal domain models for testing
class ConfigCategory {
  final String id;
  final String displayName;
  final List<ConfigItem> items;

  ConfigCategory({
    required this.id,
    required this.displayName,
    required this.items,
  });

  factory ConfigCategory.fromJson(Map<String, dynamic> json) {
    return ConfigCategory(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ConfigItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConfigItem {
  final String id;
  final String displayName;
  final String description;
  final String icon;
  final String category;
  final bool isActive;
  final int sortOrder;
  final Map<String, dynamic>? metadata;

  ConfigItem({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.category,
    required this.isActive,
    required this.sortOrder,
    this.metadata,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      isActive: json['isActive'] as bool,
      sortOrder: json['sortOrder'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

void main() async {
  print('🔄 Testing config data parsing with domain models...');

  sqfliteFfiInit();

  const dbPath = 'test_config_parsing.db';
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
          await database.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          const toolConfigJson = '''
{
  "id": "tool_config",
  "displayName": "书写工具",
  "items": [
    {
      "id": "brush",
      "displayName": "毛笔",
      "description": "传统书法毛笔",
      "icon": "brush",
      "category": "traditional",
      "isActive": true,
      "sortOrder": 1,
      "metadata": {
        "strokeWidth": {"min": 1.0, "max": 20.0, "default": 5.0},
        "opacity": {"min": 0.1, "max": 1.0, "default": 0.9},
        "hardness": {"min": 0.1, "max": 1.0, "default": 0.7}
      }
    },
    {
      "id": "pen",
      "displayName": "钢笔",
      "description": "现代硬笔书写工具",
      "icon": "edit",
      "category": "modern",
      "isActive": true,
      "sortOrder": 2,
      "metadata": {
        "strokeWidth": {"min": 0.5, "max": 5.0, "default": 1.5},
        "opacity": {"min": 0.8, "max": 1.0, "default": 1.0}
      }
    }
  ]
}''';

          const styleConfigJson = '''
{
  "id": "style_config",
  "displayName": "书法风格",
  "items": [
    {
      "id": "kaishu",
      "displayName": "楷书",
      "description": "端正工整的楷书风格",
      "icon": "grid_3x3",
      "category": "traditional",
      "isActive": true,
      "sortOrder": 1,
      "metadata": {
        "strokeOrder": true,
        "gridLines": true,
        "structure": "square"
      }
    },
    {
      "id": "xingshu",
      "displayName": "行书",
      "description": "流动自然的行书风格",
      "icon": "gesture",
      "category": "traditional",
      "isActive": true,
      "sortOrder": 2,
      "metadata": {
        "strokeOrder": false,
        "gridLines": false,
        "structure": "flowing"
      }
    }
  ]
}''';

          await database.insert(
              'settings', {'key': 'config_tool', 'value': toolConfigJson});
          await database.insert(
              'settings', {'key': 'config_style', 'value': styleConfigJson});
        },
      ),
    );

    print('📊 Testing domain model parsing...');
    final result =
        await db.rawQuery('SELECT * FROM settings WHERE key LIKE "config_%"');

    for (final row in result) {
      final key = row['key'] as String;
      final value = row['value'] as String;

      print('Testing $key...');

      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        final config = ConfigCategory.fromJson(json);

        print('✅ Successfully parsed config: ${config.displayName}');
        print('   - Items count: ${config.items.length}');
        for (final item in config.items) {
          print('   - ${item.displayName} (${item.id}): ${item.description}');
          if (item.metadata != null) {
            print('     Metadata keys: ${item.metadata!.keys.join(', ')}');
          }
        }
      } catch (e) {
        print('❌ Failed to parse $key: $e');
        rethrow;
      }
      print('---');
    }

    await db.close();

    // Clean up
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    print('🎉 Config data parsing test completed successfully!');
    print('✅ All config data is compatible with domain models');
  } catch (e) {
    print('❌ Error during config parsing test: $e');
    rethrow;
  }
}
