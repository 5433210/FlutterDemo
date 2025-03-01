import 'dart:io';

import '../../../domain/value_objects/image/work_image_info.dart';

/// 处理作品图片的服务接口
abstract class WorkImageService {
  /// 添加图片到作品
  Future<WorkImageInfo> addImageToWork(String workId, File file, int position);

  /// 清理临时图片
  Future<void> cleanupTempImages({int maxAgeInHours});

  /// 创建临时图片文件
  Future<File> createTempImageFile(String originalPath,
      {String? prefix, String? suffix});

  /// 将临时图片移动到永久存储
  Future<String> moveToPermStorage(
      File tempFile, String workId, int imageIndex);

  /// 处理作品图片（创建缩略图等）
  Future<void> processWorkImage(String workId, File file, int index);

  /// 旋转图片
  Future<File> rotateImage(File file, int angle);
}
