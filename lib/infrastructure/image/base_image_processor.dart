import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/services/image_processing_interface.dart';
import '../../infrastructure/logging/logger.dart';

class BaseImageProcessor implements IImageProcessing {
  final _uuid = const Uuid();

  @override
  Future<File> optimize(File image, [int quality = 85]) async {
    try {
      final bytes = await image.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('无法解码图片');

      // 创建输出文件
      final dir = path.dirname(image.path);
      final extension = path.extension(image.path).toLowerCase();
      final fileName = '${_uuid.v4()}_optimized$extension';
      final outputPath = path.join(dir, fileName);

      final outputBytes = extension == '.jpg' || extension == '.jpeg'
          ? img.encodeJpg(decoded, quality: quality)
          : img.encodePng(decoded);

      await File(outputPath).writeAsBytes(outputBytes);
      return File(outputPath);
    } catch (e, stack) {
      AppLogger.error('优化图片失败',
          tag: 'BaseImageProcessor',
          error: e,
          stackTrace: stack,
          data: {'path': image.path});
      rethrow;
    }
  }

  @override
  Future<File> resize(File image,
      {required int width, required int height}) async {
    try {
      final bytes = await image.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('无法解码图片');

      final resized = img.copyResize(
        decoded,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      // 创建输出文件
      final dir = path.dirname(image.path);
      final extension = path.extension(image.path).toLowerCase();
      final fileName = '${_uuid.v4()}_resized$extension';
      final outputPath = path.join(dir, fileName);

      final outputBytes = extension == '.jpg' || extension == '.jpeg'
          ? img.encodeJpg(resized, quality: 90)
          : img.encodePng(resized);

      await File(outputPath).writeAsBytes(outputBytes);
      return File(outputPath);
    } catch (e, stack) {
      AppLogger.error('调整图片尺寸失败',
          tag: 'BaseImageProcessor',
          error: e,
          stackTrace: stack,
          data: {'path': image.path, 'width': width, 'height': height});
      rethrow;
    }
  }

  @override
  Future<File> rotate(File image, int angle,
      {bool preserveSize = false}) async {
    try {
      final bytes = await image.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('无法解码图片');

      // 标准化角度 (0-359)
      final normalizedAngle = angle % 360;
      if (normalizedAngle == 0) {
        return image;
      }

      img.Image rotated;
      if (normalizedAngle == 90 || normalizedAngle == 270) {
        // 对于90度和270度，宽高会交换
        rotated = img.copyRotate(decoded, angle: normalizedAngle);
      } else if (normalizedAngle == 180) {
        // 180度不会改变尺寸
        rotated = img.copyRotate(decoded, angle: normalizedAngle);
      } else {
        // 对于其他角度，根据preserveSize决定处理方式
        if (preserveSize) {
          // 创建一个与原图同尺寸的空白图像
          rotated = img.Image(
            width: decoded.width,
            height: decoded.height,
            numChannels: decoded.numChannels,
          );

          // 旋转并填充
          img.compositeImage(
            rotated,
            img.copyRotate(decoded, angle: normalizedAngle),
            dstX: (decoded.width - rotated.width) ~/ 2,
            dstY: (decoded.height - rotated.height) ~/ 2,
          );
        } else {
          // 如果不需要保持尺寸，直接旋转
          rotated = img.copyRotate(decoded, angle: normalizedAngle);
        }
      }

      // 创建输出文件
      final dir = path.dirname(image.path);
      final extension = path.extension(image.path).toLowerCase();
      final fileName = '${_uuid.v4()}_rotated$extension';
      final outputPath = path.join(dir, fileName);

      final outputBytes = extension == '.jpg' || extension == '.jpeg'
          ? img.encodeJpg(rotated, quality: 90)
          : img.encodePng(rotated);

      await File(outputPath).writeAsBytes(outputBytes);
      return File(outputPath);
    } catch (e, stack) {
      AppLogger.error('旋转图片失败',
          tag: 'BaseImageProcessor',
          error: e,
          stackTrace: stack,
          data: {'path': image.path, 'angle': angle});
      rethrow;
    }
  }
}
