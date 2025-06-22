import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // 初始化sqflite_ffi
  sqfliteFfiInit();

  // 获取用户文档目录
  final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final documentsPath = path.join(userHome, 'Documents');
  final dataPath = path.join(documentsPath, 'storage', 'database');
  final dbPath = path.join(dataPath, 'app.db');

  print('字符编码问题诊断工具');
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
    
    // 设置UTF-8编码
    await db.execute('PRAGMA encoding = "UTF-8"');
    
    // 检查数据库编码
    final encodingResult = await db.rawQuery('PRAGMA encoding');
    print('数据库编码: ${encodingResult.first['encoding']}');
    print('');

    print('=== 检查有问题的作品数据 ===');
    
    // 查找包含特殊字符的作品
    final works = await db.rawQuery('''
      SELECT id, title, author, createTime 
      FROM works 
      WHERE title LIKE '%?%' OR title LIKE '%�%' OR title LIKE '%\uFFFD%'
      ORDER BY createTime DESC
      LIMIT 10
    ''');

    if (works.isEmpty) {
      print('未找到包含特殊字符的作品');
      
      // 显示最近的作品
      final recentWorks = await db.rawQuery('''
        SELECT id, title, author, createTime 
        FROM works 
        ORDER BY createTime DESC 
        LIMIT 5
      ''');
      
      print('\n最近的作品:');
      for (final work in recentWorks) {
        print('ID: ${work['id']}');
        print('标题: ${work['title']}');
        print('作者: ${work['author']}');
        print('创建时间: ${work['createTime']}');
        
        // 检查title字段的字节
        final title = work['title'] as String;
        final titleBytes = utf8.encode(title);
        print('标题字节数: ${titleBytes.length}');
        print('标题字节: ${titleBytes.take(20).toList()}'); // 显示前20个字节
        
        // 检查是否包含替换字符
        if (title.contains('\uFFFD') || title.contains('�')) {
          print('⚠️ 发现替换字符');
        }
        print('---');
      }
    } else {
      print('发现包含特殊字符的作品:');
      for (final work in works) {
        print('ID: ${work['id']}');
        print('标题: ${work['title']}');
        print('作者: ${work['author']}');
        print('创建时间: ${work['createTime']}');
        
        // 检查title字段的字节
        final title = work['title'] as String;
        final titleBytes = utf8.encode(title);
        print('标题字节数: ${titleBytes.length}');
        print('标题字节: ${titleBytes.take(50).toList()}');
        
        // 尝试不同的解码方式
        print('UTF-8解码尝试:');
        try {
          final utf8Decoded = utf8.decode(titleBytes);
          print('  UTF-8解码成功: $utf8Decoded');
        } catch (e) {
          print('  UTF-8解码失败: $e');
        }
        
        // 尝试Latin-1解码
        try {
          final latin1Decoded = latin1.decode(titleBytes);
          print('  Latin-1解码: $latin1Decoded');
        } catch (e) {
          print('  Latin-1解码失败: $e');
        }
        
        print('---');
      }
    }

    print('\n=== 创建编码测试数据 ===');
    
    // 创建一个包含特殊字符的测试作品
    final testWorkId = 'encoding-test-${DateTime.now().millisecondsSinceEpoch}';
    final testTitle = 'K书(测试)'; // 正常的汉字
    
    try {
      await db.insert('works', {
        'id': testWorkId,
        'title': testTitle,
        'author': '编码测试',
        'style': '',
        'tool': '',
        'remark': '这是一个编码测试',
        'createTime': DateTime.now().toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(),
        'tags': '',
        'status': 'draft',
        'imageCount': 0,
      });
      
      print('成功创建测试作品: $testWorkId');
      
      // 重新读取并验证
      final testWork = await db.rawQuery('SELECT * FROM works WHERE id = ?', [testWorkId]);
      if (testWork.isNotEmpty) {
        final retrievedTitle = testWork.first['title'] as String;
        print('重新读取的标题: $retrievedTitle');
        print('标题是否相同: ${retrievedTitle == testTitle}');
        
        if (retrievedTitle != testTitle) {
          print('⚠️ 数据库往返过程中标题发生了变化');
          print('原始: $testTitle');
          print('读取: $retrievedTitle');
        }
      }
      
    } catch (e) {
      print('❌ 创建测试作品失败: $e');
    }

    print('\n=== 导出测试 ===');
    
    // 模拟导出过程
    final exportWorks = await db.rawQuery('SELECT * FROM works ORDER BY createTime DESC LIMIT 3');
    
    print('准备导出的作品:');
    for (final work in exportWorks) {
      print('作品: ${work['title']}');
      
      // 模拟JSON序列化
      try {
        final workJson = jsonEncode(work);
        print('JSON序列化成功');
        
        // 模拟UTF-8编码
        final utf8Bytes = utf8.encode(workJson);
        print('UTF-8编码字节数: ${utf8Bytes.length}');
        
        // 模拟解码
        final decodedJson = utf8.decode(utf8Bytes);
        final decodedWork = jsonDecode(decodedJson);
        print('重新解码的标题: ${decodedWork['title']}');
        
      } catch (e) {
        print('❌ 导出测试失败: $e');
      }
      print('---');
    }

    await db.close();
    
  } catch (e) {
    print('❌ 数据库操作失败: $e');
  }
} 