import 'dart:io';
import 'storage_interface.dart';

/// 图库存储接口
abstract class ILibraryStorage extends IStorage {
  /// 获取图库根目录
  Future<Directory> getLibraryRoot();

  /// 获取图库项目目录
  Future<Directory> getLibraryItemDirectory(String itemId);

  /// 获取图库项目缩略图目录
  Future<Directory> getThumbnailDirectory(String itemId);

  /// 保存图库项目文件
  Future<String> saveLibraryItem(
      String itemId, List<int> bytes, String extension);

  /// 保存图库项目缩略图
  Future<String> saveThumbnail(String itemId, List<int> bytes);

  /// 获取图库项目文件路径
  Future<String> getLibraryItemPath(String itemId, String extension);

  /// 获取图库项目缩略图路径
  Future<String> getThumbnailPath(String itemId);

  /// 删除图库项目及其相关文件
  Future<void> deleteLibraryItem(String itemId);

  /// 获取图库项目文件信息
  Future<FileInfo> getLibraryItemInfo(String itemId, String extension);

  /// 获取图库项目缩略图信息
  Future<FileInfo> getThumbnailInfo(String itemId);
}

/// 文件信息
class FileInfo {
  final String path;
  final int size;
  final DateTime modifiedTime;
  final String mimeType;

  FileInfo({
    required this.path,
    required this.size,
    required this.modifiedTime,
    required this.mimeType,
  });
}
