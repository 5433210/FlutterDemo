import 'dart:io';

/// 存储接口
abstract class IStorage {
  /// 复制文件
  Future<void> copyFile(String sourcePath, String destinationPath);

  /// 创建目录
  Future<Directory> createDirectory(String path);

  /// 获取临时目录
  Future<Directory> createTempDirectory();

  /// 删除目录
  Future<void> deleteDirectory(String path);

  /// 删除文件
  Future<void> deleteFile(String path);

  /// 检查目录是否存在
  Future<bool> directoryExists(String path);

  /// 确保目录存在
  Future<void> ensureDirectoryExists(String path);

  /// 检查文件是否存在
  Future<bool> fileExists(String path);

  /// 获取应用缓存目录路径
  String getAppCachePath();

  /// 获取应用数据目录路径
  String getAppDataPath();

  /// 获取应用临时目录路径
  String getAppTempPath();

  /// 获取文件修改时间
  Future<DateTime> getFileModifiedTime(String path);

  /// 获取文件大小
  Future<int> getFileSize(String path);

  /// 列出目录中的所有文件路径（递归）
  Future<List<String>> listDirectoryFiles(String path);

  /// 移动文件
  Future<void> moveFile(String sourcePath, String destinationPath);

  /// 读取文件内容
  Future<List<int>> readFile(String path);

  /// 重命名文件
  Future<void> renameFile(String oldPath, String newPath);

  /// 保存临时文件
  Future<String> saveTempFile(String sourcePath);

  /// 写入文件内容
  Future<void> writeFile(String path, List<int> bytes);
}

/// 存储接口异常
class StorageException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  StorageException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'StorageException: $message';
}
