import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/services/work_image_storage_interface.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/path_helper.dart';

class WorkImageStorage implements IWorkImageStorage {
  final _uuid = const Uuid();

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      AppLogger.error('删除文件失败',
          tag: 'WorkImageStorage', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteWorkImage(String workId, String imagePath) async {
    try {
      await deleteFile(imagePath);
    } catch (e, stack) {
      AppLogger.error('删除作品图片失败',
          tag: 'WorkImageStorage',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'imagePath': imagePath});
      rethrow;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e, stack) {
      AppLogger.error('检查文件是否存在失败',
          tag: 'WorkImageStorage', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<List<String>> getWorkImages(String workId) async {
    try {
      final imageDir = await PathHelper.getWorkImageDirectory(workId, 0);
      if (!await Directory(imageDir).exists()) {
        return [];
      }

      final files = await Directory(imageDir)
          .list()
          .where((entity) => entity is File)
          .map((entity) => entity.path)
          .toList();

      return files;
    } catch (e, stack) {
      AppLogger.error('获取作品图片列表失败',
          tag: 'WorkImageStorage',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }

  @override
  Future<String> saveTempFile(List<int> bytes) async {
    try {
      final tempDir = await PathHelper.getTempDirectory();
      final fileName = '${_uuid.v4()}.tmp';
      final filePath = path.join(tempDir.path, fileName);

      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e, stack) {
      AppLogger.error('保存临时文件失败',
          tag: 'WorkImageStorage', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<String> saveWorkImage(String workId, File image) async {
    try {
      final imageDir = await PathHelper.getWorkImageDirectory(workId, 0);
      await PathHelper.ensureDirectoryExists(imageDir);

      final fileName = '${_uuid.v4()}${path.extension(image.path)}';
      final destPath = path.join(imageDir, fileName);

      await image.copy(destPath);

      return destPath;
    } catch (e, stack) {
      AppLogger.error('保存作品图片失败',
          tag: 'WorkImageStorage',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'imagePath': image.path});
      rethrow;
    }
  }
}
