import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../infrastructure/logging/logger.dart';
import './image_processor.dart';

/// 图片处理器实现
class ImageProcessorImpl implements ImageProcessor {
  final String _cachePath;

  ImageProcessorImpl({required String cachePath}) : _cachePath = cachePath;

  @override
  String get tempPath => path.join(_cachePath, 'temp');

  @override
  String get thumbnailCachePath => path.join(_cachePath, 'thumbnails');

  @override
  Future<void> cleanupTempFiles() async {
    try {
      final dir = Directory(tempPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e, stack) {
      AppLogger.error(
        '清理临时文件失败',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<File> createPlaceholder(int width, int height) async {
    try {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(200, 200, 200));

      final outPath = await _createTempFilePath('placeholder_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(image));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '创建占位图失败',
        error: e,
        stackTrace: stack,
        data: {'width': width, 'height': height},
      );
      rethrow;
    }
  }

  @override
  Future<File> createTempFile(String prefix) async {
    final filePath = await _createTempFilePath(prefix);
    return File(filePath);
  }

  @override
  Future<File> optimizeImage(File input) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final optimized = img.copyResize(
        image,
        width: image.width,
        height: image.height,
        interpolation: img.Interpolation.linear,
      );

      final outPath = await _createTempFilePath('optimized_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(optimized, quality: 85));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '优化图片失败',
        error: e,
        stackTrace: stack,
        data: {'input': input.path},
      );
      rethrow;
    }
  }

  @override
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // 计算保持宽高比的尺寸
      final aspectRatio = image.width / image.height;
      var targetWidth = maxWidth;
      var targetHeight = maxHeight;

      if (targetWidth / targetHeight > aspectRatio) {
        targetWidth = (targetHeight * aspectRatio).round();
      } else {
        targetHeight = (targetWidth / aspectRatio).round();
      }

      final processed = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      final outPath = await _createTempFilePath('processed_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(processed, quality: quality));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '处理图片失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
          'quality': quality,
        },
      );
      rethrow;
    }
  }

  @override
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // 计算保持宽高比的尺寸
      final aspectRatio = image.width / image.height;
      var targetWidth = width;
      var targetHeight = height;

      if (targetWidth / targetHeight > aspectRatio) {
        targetWidth = (targetHeight * aspectRatio).round();
      } else {
        targetHeight = (targetWidth / aspectRatio).round();
      }

      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      final outPath = await _createTempFilePath('resized_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(resized));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '调整图片大小失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'width': width,
          'height': height,
        },
      );
      rethrow;
    }
  }

  @override
  Future<File> rotateImage(File input, int degrees) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final rotated = img.copyRotate(image, angle: degrees);

      final outPath = await _createTempFilePath('rotated_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(rotated));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '旋转图片失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'degrees': degrees,
        },
      );
      rethrow;
    }
  }

  /// 创建临时文件路径
  Future<String> _createTempFilePath(String prefix) async {
    final dir = Directory(tempPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path.join(
      tempPath,
      '$prefix${DateTime.now().millisecondsSinceEpoch}.tmp',
    );
  }
}
