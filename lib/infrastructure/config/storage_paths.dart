import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StoragePaths {
  final String basePath;
  
  const StoragePaths(this.basePath);

  // Work related paths
  String get worksPath => path.join(basePath, 'works');
  String getWorkPath(String workId) => path.join(worksPath, workId);
  String getWorkThumbnailPath(String workId) => 
      path.join(getWorkPath(workId), 'thumbnail.jpg');
  
  String getWorkPicturePath(String workId, int index) => 
      path.join(getWorkPath(workId), 'pictures', index.toString());
  
  String getWorkOriginalPicturePath(String workId, int index, String ext) =>
      path.join(getWorkPicturePath(workId, index), 'original$ext');
  
  String getWorkImportedPicturePath(String workId, int index) =>
      path.join(getWorkPicturePath(workId, index), 'imported.png');

  String getWorkImportedThumbnailPath(String workId, int index) =>
      path.join(getWorkPicturePath(workId, index), 'thumbnail.jpg');

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