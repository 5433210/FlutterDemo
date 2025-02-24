import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../application/config/app_config.dart';

class PathHelper {
  static Future<String> getWorkDirectory(String workId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'works', workId);
  }

  static Future<String> getWorkThumbnailPath(String workId) async {
    // 使用和 StoragePaths 一致的路径结构
    final thumbnailPath = path.join(
      AppConfig.dataPath,
      AppConfig.storageFolder,
      AppConfig.worksFolder,
      workId,
      AppConfig.thumbnailFile
    );
    
    // 确保父目录存在
    final directory = Directory(path.dirname(thumbnailPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    debugPrint('Getting work thumbnail path: $thumbnailPath');
    
    // 检查文件是否存在
    final file = File(thumbnailPath);
    final exists = await file.exists();
    debugPrint('Thumbnail exists: $exists');
    
    return thumbnailPath;
  }
  
  static Future<bool> thumbnailExists(String workId) async {
    final thumbnailPath = await getWorkThumbnailPath(workId);
    return File(thumbnailPath).exists();
  }
}