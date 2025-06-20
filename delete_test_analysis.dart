import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // 初始化sqflite_ffi
  sqfliteFfiInit();

  // 获取用户文档目录
  final userHome =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final documentsPath = path.join(userHome, 'Documents');
  final dataPath = path.join(documentsPath, 'storage', 'database');
  final dbPath = path.join(dataPath, 'app.db');

  print('分析作品删除后字符数据的问题');
  print('数据库路径: $dbPath');
  print('');

  final dbFile = File(dbPath);
  if (!await dbFile.exists()) {
    print('❌ 数据库文件不存在');
    return;
  }

  try {
    // 打开数据库
    final db = await databaseFactoryFfi.openDatabase(dbPath);

    print('=== 1. 检查数据库级联删除约束 ===');

    // 检查characters表的外键约束
    final foreignKeys = await db.rawQuery('''
      SELECT sql FROM sqlite_master 
      WHERE type='table' AND name='characters'
    ''');

    if (foreignKeys.isNotEmpty) {
      final createSql = foreignKeys.first['sql'] as String;
      print('characters表创建SQL:');
      print(createSql);
      print('');

      if (createSql.contains('ON DELETE CASCADE')) {
        print('✅ 级联删除约束已正确设置');
      } else {
        print('❌ 级联删除约束缺失');
      }
    }

    print('');
    print('=== 2. 查看当前数据状态 ===');

    // 检查当前作品列表
    final works = await db.rawQuery('''
      SELECT id, title, author 
      FROM works 
      ORDER BY createTime DESC 
      LIMIT 10
    ''');

    print('当前作品列表 (最新10个):');
    for (final work in works) {
      print('  - ${work['id']}: ${work['title']} (${work['author']})');
    }
    print('');

    // 检查字符总数和按作品分组
    final characterStats = await db.rawQuery('''
      SELECT 
        w.id as workId,
        w.title as workTitle,
        w.author,
        COUNT(c.id) as characterCount
      FROM works w
      LEFT JOIN characters c ON w.id = c.workId
      GROUP BY w.id, w.title, w.author
      ORDER BY characterCount DESC
    ''');

    print('作品与字符关联统计:');
    for (final stat in characterStats) {
      final count = stat['characterCount'] as int;
      print('  - ${stat['workTitle']} (${stat['author']}): $count 个字符');
    }
    print('');

    // 检查是否有孤立的字符（作品已删除但字符仍存在）
    final orphanedCharacters = await db.rawQuery('''
      SELECT c.id, c.character, c.workId
      FROM characters c
      LEFT JOIN works w ON c.workId = w.id
      WHERE w.id IS NULL
    ''');

    if (orphanedCharacters.isNotEmpty) {
      print('❌ 发现孤立字符（作品已删除但字符仍存在）:');
      for (final orphan in orphanedCharacters) {
        print(
            '  - 字符: ${orphan['character']}, workId: ${orphan['workId']}, characterId: ${orphan['id']}');
      }
    } else {
      print('✅ 未发现孤立字符');
    }
    print('');

    print('=== 3. 测试删除作品是否能正确级联删除字符 ===');

    // 找一个有字符的作品
    final workWithCharacters = await db.rawQuery('''
      SELECT w.id, w.title, COUNT(c.id) as charCount
      FROM works w
      INNER JOIN characters c ON w.id = c.workId
      GROUP BY w.id, w.title
      LIMIT 1
    ''');

    if (workWithCharacters.isNotEmpty) {
      final testWork = workWithCharacters.first;
      final workId = testWork['id'] as String;
      final workTitle = testWork['title'] as String;
      final charCount = testWork['charCount'] as int;

      print('找到测试作品: $workTitle (ID: $workId), 包含 $charCount 个字符');
      print('⚠️  注意：这只是测试，不会真正删除数据');

      // 模拟删除（使用事务但最后回滚）
      await db.transaction((txn) async {
        // 记录删除前的字符
        final charactersBefore = await txn.rawQuery('''
          SELECT id, character FROM characters WHERE workId = ?
        ''', [workId]);

        print('删除前字符列表:');
        for (final char in charactersBefore) {
          print('  - ${char['character']} (${char['id']})');
        }

        // 执行删除作品
        await txn.delete('works', where: 'id = ?', whereArgs: [workId]);

        // 检查字符是否被级联删除
        final charactersAfter = await txn.rawQuery('''
          SELECT id, character FROM characters WHERE workId = ?
        ''', [workId]);

        print('删除后字符列表:');
        if (charactersAfter.isEmpty) {
          print('  ✅ 所有字符已被级联删除');
        } else {
          print('  ❌ 仍有字符存在:');
          for (final char in charactersAfter) {
            print('    - ${char['character']} (${char['id']})');
          }
        }

        // 回滚事务，不真正删除数据
        throw Exception('测试完成，回滚事务');
      }).catchError((e) {
        if (e.toString().contains('测试完成')) {
          print('✅ 测试完成，数据已回滚');
        } else {
          print('❌ 测试出错: $e');
        }
      });
    } else {
      print('❌ 未找到有字符的作品进行测试');
    }

    await db.close();

    print('');
    print('=== 4. 建议 ===');
    print('如果发现了孤立字符，可能的原因包括:');
    print('1. 早期版本的数据库迁移未正确设置外键约束');
    print('2. 应用程序直接删除作品而未通过正确的删除流程');
    print('3. 数据库引擎未启用外键约束支持');
    print('');
    print('解决方案:');
    print('1. 确保应用启动时执行 PRAGMA foreign_keys = ON');
    print('2. 在CharacterGridProvider中监听作品删除事件并主动刷新');
    print('3. 清理现有的孤立字符数据');
  } catch (e, stack) {
    print('❌ 分析过程中出错: $e');
    print('堆栈: $stack');
  }
}
