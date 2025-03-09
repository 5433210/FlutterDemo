import 'dart:typed_data';

/// 图片处理器接口
abstract class ImageProcessor {
  /// 创建缩略图
  Future<Uint8List?> createThumbnail(
    String imagePath, {
    required int width,
    int? height,
  });

  /// 裁剪图片
  Future<Uint8List?> cropImage(
    String imagePath, {
    required int x,
    required int y,
    required int width,
    required int height,
  });

  /// 获取图片信息
  Future<Map<String, dynamic>?> getImageInfo(String imagePath);

  /// 加载图片
  Future<Uint8List?> loadImage(String path);

  /// 缩放图片
  Future<Uint8List?> resizeImage(
    String imagePath, {
    required int width,
    int? height,
  });

  /// 旋转图片
  Future<Uint8List?> rotateImage(String imagePath, int angle);

  /// 保存图片
  Future<bool> saveImage(Uint8List data, String path);
}
