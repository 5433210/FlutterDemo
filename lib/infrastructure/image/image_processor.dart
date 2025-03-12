import 'dart:io';

/// 图片处理器接口
abstract class ImageProcessor {
  /// 临时文件目录
  String get tempPath;

  /// 缩略图缓存目录
  String get thumbnailCachePath;

  /// 清理临时文件
  Future<void> cleanupTempFiles();

  /// 创建占位图
  ///
  /// 创建指定尺寸的占位图
  Future<File> createPlaceholder(int width, int height);

  /// 创建临时文件
  Future<File> createTempFile(String prefix);

  /// 优化图片
  ///
  /// 优化图片质量和大小
  Future<File> optimizeImage(File input);

  /// 处理图片
  ///
  /// 按指定尺寸和质量处理图片
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  });

  /// 调整图片大小
  ///
  /// 按指定尺寸调整图片，保持宽高比
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  });

  /// 旋转图片
  ///
  /// [degrees] 旋转角度(90, 180, 270)
  Future<File> rotateImage(File input, int degrees);
}
