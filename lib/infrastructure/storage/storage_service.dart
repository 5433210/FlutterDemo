import 'dart:io';

import 'package:path/path.dart' as path;

import '../logging/logger.dart';
import 'storage_interface.dart';

/// 基础存储服务
///
/// 职责:
/// 1. 基础文件系统操作
/// 2. 文件和目录管理
/// 3. 路径生成和验证
/// 4. 基础错误处理
class StorageService implements IStorage {
  final String _basePath;

  StorageService({
    required String basePath,
  }) : _basePath = basePath;

  /// 获取应用数据根目录
  String get appDataPath => _basePath;

  /// 复制文件
  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    try {
      _validatePath(targetPath);
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('源文件不存在', sourcePath);
      }

      // 确保目标目录存在
      final targetDir = path.dirname(targetPath);
      await createDirectory(targetDir).then((dir) => null);

      await sourceFile.copy(targetPath);
    } catch (e, stack) {
      _handleError(
        '复制文件失败',
        e,
        stack,
        data: {
          'source': sourcePath,
          'target': targetPath,
        },
      );
    }
  }

  /// 创建目录
  @override
  Future<Directory> createDirectory(String dirPath) async {
    try {
      _validatePath(dirPath);
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return dir;
      }
      return dir;
    } catch (e, stack) {
      _handleError(
        '创建目录失败',
        e,
        stack,
        data: {'path': dirPath},
      );
      rethrow;
    }
  }

  /// 删除目录
  @override
  Future<void> deleteDirectory(String dirPath, {bool recursive = true}) async {
    try {
      _validatePath(dirPath);
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: recursive);
      }
    } catch (e, stack) {
      _handleError(
        '删除目录失败',
        e,
        stack,
        data: {'path': dirPath},
      );
    }
  }

  /// 删除文件
  @override
  Future<void> deleteFile(String filePath) async {
    try {
      _validatePath(filePath);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      _handleError(
        '删除文件失败',
        e,
        stack,
        data: {'path': filePath},
      );
    }
  }

  /// 检查目录是否存在
  @override
  Future<bool> directoryExists(String dirPath) async {
    _validatePath(dirPath);
    return Directory(dirPath).exists();
  }

  /// 确保目录存在
  @override
  Future<void> ensureDirectoryExists(String dirPath) async {
    try {
      _validatePath(dirPath);
      await Directory(dirPath).create(recursive: true);
    } catch (e, stack) {
      _handleError(
        '确保目录存在失败',
        e,
        stack,
        data: {'path': dirPath},
      );
    }
  }

  /// 检查文件是否存在
  @override
  Future<bool> fileExists(String filePath) async {
    _validatePath(filePath);
    return File(filePath).exists();
  }

  /// 获取应用数据目录路径
  @override
  Future<String> getAppDataPath() async {
    return _basePath;
  }

  /// 获取文件修改时间
  @override
  Future<DateTime> getFileModifiedTime(String filePath) async {
    try {
      _validatePath(filePath);
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
      }
      return await file.lastModified();
    } catch (e, stack) {
      _handleError(
        '获取文件修改时间失败',
        e,
        stack,
        data: {'path': filePath},
      );
      rethrow;
    }
  }

  /// 获取文件大小
  @override
  Future<int> getFileSize(String filePath) async {
    try {
      _validatePath(filePath);
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
      }
      return await file.length();
    } catch (e, stack) {
      _handleError(
        '获取文件大小失败',
        e,
        stack,
        data: {'path': filePath},
      );
      rethrow;
    }
  }

  /// 获取临时目录
  @override
  Future<Directory> getTempDirectory() async {
    try {
      final tempDir = await Directory.systemTemp.createTemp('app_');
      return tempDir;
    } catch (e, stack) {
      _handleError('获取临时目录失败', e, stack);
      rethrow;
    }
  }

  /// 验证路径是否在应用目录内
  bool isPathValid(String targetPath) {
    final normalized = path.normalize(targetPath);
    return normalized.startsWith(_basePath);
  }

  /// 移动文件
  @override
  Future<void> moveFile(String sourcePath, String targetPath) async {
    try {
      _validatePath(targetPath);
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('源文件不存在', sourcePath);
      }

      // 确保目标目录存在
      final targetDir = path.dirname(targetPath);
      await createDirectory(targetDir).then((dir) => null);

      await sourceFile.rename(targetPath);
    } catch (e, stack) {
      _handleError(
        '移动文件失败',
        e,
        stack,
        data: {
          'source': sourcePath,
          'target': targetPath,
        },
      );
    }
  }

  /// 规范化路径
  String normalizePath(String relativePath) =>
      path.join(_basePath, relativePath);

  /// 读取文件
  @override
  Future<List<int>> readFile(String filePath) async {
    try {
      _validatePath(filePath);
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
      }
      return await file.readAsBytes();
    } catch (e, stack) {
      _handleError(
        '读取文件失败',
        e,
        stack,
        data: {'path': filePath},
      );
      rethrow;
    }
  }

  /// 重命名文件
  @override
  Future<void> renameFile(String oldPath, String newPath) async {
    try {
      _validatePath(oldPath);
      _validatePath(newPath);

      final file = File(oldPath);
      if (!await file.exists()) {
        throw FileSystemException('源文件不存在', oldPath);
      }

      await file.rename(newPath);
    } catch (e, stack) {
      _handleError(
        '重命名文件失败',
        e,
        stack,
        data: {
          'oldPath': oldPath,
          'newPath': newPath,
        },
      );
    }
  }

  /// 保存临时文件
  @override
  Future<String> saveTempFile(String sourcePath) async {
    try {
      final tempDir = await getTempDirectory();
      final fileName = path.basename(sourcePath);
      final tempPath = path.join(tempDir.path, fileName);
      await copyFile(sourcePath, tempPath);
      return tempPath;
    } catch (e, stack) {
      _handleError('保存临时文件失败', e, stack, data: {'sourcePath': sourcePath});
      rethrow;
    }
  }

  /// 写入文件
  @override
  Future<void> writeFile(String filePath, List<int> bytes) async {
    try {
      _validatePath(filePath);

      // 确保目标目录存在
      final dir = path.dirname(filePath);
      await createDirectory(dir).then((dir) => null);

      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } catch (e, stack) {
      _handleError(
        '写入文件失败',
        e,
        stack,
        data: {'path': filePath},
      );
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
      tag: 'StorageService',
      data: data,
    );
    throw error;
  }

  /// 检查路径是否有效
  void _validatePath(String targetPath) {
    if (!isPathValid(targetPath)) {
      throw ArgumentError.value(
        targetPath,
        'path',
        '路径必须在应用目录内',
      );
    }
  }
}
