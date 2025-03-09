import 'dart:typed_data';

/// 存储接口
abstract class StorageInterface {
  /// 复制文件
  Future<void> copyFile(String source, String target);

  /// 创建目录
  Future<void> createDirectory(String path);

  /// 删除目录
  Future<void> deleteDirectory(String path);

  /// 删除文件
  Future<void> deleteFile(String path);

  /// 目录是否存在
  Future<bool> directoryExists(String path);

  /// 关闭资源
  Future<void> dispose();

  /// 文件是否存在
  Future<bool> exists(String path);

  /// 获取文件修改时间
  Future<DateTime> getModifiedTime(String path);

  /// 获取文件大小
  Future<int> getSize(String path);

  /// 列出目录内容
  Future<List<String>> listDirectory(String path);

  /// 移动文件
  Future<void> moveFile(String source, String target);

  /// 读取文件内容
  Future<Uint8List> readBytes(String path);

  /// 重命名文件
  Future<void> renameFile(String path, String newName);

  /// 写入文件
  Future<void> writeBytes(String path, Uint8List bytes);
}
