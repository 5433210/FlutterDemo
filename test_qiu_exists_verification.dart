import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 验证"秋"字在数据库中是否真实存在
void main() async {
  // 初始化 FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('=== 验证"秋"字在数据库中的存在性 ===');

  try {
    // 查找数据库文件
    final dbPath = await _findDatabasePath();
    if (dbPath == null) {
      print('❌ 未找到数据库文件');
      return;
    }

    print('📁 数据库路径: $dbPath');

    // 打开数据库
    final db = await openDatabase(dbPath, readOnly: true);
    print('✅ 数据库打开成功');

    // 1. 直接搜索"秋"字
    print('\n1. 直接搜索"秋"字:');
    final directResult = await db.query(
      'characters',
      where: 'character = ?',
      whereArgs: ['秋'],
    );
    print('   结果数量: ${directResult.length}');
    for (var row in directResult) {
      print(
          '   - ID: ${row['id']}, 字符: ${row['character']}, 拼音: ${row['pinyin']}');
    }

    // 2. 模糊搜索包含"秋"的记录
    print('\n2. 模糊搜索包含"秋"的记录:');
    final likeResult = await db.query(
      'characters',
      where: 'character LIKE ?',
      whereArgs: ['%秋%'],
    );
    print('   结果数量: ${likeResult.length}');
    for (var row in likeResult) {
      print(
          '   - ID: ${row['id']}, 字符: ${row['character']}, 拼音: ${row['pinyin']}');
    }

    // 3. 检查字符表结构
    print('\n3. 字符表结构:');
    final tableInfo = await db.rawQuery('PRAGMA table_info(characters)');
    for (var column in tableInfo) {
      print('   - ${column['name']}: ${column['type']}');
    }

    // 4. 统计总字符数
    print('\n4. 字符表统计:');
    final countResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM characters');
    print('   总字符数: ${countResult.first['count']}');

    // 5. 搜索所有汉字字符（简单范围检查）
    print('\n5. 汉字字符范围检查:');
    final chineseResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM characters 
      WHERE unicode(character) >= unicode('一') 
      AND unicode(character) <= unicode('龯')
    ''');
    print('   汉字字符数: ${chineseResult.first['count']}');

    // 6. 查看"秋"字的Unicode值
    print('\n6. "秋"字Unicode信息:');
    const qiuChar = '秋';
    print('   Unicode码点: ${qiuChar.codeUnitAt(0)}');
    print('   十六进制: 0x${qiuChar.codeUnitAt(0).toRadixString(16)}');

    await db.close();
    print('\n✅ 数据库验证完成');
  } catch (e, stackTrace) {
    print('❌ 验证过程中出错: $e');
    print('栈跟踪: $stackTrace');
  }
}

Future<String?> _findDatabasePath() async {
  final possiblePaths = [
    'assets/databases/characters.db',
    'assets/characters.db',
    'database/characters.db',
    'lib/assets/databases/characters.db',
  ];

  for (final dbPath in possiblePaths) {
    final file = File(dbPath);
    if (await file.exists()) {
      return dbPath;
    }
  }

  // 递归搜索
  final currentDir = Directory.current;
  await for (final entity in currentDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('characters.db')) {
      return entity.path;
    }
  }

  return null;
}
