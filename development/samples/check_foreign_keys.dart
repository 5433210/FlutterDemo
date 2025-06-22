import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();

  final userHome =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final documentsPath = path.join(userHome, 'Documents');
  final dataPath = path.join(documentsPath, 'storage', 'database');
  final dbPath = path.join(dataPath, 'app.db');

  try {
    final db = await databaseFactoryFfi.openDatabase(dbPath);

    // 检查外键约束是否启用
    final foreignKeysResult = await db.rawQuery('PRAGMA foreign_keys');
    final foreignKeysEnabled = foreignKeysResult.first['foreign_keys'] == 1;
    print('外键约束状态: ${foreignKeysEnabled ? "已启用" : "未启用"}');

    // 如果未启用，手动启用
    if (!foreignKeysEnabled) {
      await db.execute('PRAGMA foreign_keys = ON');
      print('已启用外键约束');
    }

    // 再次检查
    final foreignKeysResult2 = await db.rawQuery('PRAGMA foreign_keys');
    final foreignKeysEnabled2 = foreignKeysResult2.first['foreign_keys'] == 1;
    print('外键约束状态（启用后）: ${foreignKeysEnabled2 ? "已启用" : "未启用"}');

    // 清理之前的测试数据
    await db
        .delete('characters', where: 'character LIKE ?', whereArgs: ['测试字符%']);
    await db.delete('works', where: 'title LIKE ?', whereArgs: ['测试作品-%']);

    // 创建测试数据
    const testWorkId = 'test-work-cascade';
    await db.insert('works', {
      'id': testWorkId,
      'title': '测试作品-级联删除',
      'author': '测试',
      'style': '',
      'tool': '',
      'remark': '',
      'createTime': DateTime.now().toIso8601String(),
      'updateTime': DateTime.now().toIso8601String(),
      'tags': '',
      'status': 'draft',
      'imageCount': 0,
    });

    await db.insert('characters', {
      'id': 'test-char-cascade',
      'workId': testWorkId,
      'pageId': 'test-page',
      'character': '测试字符',
      'region': '{"x": 0, "y": 0, "width": 100, "height": 100}',
      'tags': '',
      'createTime': DateTime.now().toIso8601String(),
      'updateTime': DateTime.now().toIso8601String(),
      'isFavorite': 0,
      'note': '',
    });

    print('创建测试数据完成');

    // 验证数据存在
    final charsBefore = await db
        .query('characters', where: 'workId = ?', whereArgs: [testWorkId]);
    print('删除前字符数量: ${charsBefore.length}');

    // 删除作品
    final deleteResult =
        await db.delete('works', where: 'id = ?', whereArgs: [testWorkId]);
    print('删除作品结果: $deleteResult');

    // 检查字符是否被删除
    final charsAfter = await db
        .query('characters', where: 'workId = ?', whereArgs: [testWorkId]);
    print('删除后字符数量: ${charsAfter.length}');

    if (charsAfter.isEmpty) {
      print('✅ 级联删除成功');
    } else {
      print('❌ 级联删除失败');

      // 手动检查外键约束定义
      final schema = await db.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name='characters'");
      print('characters表定义:');
      print(schema.first['sql']);
    }

    await db.close();
  } catch (e, stack) {
    print('错误: $e');
    print('堆栈: $stack');
  }
}
