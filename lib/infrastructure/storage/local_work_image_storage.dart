import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/services/work_image_storage_interface.dart';
import '../../utils/path_helper.dart';

class LocalWorkImageStorage implements IWorkImageStorage {
  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to delete file',
        '',
        path,
        e,
      );
    }
  }

  @override
  Future<void> deleteWorkImage(String workId, String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to delete work image',
        workId,
        imagePath,
        e,
      );
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  @override
  Future<List<String>> getWorkImages(String workId) async {
    try {
      final basePath = await PathHelper.getWorkPath(workId);
      final directory = Directory(path.join(basePath, 'images'));

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) {
            return entity is File &&
                !path.basename(entity.path).startsWith('.');
          })
          .map((entity) => entity.path)
          .toList();

      return files;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get work images',
        workId,
        '',
        e,
      );
    }
  }

  @override
  Future<String> saveTempFile(List<int> bytes) async {
    try {
      final tempDir = await PathHelper.getTempDirectory();
      final tempFile =
          File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}');
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to save temp file',
        '',
        '',
        e,
      );
    }
  }

  @override
  Future<String> saveWorkImage(String workId, File image) async {
    try {
      final imageId = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);

      // 获取存储目录
      final imageDir = await PathHelper.getWorkImageDirectory(workId, imageId);
      await PathHelper.ensureDirectoryExists(imageDir);

      final targetPath = path.join(imageDir, 'original$extension');
      await image.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to save work image',
        workId,
        image.path,
        e,
      );
    }
  }
}

class WorkImageStorageException implements Exception {
  final String message;
  final String workId;
  final String path;
  final dynamic originalError;

  WorkImageStorageException(
      this.message, this.workId, this.path, this.originalError);

  @override
  String toString() =>
      'WorkImageStorageException: $message (workId: $workId, path: $path)';
}
