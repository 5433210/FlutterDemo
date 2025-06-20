import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // 初始化sqflite_ffi
  sqfliteFfiInit();

  // 获取数据库路径
  final userHome =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final documentsPath = path.join(userHome, 'Documents');
  final dataPath = path.join(documentsPath, 'storage', 'database');
  final dbPath = path.join(dataPath, 'app.db');

  print('测试work_images表中的libraryItemId字段功能...');

  try {
    final db = await databaseFactoryFfi.openDatabase(dbPath);

    // 查看是否有现有的work_images记录
    final existingImages = await db.query('work_images', limit: 5);
    print('📊 现有work_images记录数: ${existingImages.length}');

    if (existingImages.isNotEmpty) {
      print('📋 前5条记录的libraryItemId字段值:');
      for (int i = 0; i < existingImages.length; i++) {
        final record = existingImages[i];
        final libraryItemId = record['libraryItemId'];
        print('  ${i + 1}. ID: ${record['id']}, LibraryItemId: $libraryItemId');
      }
    }

    // 测试插入一条包含libraryItemId的记录
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final testLibraryItemId =
        'library_test_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('work_images', {
      'id': testId,
      'workId': 'test_work',
      'indexInWork': 1,
      'path': '/test/path.jpg',
      'format': 'jpg',
      'size': 1024,
      'width': 800,
      'height': 600,
      'createTime': DateTime.now().toIso8601String(),
      'updateTime': DateTime.now().toIso8601String(),
      'libraryItemId': testLibraryItemId, // 测试新字段
    });

    print('✅ 成功插入包含libraryItemId的测试记录');

    // 验证插入的记录
    final insertedRecord =
        await db.query('work_images', where: 'id = ?', whereArgs: [testId]);

    if (insertedRecord.isNotEmpty) {
      final record = insertedRecord.first;
      print('✅ 验证插入的记录:');
      print('   ID: ${record['id']}');
      print('   LibraryItemId: ${record['libraryItemId']}');

      if (record['libraryItemId'] == testLibraryItemId) {
        print('✅ libraryItemId字段存储和读取正常');
      } else {
        print('❌ libraryItemId字段值不匹配');
      }
    }

    // 清理测试数据
    await db.delete('work_images', where: 'id = ?', whereArgs: [testId]);
    print('🧹 已清理测试数据');

    await db.close();
    print('✅ libraryItemId功能测试完成');
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}
