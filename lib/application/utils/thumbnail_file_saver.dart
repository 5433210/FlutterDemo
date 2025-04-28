import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 缩略图文件保存工具
class ThumbnailFileSaver {
  /// 保存缩略图到文件系统
  /// 
  /// [thumbnailData] 缩略图数据
  /// [fileName] 文件名，如果为空，则使用时间戳作为文件名
  /// 
  /// 返回保存的文件路径
  static Future<String> saveThumbnail(
    Uint8List thumbnailData, {
    String? fileName,
  }) async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      
      // 创建缩略图目录
      final thumbnailDir = Directory(path.join(directory.path, 'thumbnails'));
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }
      
      // 生成文件名
      final name = fileName ?? 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(thumbnailDir.path, name);
      
      // 保存文件
      final file = File(filePath);
      await file.writeAsBytes(thumbnailData);
      
      debugPrint('缩略图已保存到: $filePath');
      return filePath;
    } catch (e, stack) {
      debugPrint('保存缩略图失败: $e');
      debugPrint('堆栈跟踪: $stack');
      rethrow;
    }
  }
  
  /// 获取缩略图目录
  static Future<String> getThumbnailDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailDir = path.join(directory.path, 'thumbnails');
    return thumbnailDir;
  }
  
  /// 打开缩略图目录
  static Future<void> openThumbnailDirectory() async {
    final thumbnailDir = await getThumbnailDirectory();
    
    if (Platform.isWindows) {
      await Process.run('explorer', [thumbnailDir]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [thumbnailDir]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [thumbnailDir]);
    }
  }
}
