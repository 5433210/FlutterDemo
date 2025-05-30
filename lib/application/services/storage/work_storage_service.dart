import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/storage/storage_interface.dart';

/// 作品存储服务
///
/// 职责:
/// 1. 作品文件目录管理
/// 2. 作品文件命名规则
/// 3. 文件版本管理
/// 4. 图片格式处理
class WorkStorageService {
  final IStorage _storage;

  WorkStorageService({
    required IStorage storage,
  }) : _storage = storage;

  /// 创建作品目录结构
  Future<void> createWorkDirectories(String workId) async {
    try {
      await _storage.createDirectory(getWorkPath(workId));
      await _storage.createDirectory(getWorkImagesPath(workId));
      await _storage.createDirectory(getWorkCoverPath(workId));
    } catch (e, stack) {
      _handleError(
        '创建作品目录失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }
  }

  /// 删除作品目录
  Future<void> deleteWorkDirectory(String workId) async {
    try {
      final workPath = getWorkPath(workId);
      await _storage.deleteDirectory(workPath);
    } catch (e, stack) {
      _handleError(
        '删除作品目录失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }
  }

  /// 删除作品图片
  Future<void> deleteWorkImage(String workId, String imageId) async {
    try {
      final imagePath = getWorkImagePath(workId, imageId);
      await _storage.deleteDirectory(imagePath);
    } catch (e, stack) {
      _handleError(
        '删除作品图片失败',
        e,
        stack,
        data: {
          'workId': workId,
          'imageId': imageId,
        },
      );
    }
  }

  Future<void> ensureWorkDirectoryExists(String workId) async {
    try {
      await _storage.ensureDirectoryExists(getWorkPath(workId));
      await _storage.ensureDirectoryExists(getWorkImagesPath(workId));
      await _storage.ensureDirectoryExists(getWorkCoverPath(workId));
    } catch (e, stack) {
      _handleError(
        '创建作品目录失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }
  }

  /// 获取作品导入图片路径
  String getImportedPath(String workId, String imageId) =>
      path.join(getWorkImagePath(workId, imageId), 'imported.png');

  /// 获取作品元数据文件路径
  String getMetadataPath(String workId) =>
      path.join(getWorkPath(workId), 'metadata.json');

  /// 获取作品原始图片路径
  String getOriginalPath(String workId, String imageId) => path.join(
      getWorkImagePath(workId, imageId), 'original.${_getExtension(imageId)}');

  /// 获取作品缩略图路径
  String getThumbnailPath(String workId, String imageId) =>
      path.join(getWorkImagePath(workId, imageId), 'thumbnail.jpg');

  /// 获取作品封面导入图路径
  String getWorkCoverImportedPath(String workId) =>
      path.join(getWorkCoverPath(workId), 'imported.png');

  /// 获取作品封面目录路径
  String getWorkCoverPath(String workId) =>
      path.join(getWorkPath(workId), 'cover');

  /// 获取作品封面缩略图路径
  String getWorkCoverThumbnailPath(String workId) =>
      path.join(getWorkCoverPath(workId), 'thumbnail.jpg');

  /// 获取作品图片
  Future<File> getWorkImage(String path) async {
    if (!await _storage.fileExists(path)) {
      throw FileSystemException('文件不存在', path);
    }
    return File(path);
  }

  /// 获取图片信息
  Future<Map<String, int>> getWorkImageInfo(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', path);
    }

    final dimensions = await _getImageDimensions(file);

    return {
      'size': await file.length(),
      'width': dimensions['width'] ?? 0,
      'height': dimensions['height'] ?? 0,
    };
  }

  /// 获取作品图片路径
  String getWorkImagePath(String workId, String imageId) =>
      path.join(getWorkImagesPath(workId), imageId);

  /// 获取图片大小
  Future<int> getWorkImageSize(String path) => _storage.getFileSize(path);

  /// 获取作品图片目录路径
  String getWorkImagesPath(String workId) =>
      path.join(getWorkPath(workId), 'images');

  /// 获取作品目录路径
  String getWorkPath(String workId) =>
      (path.join(_storage.getAppDataPath(), 'works', workId));

  /// 检查作品图片是否存在
  Future<bool> hasWorkImage(String path) => _storage.fileExists(path);

  /// 列出作品所有文件路径（递归）
  Future<List<String>> listWorkFiles(String workId) async {
    try {
      final workPath = getWorkPath(workId);
      return await _storage.listDirectoryFiles(workPath);
    } catch (e, stack) {
      _handleError(
        '获取作品文件列表失败',
        e,
        stack,
        data: {'workId': workId},
      );
      return [];
    }
  }

  /// 保存作品封面导入图
  Future<String> saveCoverImported(String workId, File file) async {
    final targetPath = getWorkCoverImportedPath(workId);
    try {
      await ensureWorkDirectoryExists(workId);

      // 确保目标目录存在
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 如果目标文件存在则先删除
      if (await _storage.fileExists(targetPath)) {
        await _storage.deleteFile(targetPath);
      }
      await _storage.copyFile(file.path, targetPath);

      // 验证文件是否成功保存
      if (!await _storage.fileExists(targetPath)) {
        AppLogger.error('封面导入图保存失败', tag: 'WorkStorageService', data: {
          'workId': workId,
          'sourcePath': file.path,
          'targetPath': targetPath
        });
        throw FileSystemException('封面导入图保存失败', targetPath);
      }

      return targetPath;
    } catch (e, stack) {
      _handleError(
        '保存封面导入图失败',
        e,
        stack,
        data: {
          'workId': workId,
          'sourcePath': file.path,
          'targetPath': targetPath
        },
      );
      rethrow;
    }
  }

  /// 保存作品封面缩略图
  Future<String> saveCoverThumbnail(String workId, File file) async {
    final targetPath = getWorkCoverThumbnailPath(workId);
    try {
      await ensureWorkDirectoryExists(workId);

      // 确保目标目录存在
      final targetDir = Directory(path.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 如果目标文件存在则先删除
      if (await _storage.fileExists(targetPath)) {
        await _storage.deleteFile(targetPath);
      }
      await _storage.copyFile(file.path, targetPath);

      // 验证文件是否成功保存
      if (!await _storage.fileExists(targetPath)) {
        AppLogger.error('封面缩略图保存失败', tag: 'WorkStorageService', data: {
          'workId': workId,
          'sourcePath': file.path,
          'targetPath': targetPath
        });
        throw FileSystemException('封面缩略图保存失败', targetPath);
      }

      return targetPath;
    } catch (e, stack) {
      _handleError(
        '保存封面缩略图失败',
        e,
        stack,
        data: {
          'workId': workId,
          'sourcePath': file.path,
          'targetPath': targetPath
        },
      );
      rethrow;
    }
  }

  /// 保存作品导入图片
  Future<String> saveImportedImage(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getImportedPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品元数据
  Future<void> saveMetadata(String workId, String content) async {
    final targetPath = getMetadataPath(workId);
    await _storage.writeFile(targetPath, content.codeUnits);
  }

  /// 保存作品原始图片
  Future<String> saveOriginalImage(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getOriginalPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品缩略图
  Future<String> saveThumbnail(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getThumbnailPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 检查作品图片是否存在（带重试机制）
  Future<bool> verifyWorkImageExists(String path, {int retries = 3}) async {
    bool exists = await _storage.fileExists(path);

    // If file doesn't exist, retry a few times with delays
    int attempt = 0;
    while (!exists && attempt < retries) {
      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      exists = await _storage.fileExists(path);
      attempt++;

      AppLogger.debug(
        'Retry checking file existence',
        tag: 'WorkStorageService',
        data: {
          'path': path,
          'attempt': attempt,
          'exists': exists,
        },
      );
    }

    // 如果文件存在，尝试读取以确保它完全写入
    if (exists) {
      try {
        final file = File(path);
        final randomAccessFile = await file.open(mode: FileMode.read);
        try {
          // 尝试读取几个字节以验证文件可访问
          await randomAccessFile.read(8);
        } finally {
          await randomAccessFile.close();
        }
      } catch (e) {
        AppLogger.warning(
          '文件存在但无法完全访问',
          tag: 'WorkStorageService',
          error: e,
          data: {'path': path},
        );
        exists = false; // 文件存在但不可访问，标记为不存在
      }
    }

    if (!exists) {
      AppLogger.warning(
        '文件不存在或不可访问',
        tag: 'WorkStorageService',
        data: {'path': path, 'afterRetries': retries},
      );
    }

    return exists;
  }

  /// 确认作品所有图片都存在
  Future<Map<String, bool>> verifyWorkImages(String workId) async {
    Map<String, bool> results = {};
    try {
      final workPath = getWorkPath(workId);
      final files = await _storage.listDirectoryFiles(workPath);

      for (final file in files) {
        results[file] = await _storage.fileExists(file);
      }

      // Check cover files specifically
      final coverPath = getWorkCoverImportedPath(workId);
      final coverThumbPath = getWorkCoverThumbnailPath(workId);

      results[coverPath] = await verifyWorkImageExists(coverPath);
      results[coverThumbPath] = await verifyWorkImageExists(coverThumbPath);

      // Log any missing files
      final missingFiles =
          results.entries.where((e) => !e.value).map((e) => e.key).toList();

      if (missingFiles.isNotEmpty) {
        AppLogger.warning(
          '作品存在丢失的文件',
          tag: 'WorkStorageService',
          data: {
            'workId': workId,
            'missingFiles': missingFiles,
          },
        );
      }
    } catch (e, stack) {
      _handleError(
        '验证作品图片失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }

    return results;
  }

  /// 获取文件扩展名
  String _getExtension(String imageId) {
    // 从图片ID或其他元数据获取扩展名
    return 'png';
  }

  /// 获取图片尺寸
  Future<Map<String, int>> _getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return _parseImageDimensions(bytes);
    } catch (e) {
      AppLogger.warning(
        '获取图片尺寸失败',
        tag: 'WorkStorageService',
        error: e,
        data: {'filePath': file.path},
      );
      return {'width': 0, 'height': 0};
    }
  }

  /// 统一错误处理
  void _handleError(
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    AppLogger.error(
      message,
      error: error,
      stackTrace: stack,
      tag: 'WorkStorageService',
      data: data,
    );
    throw error;
  }

  /// 解析GIF图片尺寸
  Map<String, int> _parseGifDimensions(Uint8List bytes) {
    if (bytes.length < 10) return {'width': 0, 'height': 0};

    final width = bytes[6] | (bytes[7] << 8);
    final height = bytes[8] | (bytes[9] << 8);

    return {'width': width, 'height': height};
  }

  /// 解析图片尺寸（支持PNG、JPEG、GIF、WebP）
  Map<String, int> _parseImageDimensions(Uint8List bytes) {
    if (bytes.length < 8) return {'width': 0, 'height': 0};

    // PNG格式检测
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return _parsePngDimensions(bytes);
    }

    // JPEG格式检测
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _parseJpegDimensions(bytes);
    }

    // GIF格式检测
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return _parseGifDimensions(bytes);
    }

    // WebP格式检测
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return _parseWebpDimensions(bytes);
    }

    return {'width': 0, 'height': 0};
  }

  /// 解析JPEG图片尺寸
  Map<String, int> _parseJpegDimensions(Uint8List bytes) {
    int i = 2;
    while (i < bytes.length - 8) {
      if (bytes[i] == 0xFF) {
        final marker = bytes[i + 1];
        if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
          final height = (bytes[i + 5] << 8) | bytes[i + 6];
          final width = (bytes[i + 7] << 8) | bytes[i + 8];
          return {'width': width, 'height': height};
        }
        final length = (bytes[i + 2] << 8) | bytes[i + 3];
        i += length + 2;
      } else {
        i++;
      }
    }
    return {'width': 0, 'height': 0};
  }

  /// 解析PNG图片尺寸
  Map<String, int> _parsePngDimensions(Uint8List bytes) {
    if (bytes.length < 24) return {'width': 0, 'height': 0};

    final width =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];

    return {'width': width, 'height': height};
  }

  /// 解析WebP图片尺寸
  Map<String, int> _parseWebpDimensions(Uint8List bytes) {
    if (bytes.length < 30) return {'width': 0, 'height': 0};

    // 检查是否为WebP格式
    if (bytes[8] != 0x57 ||
        bytes[9] != 0x45 ||
        bytes[10] != 0x42 ||
        bytes[11] != 0x50) {
      return {'width': 0, 'height': 0};
    }

    // VP8格式
    if (bytes[12] == 0x56 &&
        bytes[13] == 0x50 &&
        bytes[14] == 0x38 &&
        bytes[15] == 0x20) {
      if (bytes.length < 30) return {'width': 0, 'height': 0};
      final width = ((bytes[26] | (bytes[27] << 8)) & 0x3FFF);
      final height = ((bytes[28] | (bytes[29] << 8)) & 0x3FFF);
      return {'width': width, 'height': height};
    }

    return {'width': 0, 'height': 0};
  }
}
