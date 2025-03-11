import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../application/config/app_config.dart';
import '../../infrastructure/logging/logger.dart';
import 'storage_interface.dart';

class LocalStorageImpl implements IStorage {
  final String _appDataPath;

  /// 构造函数，注入应用数据存储路径
  LocalStorageImpl() : _appDataPath = AppConfig.dataPath;

  @override
  Future<void> cleanupTempDirectory(
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final tempDir = await getTempDirectory();
      final cutoff = DateTime.now().subtract(maxAge);

      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw StorageException('Failed to cleanup temp directory', '', e);
    }
  }

  @override
  Uint8List createMinimalPngBytes() {
    // 这是一个最小的有效PNG文件，1x1像素，红色
    return Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53,
      0xDE,
      0x00,
      0x00,
      0x00,
      0x0C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0xD7,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x03,
      0x01,
      0x01,
      0x00,
      0x18,
      0xDD,
      0x8D,
      0xB0,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82
    ]);
  }

  @override
  Future<void> createPlaceholderImage(String filePath) async {
    try {
      final file = File(filePath);

      // 如果文件已经存在就不做任何操作
      if (await file.exists()) {
        // 检查文件大小，如果为0则需要替换
        if (await file.length() == 0) {
          await file.delete();
        } else {
          return; // 文件存在且有效
        }
      }

      // 确保父目录存在
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 创建一个最小的有效PNG文件 (1x1像素)
      final pngData = createMinimalPngBytes();
      await file.writeAsBytes(pngData);

      AppLogger.debug('创建有效占位图成功',
          tag: 'LocalStorageImpl',
          data: {'path': filePath, 'size': pngData.length});
    } catch (e) {
      throw StorageException('Failed to create placeholder image', filePath, e);
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException('Failed to delete file', path, e);
    }
  }

  @override
  Future<void> ensureDirectoryExists(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        AppLogger.debug('目录创建成功',
            tag: 'LocalStorageImpl', data: {'path': directoryPath});
      }
    } catch (e) {
      // 特别处理目录已存在的情况
      if (e is FileSystemException && e.osError?.errorCode == 183) {
        // 183 表示 "当文件已存在时，无法创建该文件"
        // 这是正常的情况，目录可能在并发情况下被创建
        AppLogger.debug('目录已存在',
            tag: 'LocalStorageImpl', data: {'path': directoryPath});
        return;
      }

      throw StorageException(
          'Failed to ensure directory exists', directoryPath, e);
    }
  }

  @override
  Future<void> ensureFileExists(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // 确保父目录存在
        final parentDir = path.dirname(filePath);
        await ensureDirectoryExists(parentDir);

        try {
          // 创建空文件
          await file.create();
          AppLogger.debug('文件创建成功',
              tag: 'LocalStorageImpl', data: {'path': filePath});
        } catch (e) {
          // 检查文件是否已经被创建（可能是并发请求导致）
          if (await file.exists()) {
            AppLogger.debug('文件已存在',
                tag: 'LocalStorageImpl', data: {'path': filePath});
            return;
          }
          rethrow;
        }
      }
    } catch (e) {
      throw StorageException('Failed to ensure file exists', filePath, e);
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      throw StorageException('Failed to check file exists', path, e);
    }
  }

  @override
  String generateUniqueFileName({String? prefix, required String extension}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid().v4().substring(0, 8);
    return '${prefix ?? 'file'}_${timestamp}_$uuid.$extension';
  }

  @override
  Future<String> getAppDataPath() async {
    try {
      return _appDataPath;
    } catch (e) {
      throw StorageException('Failed to get app data path', _appDataPath, e);
    }
  }

  @override
  Future<Directory> getTempDirectory() async {
    try {
      final tempDir = Directory(path.join(_appDataPath, 'temp'));
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      return tempDir;
    } catch (e) {
      throw StorageException(
          'Failed to get temp directory', path.join(_appDataPath, 'temp'), e);
    }
  }

  @override
  Future<String> saveTempFile(List<int> bytes) async {
    try {
      final tempDir = await getTempDirectory();
      final tempFile = File(path.join(
          tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}'));
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } catch (e) {
      throw StorageException('Failed to save temp file', '', e);
    }
  }

  @override
  void validatePathSafety(String filePath) {
    if (filePath.contains('..')) {
      throw StorageException('Path contains illegal sequence', filePath, null);
    }
  }
}
