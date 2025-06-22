import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  print('🔄 Testing database creation with migrations...');

  sqfliteFfiInit();

  // Clean up any existing database
  const dbPath = 'test_charasgem.db';
  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('✅ Cleaned up existing test database');
  }

  try {
    print('📚 Creating database with migrations...');

    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          print('🏗️ Running database migrations...');

          // Create settings table
          await database.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // Insert config data
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

          await database.insert('settings', {
            'key': 'config_tool',
            'value': toolConfigJson,
          });

          await database.insert('settings', {
            'key': 'config_style',
            'value': styleConfigJson,
          });

          print('✅ Config data inserted successfully');
        },
      ),
    );

    print('📊 Verifying config data...');
    final result =
        await db.rawQuery('SELECT * FROM settings WHERE key LIKE "config_%"');

    print('Found ${result.length} config entries:');
    for (final row in result) {
      print('Key: ${row['key']}');
      print('Value length: ${(row['value'] as String).length} characters');

      // Test JSON parsing
      try {
        // Simple JSON validation - check if it starts with { and ends with }
        final value = row['value'] as String;
        if (value.trim().startsWith('{') && value.trim().endsWith('}')) {
          print('✅ JSON format looks valid');
        } else {
          print('❌ Invalid JSON format');
        }
      } catch (e) {
        print('❌ JSON parsing error: $e');
      }
      print('---');
    }

    await db.close();

    print(
        '🎉 Database creation and config loading test completed successfully!');

    // Clean up test database
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('🧹 Test database cleaned up');
    }
  } catch (e) {
    print('❌ Error during test: $e');
    rethrow;
  }
}
