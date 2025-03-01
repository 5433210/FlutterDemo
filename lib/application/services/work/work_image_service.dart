import 'dart:io';

import '../../../domain/value_objects/image/work_image_info.dart';

/// 作品图片处理服务接口
abstract class WorkImageService {
  /// 添加图片到作品
  Future<WorkImageInfo> addImageToWork(
      String workId, File imageFile, int index);

  /// 获取图片缩略图路径
  Future<String?> getImageThumbnail(String workId, int imageIndex);

  /// 旋转图片
  Future<File> rotateImage(File file, int angle, {bool preserveSize = false});
}
