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

  print('数据库字符损坏修复工具');
  print('数据库路径: $dbPath');
  print('');

  final dbFile = File(dbPath);
  if (!await dbFile.exists()) {
    print('❌ 数据库文件不存在');
    return;
  }

  try {
    // 创建备份
    final backupPath = '$dbPath.backup.${DateTime.now().millisecondsSinceEpoch}';
    await dbFile.copy(backupPath);
    print('✅ 已创建数据库备份: $backupPath');

    // 打开数据库
    final db = await databaseFactoryFfi.openDatabase(dbPath);
    
    print('\n=== 开始修复作品标题 ===');
    
    // 查找并修复works表中的损坏数据
    final works = await db.rawQuery('SELECT id, title, author, remark FROM works');
    int fixedCount = 0;
    
    for (final work in works) {
      final id = work['id'] as String;
      final title = work['title'] as String?;
      final author = work['author'] as String?;
      final remark = work['remark'] as String?;
      
      bool needsUpdate = false;
      String? fixedTitle;
      String? fixedAuthor;
      String? fixedRemark;
      
      // 修复标题
      if (title != null) {
        fixedTitle = _cleanCorruptedText(title);
        if (fixedTitle != title) {
          print('修复标题: "$title" -> "$fixedTitle"');
          needsUpdate = true;
        }
      }
      
      // 修复作者
      if (author != null) {
        fixedAuthor = _cleanCorruptedText(author);
        if (fixedAuthor != author) {
          print('修复作者: "$author" -> "$fixedAuthor"');
          needsUpdate = true;
        }
      }
      
      // 修复备注
      if (remark != null) {
        fixedRemark = _cleanCorruptedText(remark);
        if (fixedRemark != remark) {
          print('修复备注: "$remark" -> "$fixedRemark"');
          needsUpdate = true;
        }
      }
      
      // 更新数据库
      if (needsUpdate) {
        await db.update(
          'works',
          {
            if (fixedTitle != null) 'title': fixedTitle,
            if (fixedAuthor != null) 'author': fixedAuthor,
            if (fixedRemark != null) 'remark': fixedRemark,
            'updateTime': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        fixedCount++;
      }
    }
    
    print('\n=== 开始修复字符数据 ===');
    
    // 查找并修复characters表中的损坏数据
    final characters = await db.rawQuery('SELECT id, character, note FROM characters');
    int fixedCharCount = 0;
    
    for (final char in characters) {
      final id = char['id'] as String;
      final character = char['character'] as String?;
      final note = char['note'] as String?;
      
      bool needsUpdate = false;
      String? fixedCharacter;
      String? fixedNote;
      
      // 修复字符
      if (character != null) {
        fixedCharacter = _cleanCorruptedText(character);
        if (fixedCharacter != character) {
          print('修复字符: "$character" -> "$fixedCharacter"');
          needsUpdate = true;
        }
      }
      
      // 修复备注
      if (note != null) {
        fixedNote = _cleanCorruptedText(note);
        if (fixedNote != note) {
          print('修复字符备注: "$note" -> "$fixedNote"');
          needsUpdate = true;
        }
      }
      
      // 更新数据库
      if (needsUpdate) {
        await db.update(
          'characters',
          {
            if (fixedCharacter != null) 'character': fixedCharacter,
            if (fixedNote != null) 'note': fixedNote,
            'updateTime': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        fixedCharCount++;
      }
    }

    print('\n=== 修复完成 ===');
    print('修复的作品数量: $fixedCount');
    print('修复的字符数量: $fixedCharCount');
    
    // 验证修复结果
    print('\n=== 验证修复结果 ===');
    final corruptedWorks = await db.rawQuery('''
      SELECT id, title FROM works 
      WHERE title LIKE '%�%' OR title LIKE '%\uFFFD%'
    ''');
    
    if (corruptedWorks.isEmpty) {
      print('✅ 未发现损坏的作品标题');
    } else {
      print('⚠️ 仍有${corruptedWorks.length}个作品包含损坏字符');
      for (final work in corruptedWorks) {
        print('  - ${work['id']}: ${work['title']}');
      }
    }

    await db.close();
    print('\n✅ 修复完成');
    
  } catch (e) {
    print('❌ 修复失败: $e');
  }
}

/// 清理损坏的文本
String _cleanCorruptedText(String text) {
  if (text.isEmpty) return text;
  
  String cleaned = text;
  
  // 移除UTF-8替换字符
  cleaned = cleaned.replaceAll('\uFFFD', '');
  cleaned = cleaned.replaceAll('�', '');
  
  // 移除控制字符
  cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  
  // 移除零宽字符
  cleaned = cleaned.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
  
  // 移除其他可能的替换字符
  cleaned = cleaned.replaceAll(RegExp(r'[\uFFF0-\uFFFF]'), '');
  
  // 修复常见的编码问题
  final Map<String, String> fixes = {
    'ï¿½': '',  // UTF-8 BOM 问题
    'â€™': "'",  // 单引号编码问题
    'â€œ': '"',  // 左双引号编码问题
    'â€': '"',   // 右双引号编码问题
    'â€"': '—',  // 长破折号编码问题
    'â€"': '–',  // 短破折号编码问题
  };
  
  for (final entry in fixes.entries) {
    cleaned = cleaned.replaceAll(entry.key, entry.value);
  }
  
  // 清理多余的空格
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  // 如果清理后的文本为空，提供一个默认值
  if (cleaned.isEmpty && text.isNotEmpty) {
    // 尝试从原始文本中提取可读字符
    final readable = text.runes
        .where((rune) => rune >= 32 && rune < 127 || (rune >= 0x4e00 && rune <= 0x9fff))
        .map((rune) => String.fromCharCode(rune))
        .join('');
    
    if (readable.isNotEmpty) {
      cleaned = readable;
    } else {
      cleaned = '未知标题'; // 最后的回退选项
    }
  }
  
  return cleaned;
} 