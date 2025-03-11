import 'dart:io';
import 'dart:typed_data';

abstract class IStorage {
  // 目录操作
  Future<void> cleanupTempDirectory({Duration maxAge});
  Uint8List createMinimalPngBytes();
  Future<void> createPlaceholderImage(String path);

  // 基础文件操作
  Future<void> deleteFile(String path);
  Future<void> ensureDirectoryExists(String path);
  Future<void> ensureFileExists(String path);

  Future<bool> fileExists(String path);
  // 工具方法
  String generateUniqueFileName({String? prefix, required String extension});
  // 路径管理
  Future<String> getAppDataPath();

  Future<Directory> getTempDirectory();
  Future<String> saveTempFile(List<int> bytes);
  void validatePathSafety(String path);
}

/// 存储异常
class StorageException implements Exception {
  final String message;
  final String path;
  final dynamic originalError;

  StorageException(this.message, this.path, this.originalError);

  @override
  String toString() => 'StorageException: $message (path: $path)';
}
