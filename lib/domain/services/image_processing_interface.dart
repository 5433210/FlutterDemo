import 'dart:io';

abstract class IImageProcessing {
  /// 优化图片质量（通用）
  Future<File> optimize(File image, [int quality = 85]);

  /// 调整图片尺寸（通用）
  Future<File> resize(File image, {required int width, required int height});

  /// 旋转图片（通用）
  Future<File> rotate(File image, int angle, {bool preserveSize = false});
}
