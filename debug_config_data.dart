import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() async {
  try {
    // 获取数据库路径
    final dbPath = await getDatabasePath();
    print('📍 数据库路径: $dbPath');

    if (!File(dbPath).existsSync()) {
      print('❌ 数据库文件不存在');
      return;
    }

    // 打开数据库
    final db = sqlite3.open(dbPath);

    try {
      print('\n📋 检查配置表结构...');
      final tableInfo = db.select('PRAGMA table_info(settings)');
      print('settings 表结构:');
      for (final row in tableInfo) {
        print('  ${row['name']}: ${row['type']}');
      }

      print('\n📋 当前配置数据:');
      final configs = db.select(
          "SELECT key, value, updateTime FROM settings WHERE key LIKE '%_configs'");

      if (configs.isEmpty) {
        print('⚠️ 没有找到配置数据');
      } else {
        for (final config in configs) {
          print('\n🔑 配置键: ${config['key']}');
          print('📅 更新时间: ${config['updateTime']}');

          try {
            final configData = jsonDecode(config['value'] as String);
            print('📦 配置数据 (JSON):');
            print('  分类: ${configData['category']}');
            print('  显示名称: ${configData['displayName']}');

            if (configData['items'] != null) {
              final items = configData['items'] as List;
              print('  配置项数量: ${items.length}');

              for (int i = 0; i < items.length; i++) {
                final item = items[i];
                print(
                    '    [$i] key: ${item['key']}, displayName: ${item['displayName']}, isActive: ${item['isActive']}');
              }
            } else {
              print('  ⚠️ 配置项为null');
            }
          } catch (e) {
            print('❌ 解析配置数据失败: $e');
            print('原始数据: ${config['value']}');
          }
        }
      }
    } finally {
      db.dispose();
    }

    print('\n✅ 数据库检查完成');
  } catch (e, stack) {
    print('❌ 检查配置数据时发生错误: $e');
    print('堆栈跟踪: $stack');
  }
}

Future<String> getDatabasePath() async {
  // Windows 应用数据路径
  final appDataDir = Platform.environment['LOCALAPPDATA'];
  if (appDataDir != null) {
    final dbDir = path.join(appDataDir, 'demo', 'databases');
    return path.join(dbDir, 'demo.db');
  }

  // 回退到当前目录
  return 'demo.db';
}
