import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/models/image/work_image_info.dart';
import '../../domain/models/image/work_image_size.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/path_helper.dart';
import '../config/app_config.dart';

class ImageDimension {
  final int width;
  final int height;

  ImageDimension({required this.width, required this.height});
}

class ImageService {
  static const String _tempImageDir = 'temp_images';

  static const String _backupImageDir = 'backup_images';
  ImageService();
  Future<void> backupOriginal(File file) async {
    try {
      AppLogger.info('备份原始图片文件',
          tag: 'ImageService', data: {'path': file.path});

      final appDir = await PathHelper.getAppDataPath();
      final backupDirPath = path.join(appDir, _backupImageDir);
      final backupDir = Directory(backupDirPath);

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = path.basename(file.path);
      final backupPath = path.join(backupDir.path, '${timestamp}_$filename');

      await file.copy(backupPath);

      AppLogger.info('原始图片备份成功',
          tag: 'ImageService',
          data: {'originalPath': file.path, 'backupPath': backupPath});
    } catch (e, stack) {
      AppLogger.error('备份原始图片失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'path': file.path});
    }
  }

  Future<void> cleanupTempImages({int maxAgeInHours = 24}) async {
    try {
      AppLogger.info('开始清理临时图片文件',
          tag: 'ImageService', data: {'maxAgeInHours': maxAgeInHours});

      // 获取临时目录
      final tempDir = await _getTempImageDir();
      if (!await tempDir.exists()) {
        AppLogger.debug('临时目录不存在，无需清理', tag: 'ImageService');
        return;
      }

      final cutoffTime = DateTime.now()
          .subtract(Duration(hours: maxAgeInHours))
          .millisecondsSinceEpoch;

      int removedCount = 0;
      int failedCount = 0;

      // 列出所有文件
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          try {
            final stats = await entity.stat();
            if (stats.modified.millisecondsSinceEpoch < cutoffTime) {
              await entity.delete();
              removedCount++;
            }
          } catch (e) {
            failedCount++;
            AppLogger.warning('删除临时文件失败',
                tag: 'ImageService', error: e, data: {'path': entity.path});
          }
        }
      }

      AppLogger.info('清理临时图片文件完成',
          tag: 'ImageService',
          data: {'removedCount': removedCount, 'failedCount': failedCount});
    } catch (e, stack) {
      AppLogger.error('清理临时图片文件失败',
          tag: 'ImageService', error: e, stackTrace: stack);
    }
  }

  Future<File> createTempFileFromBytes(
      List<int> bytes, String extension) async {
    try {
      // 计算字节数据的哈希值
      final hash = crypto.md5.convert(bytes).toString().substring(0, 8);

      // 获取临时文件路径
      final tempDir = await _getTempImageDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          path.join(tempDir.path, 'temp_${timestamp}_$hash.$extension');

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return file;
    } catch (e, stack) {
      AppLogger.error('创建临时文件失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'extension': extension});
      rethrow;
    }
  }

  Future<File> createTempThumbnail(File imageFile,
      {int width = 120, int height = 120}) async {
    try {
      // 创建一个临时文件
      final thumbnailPath = await getTemporaryFilePath(imageFile.path,
          suffix: 'thumbnail', extension: '.png');
      final thumbnailFile = File(thumbnailPath);

      // 读取原始图片并调整大小
      final img = await decodeImageFromList(await imageFile.readAsBytes());
      final thumbnail = await _resizeImage(img, width, height);

      // 将缩略图写入文件
      await thumbnailFile.writeAsBytes(thumbnail);
      return thumbnailFile;
    } catch (e, stack) {
      AppLogger.error('创建缩略图失败',
          tag: 'ImageService', error: e, stackTrace: stack);
      throw Exception('创建缩略图失败: $e');
    }
  }

  /// Gets the dimensions of an image file
  Future<ImageDimension> getImageDimensions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return ImageDimension(width: image.width, height: image.height);
  }

  Future<String> getTemporaryFilePath(
    String originalPath, {
    String? suffix,
    String? extension,
  }) async {
    try {
      // 获取临时目录
      final tempDir = await _getTempImageDir();

      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = const Uuid().v4().substring(0, 8);
      final fileExtension = extension ?? path.extension(originalPath);
      final baseName = path.basenameWithoutExtension(originalPath);

      // 构建文件名
      String fileName = '${baseName}_${timestamp}_$randomId';
      if (suffix != null && suffix.isNotEmpty) {
        fileName += '_$suffix';
      }
      fileName += fileExtension;

      final filePath = path.join(tempDir.path, fileName);

      // 确保目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(filePath));

      return filePath;
    } catch (e, stack) {
      AppLogger.error('生成临时文件路径失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'originalPath': originalPath});
      rethrow;
    }
  }

  Future<String> moveToPermStorage(File tempFile, String workId, int imageIndex,
      {bool isThumbnail = false}) async {
    try {
      AppLogger.debug('移动临时文件到永久位置', tag: 'ImageService', data: {
        'tempPath': tempFile.path,
        'workId': workId,
        'imageIndex': imageIndex,
        'isThumbnail': isThumbnail
      });

      // 确定目标路径
      String? destPath;
      if (isThumbnail) {
        destPath = await PathHelper.getWorkThumbnailPath(workId, imageIndex);
      } else {
        destPath = await PathHelper.getWorkImagePath(workId, imageIndex);
      }

      if (destPath == null) {
        throw Exception('无法获取目标路径');
      }

      // 确保目标目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(destPath));

      // 复制文件
      final destFile = File(destPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }
      await tempFile.copy(destPath);

      // 删除临时文件（可选）
      try {
        await tempFile.delete();
      } catch (e) {
        AppLogger.warning('删除临时文件失败',
            tag: 'ImageService', error: e, data: {'path': tempFile.path});
      }

      AppLogger.debug('文件移动成功',
          tag: 'ImageService', data: {'from': tempFile.path, 'to': destPath});

      return destPath;
    } catch (e, stack) {
      AppLogger.error('移动文件失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {
            'tempPath': tempFile.path,
            'workId': workId,
            'imageIndex': imageIndex
          });
      rethrow;
    }
  }

  Future<File> optimizeImage(
    File file, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片');

    // Calculate new dimensions maintaining aspect ratio
    double ratio = image.width / image.height;
    int newWidth = image.width;
    int newHeight = image.height;

    if (newWidth > maxWidth) {
      newWidth = maxWidth;
      newHeight = (newWidth / ratio).round();
    }

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (newHeight * ratio).round();
    }

    // Resize if needed
    if (newWidth != image.width || newHeight != image.height) {
      image = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Create optimized file
    final dir = path.dirname(file.path);
    final ext = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final optimizedPath = path.join(dir, 'optimized_$timestamp$ext');

    // Save optimized image
    final optimizedFile = File(optimizedPath);
    await optimizedFile.writeAsBytes(img.encodeJpg(image, quality: quality));

    return optimizedFile;
  }

  Future<List<WorkImageInfo>> processWorkImages(
      String workId, List<File> images) async {
    try {
      AppLogger.info('开始处理作品图片',
          tag: 'ImageService',
          data: {'workId': workId, 'imageCount': images.length});

      await PathHelper.ensureWorkDirectoryExists(workId);
      final processedImages = <WorkImageInfo>[];

      for (var i = 0; i < images.length; i++) {
        final file = images[i];
        AppLogger.debug('处理图片 ${i + 1}/${images.length}',
            tag: 'ImageService',
            data: {'workId': workId, 'filePath': file.path});

        // 检查文件
        try {
          final fileSize = await file.length();
          if (fileSize == 0) {
            AppLogger.warning('图片文件为空',
                tag: 'ImageService',
                data: {'workId': workId, 'filePath': file.path});
            continue;
          }
        } catch (e) {
          AppLogger.error('检查图片文件失败',
              tag: 'ImageService',
              error: e,
              data: {'workId': workId, 'filePath': file.path});
          continue;
        }

        final bytes = await file.readAsBytes();

        AppLogger.debug('读取图片字节', tag: 'ImageService', data: {
          'workId': workId,
          'filePath': file.path,
          'fileSize': bytes.length
        });

        final image = img.decodeImage(bytes);

        if (image == null) {
          AppLogger.error('无法解码图片',
              tag: 'ImageService',
              data: {'workId': workId, 'filePath': file.path});
          throw Exception('无法解码图片：${path.basename(file.path)}');
        }

        AppLogger.debug('图片解码成功', tag: 'ImageService', data: {
          'workId': workId,
          'filePath': file.path,
          'width': image.width,
          'height': image.height,
          'format': path.extension(file.path)
        });

        // 确保所有相关目录存在
        final pictureDirPath =
            path.dirname(await PathHelper.getWorkImagePath(workId, i) ?? '');
        await PathHelper.ensureDirectoryExists(pictureDirPath);

        AppLogger.debug('创建图片目录',
            tag: 'ImageService',
            data: {'workId': workId, 'picturePath': pictureDirPath});

        // 保存原始图片 - 使用copyFile而不是直接copy
        String? originalPath = await PathHelper.getOriginalWorkPath(
            workId, i, path.extension(file.path));

        AppLogger.debug('复制原始图片', tag: 'ImageService', data: {
          'workId': workId,
          'sourceFile': file.path,
          'targetPath': originalPath
        });

        await _safelyCopyFile(file, originalPath);

        // 处理图片并保存
        AppLogger.debug('处理图片',
            tag: 'ImageService', data: {'workId': workId, 'index': i});

        final processed = _processImage(image);

        AppLogger.debug('处理完成', tag: 'ImageService', data: {
          'workId': workId,
          'index': i,
          'originalSize': '${image.width}x${image.height}',
          'processedSize': '${processed.width}x${processed.height}'
        });

        final importedPath = await PathHelper.getWorkImagePath(workId, i);

        AppLogger.debug('保存处理后的图片',
            tag: 'ImageService',
            data: {'workId': workId, 'index': i, 'path': importedPath});

        final pngBytes = img.encodePng(processed);
        await _safelyWriteBytes(importedPath!, pngBytes);

        // 创建缩略图
        AppLogger.debug('创建缩略图',
            tag: 'ImageService', data: {'workId': workId, 'index': i});

        final thumbnail = _createThumbnail(processed);

        AppLogger.debug('缩略图创建成功', tag: 'ImageService', data: {
          'workId': workId,
          'index': i,
          'size': '${thumbnail.width}x${thumbnail.height}'
        });

        final thumbnailPath = await PathHelper.getWorkThumbnailPath(workId, i);

        AppLogger.debug('保存缩略图',
            tag: 'ImageService',
            data: {'workId': workId, 'index': i, 'path': thumbnailPath});

        final jpgBytes = img.encodeJpg(thumbnail, quality: 80);
        await _safelyWriteBytes(thumbnailPath!, jpgBytes);

        // 添加图片信息到结果列表
        processedImages.add(WorkImageInfo(
            fileSize: bytes.length,
            format: path.extension(file.path).replaceAll('.', ''),
            path: importedPath,
            size:
                WorkImageSize(width: processed.width, height: processed.height),
            thumbnail: thumbnailPath,
            original: originalPath));

        AppLogger.debug('图片 ${i + 1}/${images.length} 处理完成',
            tag: 'ImageService',
            data: {
              'workId': workId,
              'format': path.extension(file.path).replaceAll('.', ''),
              'size': '${processed.width}x${processed.height}',
              'fileSize': bytes.length
            });
      }

      // 创建作品封面缩略图
      if (processedImages.isNotEmpty) {
        await _createCoverThumbnail(workId, processedImages);
      }

      AppLogger.info('作品图片处理完成', tag: 'ImageService', data: {
        'workId': workId,
        'processedCount': processedImages.length,
        'totalOriginalCount': images.length
      });

      return processedImages;
    } catch (e, stack) {
      AppLogger.error('处理作品图片失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }

  Future<File> rotateImage(File file, int angle,
      {bool preserveSize = false}) async {
    try {
      AppLogger.debug('开始旋转图片',
          tag: 'ImageService', data: {'path': file.path, 'angle': angle});

      // 读取图片
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('无法解码图片: ${file.path}');
      }

      // 使用标准化角度 (0-359)
      final normalizedAngle = angle % 360;
      if (normalizedAngle == 0) {
        // 无需旋转
        return file;
      }

      // 执行旋转，根据不同角度处理
      img.Image rotated;
      if (normalizedAngle == 90 || normalizedAngle == 270) {
        // 对于90度和270度，宽高会交换
        rotated = img.copyRotate(image, angle: normalizedAngle);
      } else if (normalizedAngle == 180) {
        // 180度不会改变尺寸
        rotated = img.copyRotate(image, angle: normalizedAngle);
      } else {
        // 对于其他角度，如果需要保持尺寸，则使用填充背景的方式
        if (preserveSize) {
          // 创建一个与原图同尺寸的空白图像
          rotated = img.Image(
            width: image.width,
            height: image.height,
            numChannels: image.numChannels,
          );

          // 计算旋转中心点
          final centerX = image.width / 2;
          final centerY = image.height / 2;

          // 旋转并填充
          img.compositeImage(
            rotated,
            img.copyRotate(image, angle: normalizedAngle),
            dstX: (image.width - rotated.width) ~/ 2,
            dstY: (image.height - rotated.height) ~/ 2,
          );
        } else {
          // 如果不需要保持尺寸，直接旋转
          rotated = img.copyRotate(image, angle: normalizedAngle);
        }
      }

      // 创建输出文件（使用临时文件目录）
      final outputFile = await _createTempImageFile(
        originalPath: file.path,
        suffix: 'rotated_$normalizedAngle',
      );

      // 根据原始文件格式编码输出
      List<int> outputBytes;
      final extension = path.extension(file.path).toLowerCase();
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          outputBytes = img.encodeJpg(rotated, quality: 90);
          break;
        case '.png':
          outputBytes = img.encodePng(rotated);
          break;
        case '.gif':
          outputBytes = img.encodeGif(rotated);
          break;
        case '.bmp':
          outputBytes = img.encodeBmp(rotated);
          break;
        default:
          // 默认使用 PNG 格式
          outputBytes = img.encodePng(rotated);
      }

      // 写入文件
      await outputFile.writeAsBytes(outputBytes);

      AppLogger.debug('图片旋转成功', tag: 'ImageService', data: {
        'originalPath': file.path,
        'outputPath': outputFile.path,
        'originalSize': '${image.width}x${image.height}',
        'rotatedSize': '${rotated.width}x${rotated.height}',
      });

      return outputFile;
    } catch (e, stack) {
      AppLogger.error('图片旋转失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'path': file.path, 'angle': angle});
      rethrow;
    }
  }

  Future<void> _createCoverThumbnail(
      String workId, List<WorkImageInfo> images) async {
    final workThumbnailPath =
        await PathHelper.getWorkCoverThumbnailPath(workId);
    AppLogger.debug('创建作品缩略图',
        tag: 'ImageService',
        data: {'workId': workId, 'path': workThumbnailPath});

    try {
      final firstImageFile = File(images[0].path);

      if (!await firstImageFile.exists()) {
        AppLogger.warning('封面源图片不存在，无法创建封面缩略图',
            tag: 'ImageService',
            data: {'workId': workId, 'imagePath': images[0].path});
        return;
      }

      final firstImageBytes = await firstImageFile.readAsBytes();
      final firstImage = img.decodeImage(firstImageBytes);

      if (firstImage != null) {
        final workThumbnail = _createThumbnail(firstImage);

        AppLogger.debug('作品缩略图创建成功', tag: 'ImageService', data: {
          'workId': workId,
          'size': '${workThumbnail.width}x${workThumbnail.height}'
        });

        // 确保缩略图目录存在
        await PathHelper.ensureDirectoryExists(path.dirname(workThumbnailPath));

        final thumbnailBytes = img.encodeJpg(workThumbnail, quality: 85);
        await _safelyWriteBytes(workThumbnailPath, thumbnailBytes);

        AppLogger.debug('作品缩略图保存成功', tag: 'ImageService', data: {
          'workId': workId,
          'path': workThumbnailPath,
          'size': thumbnailBytes.length
        });
      }
    } catch (e, stack) {
      AppLogger.error('创建作品缩略图失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      // 继续执行，即使缩略图创建失败
    }
  }

  Future<File> _createTempImageFile({
    required String originalPath,
    String prefix = 'temp_',
    String suffix = '',
  }) async {
    try {
      // 获取临时目录
      final tempDir = await _getTempImageDir();

      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = const Uuid().v4().substring(0, 8);
      final extension = path.extension(originalPath);

      // 构建文件名: prefix_timestamp_randomId_suffix.ext
      String fileName = '$prefix$timestamp';
      if (suffix.isNotEmpty) fileName += '_$suffix';
      fileName += '_$randomId$extension';

      final filePath = path.join(tempDir.path, fileName);

      // 确保目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(filePath));

      // 创建并返回文件
      return File(filePath);
    } catch (e, stack) {
      AppLogger.error('创建临时图片文件失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'originalPath': originalPath});
      rethrow;
    }
  }

  img.Image _createThumbnail(img.Image image) {
    final aspectRatio = image.width / image.height;
    int thumbWidth = AppConfig.thumbnailSize;
    int thumbHeight = AppConfig.thumbnailSize;

    if (aspectRatio > 1) {
      thumbHeight = (AppConfig.thumbnailSize / aspectRatio).round();
    } else {
      thumbWidth = (AppConfig.thumbnailSize * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: thumbWidth,
      height: thumbHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  Future<Directory> _getTempImageDir() async {
    final appDir = await PathHelper.getAppDataPath();
    final tempDirPath = path.join(appDir, _tempImageDir);
    final tempDir = Directory(tempDirPath);

    // 确保目录存在
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return tempDir;
  }

  img.Image _processImage(img.Image image) {
    // Resize if needed
    if (image.width > AppConfig.maxImageWidth ||
        image.height > AppConfig.maxImageHeight) {
      final aspectRatio = image.width / image.height;
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > AppConfig.maxImageWidth) {
        newWidth = AppConfig.maxImageWidth;
        newHeight = (AppConfig.maxImageWidth / aspectRatio).round();
      }

      if (newHeight > AppConfig.maxImageHeight) {
        newHeight = AppConfig.maxImageHeight;
        newWidth = (AppConfig.maxImageHeight * aspectRatio).round();
      }

      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    return image;
  }

  Future<Uint8List> _resizeImage(
      ui.Image image, int targetWidth, int targetHeight) async {
    // 计算调整后的尺寸，保持原始宽高比
    final double aspectRatio = image.width / image.height;
    int width = targetWidth;
    int height = targetHeight;

    if (aspectRatio > 1) {
      // 宽度大于高度的图片
      height = (width / aspectRatio).round();
    } else {
      // 高度大于宽度的图片
      width = (height * aspectRatio).round();
    }

    // 创建一个画布并绘制调整大小后的图像
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image resized = await picture.toImage(width, height);
    final ByteData? byteData =
        await resized.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }

  Future<void> _safelyCopyFile(File source, String destinationPath) async {
    try {
      final destinationFile = File(destinationPath);

      // 如果目标文件已存在，先删除
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      // 确保目标目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(destinationPath));

      // 复制文件
      await source.copy(destinationPath);
    } catch (e, stack) {
      AppLogger.error('复制文件失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'source': source.path, 'destination': destinationPath});
      rethrow;
    }
  }

  Future<void> _safelyWriteBytes(String filePath, List<int> bytes) async {
    try {
      final file = File(filePath);

      // 如果文件已存在，先删除
      if (await file.exists()) {
        await file.delete();
      }

      // 确保父目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(filePath));

      // 写入文件
      await file.writeAsBytes(bytes);
    } catch (e, stack) {
      AppLogger.error('写入文件失败',
          tag: 'ImageService',
          error: e,
          stackTrace: stack,
          data: {'path': filePath, 'size': bytes.length});
      rethrow;
    }
  }
}
