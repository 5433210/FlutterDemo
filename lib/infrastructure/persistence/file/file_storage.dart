import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileStorage {
  Future<String> get _basePath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Directory creation
  Future<void> createDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<String> getBackupDirectory() async {
    final basePath = await _basePath;
    return path.join(basePath, 'storage', 'backup');
  }

  Future<String> getCharsDirectory() async {
    final basePath = await _basePath;
    return path.join(basePath, 'storage', 'chars');
  }

  Future<String> getPracticesDirectory() async {
    final basePath = await _basePath;
    return path.join(basePath, 'storage', 'practices');
  }

  Future<String> getTempDirectory() async {
    final basePath = await _basePath;
    return path.join(basePath, 'storage', 'temp');
  }

  // Work-related methods
  Future<String> getWorkDirectory(String workId) async {
    final worksDirectory = await getWorksDirectory();
    return path.join(worksDirectory, workId);
  }

  Future<File> getWorkImportedPictureFile(String workId, int index) async {
    final pictureDirectory = await getWorkPictureDirectory(workId, index);
    final filePath = path.join(pictureDirectory, 'imported.png');
    return File(filePath);
  }

  Future<File> getWorkMetadataFile(String workId) async {
    final workDirectory = await getWorkDirectory(workId);
    final filePath = path.join(workDirectory, 'metadata.json');
    return File(filePath);
  }

  Future<File> getWorkOriginalPictureFile(
      String workId, int index, String ext) async {
    final pictureDirectory = await getWorkPictureDirectory(workId, index);
    final filePath = path.join(pictureDirectory, 'original.$ext');
    return File(filePath);
  }

  Future<String> getWorkPictureDirectory(String workId, int index) async {
    final workDirectory = await getWorkDirectory(workId);
    return path.join(workDirectory, 'pictures', index.toString());
  }

  Future<String> getWorksDirectory() async {
    final basePath = await _basePath;
    return path.join(basePath, 'storage', 'works');
  }

  Future<File> getWorkThumbnailFile(String workId) async {
    final workDirectory = await getWorkDirectory(workId);
    final filePath = path.join(workDirectory, 'thumbnail.jpg');
    return File(filePath);
  }

  Future<List<int>?> readFile(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> readJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error reading JSON from file: $e');
      return null;
    }
  }

  Future<void> writeFile(File file, List<int> data) async {
    await file.writeAsBytes(data);
  }

  // Generic read/write methods
  Future<void> writeJson(File file, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }
}
