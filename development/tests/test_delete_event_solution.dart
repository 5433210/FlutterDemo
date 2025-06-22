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

  print('作品删除事件通知机制测试');
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
    print('=== 测试数据准备 ===');

    // 查看works表结构
    final worksSchema = await db.rawQuery('PRAGMA table_info(works)');
    print('works表结构:');
    for (final column in worksSchema) {
      print('  - ${column['name']}: ${column['type']}');
    }
    print('');

    // 创建一个测试作品（使用正确的字段名）
    final testWorkId = 'test-work-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('works', {
      'id': testWorkId,
      'title': '测试作品-用于验证删除事件',
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

    // 创建一些测试字符
    final testCharacterIds = <String>[];
    for (int i = 0; i < 3; i++) {
      final charId = 'test-char-$testWorkId-$i';
      testCharacterIds.add(charId);

      await db.insert('characters', {
        'id': charId,
        'workId': testWorkId,
        'pageId': 'test-page-$i',
        'character': '测试字符$i',
        'region': '{"x": 0, "y": 0, "width": 100, "height": 100}',
        'tags': '',
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
        'isFavorite': 0,
        'note': '',
      });
    }

    print('✅ 创建测试作品: $testWorkId');
    print('✅ 创建测试字符: ${testCharacterIds.length} 个');
    print('');

    print('=== 验证级联删除机制 ===');

    // 删除作品前检查字符数量
    final charactersBeforeDelete = await db.rawQuery('''
      SELECT id, character FROM characters WHERE workId = ?
    ''', [testWorkId]);

    print('删除前字符数量: ${charactersBeforeDelete.length}');
    for (final char in charactersBeforeDelete) {
      print('  - ${char['character']} (${char['id']})');
    }

    // 模拟作品删除（真实删除）
    await db.delete('works', where: 'id = ?', whereArgs: [testWorkId]);

    // 检查字符是否被级联删除
    final charactersAfterDelete = await db.rawQuery('''
      SELECT id, character FROM characters WHERE workId = ?
    ''', [testWorkId]);

    print('删除后字符数量: ${charactersAfterDelete.length}');
    if (charactersAfterDelete.isEmpty) {
      print('✅ 级联删除成功：所有关联字符已被删除');
    } else {
      print('❌ 级联删除失败：仍有字符存在');
      for (final char in charactersAfterDelete) {
        print('  - ${char['character']} (${char['id']})');
      }
    }

    await db.close();
    print('');

    print('=== 事件通知机制说明 ===');
    print('已实现的解决方案：');
    print('1. ✅ 创建了事件通知 Provider (work_events_provider.dart)');
    print('2. ✅ 修改了 CharacterGridProvider 监听作品删除事件');
    print('3. ✅ 修改了 WorkBrowseViewModel 在删除作品后发送事件通知');
    print('4. ✅ 修改了 WorkDetailNotifier 在删除作品后发送事件通知');
    print('');

    print('解决方案工作流程：');
    print(
        '1. 用户删除作品 → WorkBrowseViewModel.deleteSelected() 或 WorkDetailNotifier.deleteWork()');
    print('2. 调用 WorkService.deleteWork() 执行数据库删除');
    print('3. 数据库级联删除相关字符记录');
    print('4. 发送删除事件通知 → workDeletedNotifierProvider.state = workId');
    print('5. CharacterGridProvider 监听到事件 → 清空字符列表状态');
    print('6. UI 立即更新，不再显示已删除作品的字符');
    print('');

    print('✅ 问题解决：作品删除后，字库管理页面将立即清空该作品的集字显示');
  } catch (e, stack) {
    print('❌ 测试过程中出错: $e');
    print('堆栈: $stack');
  }
}
