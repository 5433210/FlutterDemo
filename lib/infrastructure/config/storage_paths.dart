import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../application/config/app_config.dart';

class StoragePaths {
  final String basePath;
  
  const StoragePaths(this.basePath);

  // Work related paths
  String get worksPath => path.join(basePath, AppConfig.worksFolder);
  
  String getWorkPath(String workId) {
    // 删除额外的 storage 文件夹引用
    final workPath = path.join(
      AppConfig.dataPath,  // 这已经是完整路径
      AppConfig.storageFolder,
      AppConfig.worksFolder, 
      workId
    );
    debugPrint('Getting work path: $workPath');
    return workPath;
  }

  String getWorkThumbnailPath(String workId) {
    final thumbnailPath = path.join(getWorkPath(workId), AppConfig.thumbnailFile);
    debugPrint('Getting work thumbnail path: $thumbnailPath');
    return thumbnailPath;
  }
  
  String getWorkPicturePath(String workId, int index) => 
      path.join(getWorkPath(workId), 'pictures', index.toString());
  
  String getWorkOriginalPicturePath(String workId, int index, String ext) =>
      path.join(getWorkPicturePath(workId, index), 'original$ext');
  
  String getWorkImportedPicturePath(String workId, int index) =>
      path.join(getWorkPicturePath(workId, index), 'imported.png');

  String getWorkImportedThumbnailPath(String workId, int index) =>
      path.join(getWorkPicturePath(workId, index), 'thumbnail.jpg');

  Future<void> ensureWorkDirectoryExists(String workId) async {
    final workPath = getWorkPath(workId);
    final thumbnailPath = path.join(workPath, AppConfig.thumbnailFile);
    
    debugPrint('Ensuring directories exist:');
    debugPrint('Work path: $workPath');
    debugPrint('Thumbnail path: $thumbnailPath');
    
    await ensureDirectoryExists(path.dirname(thumbnailPath));
  }

  // Character related paths
  String get charsPath => path.join(basePath, 'chars');
  String getCharPath(String charId) => path.join(charsPath, charId);
  String getCharImagePath(String charId) => 
      path.join(getCharPath(charId), 'char.png');
  String getCharThumbnailPath(String charId) => 
      path.join(getCharPath(charId), 'thumbnail.jpg');

  // Practice related paths
  String get practicesPath => path.join(basePath, 'practices');
  String getPracticePath(String practiceId) => 
      path.join(practicesPath, practiceId);
  String getPracticeThumbnailPath(String practiceId) => 
      path.join(getPracticePath(practiceId), 'thumbnail.jpg');

  // Temp and backup paths
  String get tempPath => path.join(basePath, 'temp');
  String get backupPath => path.join(basePath, 'backup');

  // Helper methods
  Future<void> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<String> createTempFile(String prefix, String ext) async {
    await ensureDirectoryExists(tempPath);
    final uuid = const Uuid().v4();
    return path.join(tempPath, '$prefix-$uuid$ext');
  }

  Future<void> cleanupTempFiles() async {
    final temp = Directory(tempPath);
    if (await temp.exists()) {
      await for (final file in temp.list()) {
        await file.delete();
      }
    }
  }
}