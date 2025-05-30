import 'package:path/path.dart' as path;

import '../../infrastructure/logging/logger.dart';
import 'storage_interface.dart';

/// 图库文件存储服务
class LibraryFileStorage {
  final IStorage _storage;

  LibraryFileStorage(this._storage);

  /// 删除项目相关的所有文件
  Future<void> deleteItemFiles(String itemId) async {
    try {
      // 获取项目目录路径
      final directoryPath =
          path.join(_storage.getAppDataPath(), 'library', itemId);

      AppLogger.debug('准备删除项目目录', data: {
        'itemId': itemId,
        'directoryPath': directoryPath,
      });

      // 检查并删除整个目录
      if (await _storage.directoryExists(directoryPath)) {
        await _storage.deleteDirectory(directoryPath);
        AppLogger.info('项目目录删除成功', data: {'itemId': itemId});
      } else {
        AppLogger.warning('项目目录不存在', data: {'itemId': itemId});
      }
    } catch (e, stack) {
      AppLogger.error('删除项目目录失败',
          error: e, stackTrace: stack, data: {'itemId': itemId});
      rethrow;
    }
  }

  /// 获取项目文件目录路径
  String getItemPath(String itemId) {
    return path.join(_storage.getAppDataPath(), 'library', 'items', itemId);
  }

  /// 获取项目原始文件路径
  String getOriginalFilePath(String itemId) {
    return path.join(
        getItemPath(itemId), 'original${_getFileExtension(itemId)}');
  }

  /// 获取项目缩略图路径
  String getThumbnailPath(String itemId) {
    return path.join(getItemPath(itemId), 'thumbnail.jpg');
  }

  /// 获取文件扩展名
  String _getFileExtension(String itemId) {
    // 从项目元数据中获取实际的文件扩展名
    // 这里暂时返回默认的 .jpg 扩展名
    // 后续可以通过读取元数据文件来获取真实的文件扩展名
    return '.jpg';
  }
}
