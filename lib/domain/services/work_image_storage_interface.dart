import 'dart:io';

// 移除对 IStorage 的继承
abstract class IWorkImageStorage {
  /// 删除作品图片
  Future<void> deleteWorkImage(String workId, String imagePath);

  /// 确保作品目录结构存在
  Future<void> ensureWorkDirectoryExists(String workId);

  /// 获取作品封面缩略图路径
  Future<String> getWorkCoverThumbnailPath(String workId);

  /// 获取作品图片目录
  Future<String> getWorkImageDir(String workId, String imageId);

  /// 获取作品所有图片路径
  Future<List<String>> getWorkImages(String workId);

  /// 获取缩略图路径
  Future<String> getWorkImageThumbnailPath(String workId, String imageId);

  /// 获取导入图片路径
  Future<String> getWorkImportedImagePath(String workId, String imageId);

  /// 获取原始图片路径
  Future<String> getWorkOriginalImagePath(
      String workId, String imageId, String ext);

  /// 获取作品路径
  Future<String> getWorkPath(String workId);

  /// 保存作品图片
  Future<String> saveWorkImage(String workId, File image);

  /// 检查作品封面缩略图是否存在
  Future<bool> workCoverThumbnailExists(String workId);
}
