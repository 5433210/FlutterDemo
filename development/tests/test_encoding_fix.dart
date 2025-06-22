import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

void main() async {
  print('测试字符编码修复...');
  
  // 创建包含特殊字符的测试数据
  final testData = {
    'title': 'KÕ(\\Á',  // 包含特殊字符的标题
    'author': '测试作者',
    'content': '这是一个包含特殊字符的测试：éñüñü',
    'description': '测试描述 with émojis 🎉',
  };
  
  print('原始数据: $testData');
  
  // 测试旧方式（使用codeUnits）
  print('\n=== 测试旧方式（codeUnits）===');
  try {
    final jsonString1 = jsonEncode(testData);
    final codeUnits = jsonString1.codeUnits;
    final restored1 = String.fromCharCodes(codeUnits);
    final decoded1 = jsonDecode(restored1);
    print('旧方式成功: $decoded1');
  } catch (e) {
    print('旧方式失败: $e');
  }
  
  // 测试新方式（使用UTF-8）
  print('\n=== 测试新方式（UTF-8）===');
  try {
    final jsonString2 = jsonEncode(testData);
    final utf8Bytes = utf8.encode(jsonString2);
    final restored2 = utf8.decode(utf8Bytes);
    final decoded2 = jsonDecode(restored2);
    print('新方式成功: $decoded2');
  } catch (e) {
    print('新方式失败: $e');
  }
  
  // 测试Archive中的使用
  print('\n=== 测试Archive中的使用 ===');
  final archive = Archive();
  
  // 旧方式
  try {
    final jsonString = jsonEncode(testData);
    final archiveFile1 = ArchiveFile('test_old.json', jsonString.length, jsonString.codeUnits);
    archive.addFile(archiveFile1);
    print('Archive旧方式添加成功');
  } catch (e) {
    print('Archive旧方式失败: $e');
  }
  
  // 新方式
  try {
    final jsonString = jsonEncode(testData);
    final utf8Bytes = utf8.encode(jsonString);
    final archiveFile2 = ArchiveFile('test_new.json', utf8Bytes.length, utf8Bytes);
    archive.addFile(archiveFile2);
    print('Archive新方式添加成功');
  } catch (e) {
    print('Archive新方式失败: $e');
  }
  
  // 创建ZIP并测试读取
  print('\n=== 测试ZIP读取 ===');
  try {
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    
    // 写入文件
    final file = File('test_encoding.zip');
    await file.writeAsBytes(zipData);
    
    // 读取并解析
    final readBytes = await file.readAsBytes();
    final readArchive = ZipDecoder().decodeBytes(readBytes);
    
    for (final archiveFile in readArchive.files) {
      print('\n文件: ${archiveFile.name}');
      try {
        // 尝试UTF-8解码
        final content = utf8.decode(archiveFile.content as List<int>);
        final data = jsonDecode(content);
        print('UTF-8解码成功: $data');
      } catch (e) {
        print('UTF-8解码失败: $e');
        
        // 尝试fromCharCodes
        try {
          final content = String.fromCharCodes(archiveFile.content as List<int>);
          final data = jsonDecode(content);
          print('fromCharCodes成功: $data');
        } catch (e2) {
          print('fromCharCodes也失败: $e2');
        }
      }
    }
    
    // 清理测试文件
    await file.delete();
    
  } catch (e) {
    print('ZIP测试失败: $e');
  }
  
  print('\n测试完成！');
} 