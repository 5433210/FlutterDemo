import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../domain/value_objects/image/work_image_info.dart';
import '../../domain/value_objects/image/work_image_size.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/path_helper.dart';
import '../config/app_config.dart';

class ImageService {
  ImageService();

  // Future<void> backupOriginal(File file) async {
  //   try {
  //     AppLogger.info('备份原始图片文件',
  //         tag: 'ImageService', data: {'path': file.path});

  //     final backupDir = PathHelper.getWorkPath()

  //     if (!await backupDir.exists()) {
  //       await backupDir.create(recursive: true);
  //     }

  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final filename = path.basename(file.path);
  //     final backupPath = path.join(backupDir.path, '${timestamp}_$filename');

  //     await file.copy(backupPath);

  //     AppLogger.info('原始图片备份成功',
  //         tag: 'ImageService',
  //         data: {'originalPath': file.path, 'backupPath': backupPath});
  //   } catch (e, stack) {
  //     AppLogger.error('备份原始图片失败',
  //         tag: 'ImageService',
  //         error: e,
  //         stackTrace: stack,
  //         data: {'path': file.path});
  //     rethrow;
  //   }
  // }

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

      PathHelper.ensureDirectoryExists(await PathHelper.getWorkPath(workId));

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

        // Create work picture directory
        final picturePath = await PathHelper.getWorkImagePath(workId, i);
        PathHelper.ensureDirectoryExists(picturePath!);
        AppLogger.debug('创建图片目录',
            tag: 'ImageService',
            data: {'workId': workId, 'picturePath': picturePath});

        // Save original if requested
        String? originalPath;

        originalPath = await PathHelper.getOriginalWorkPath(
            workId, i, path.extension(file.path));

        AppLogger.debug('复制原始图片', tag: 'ImageService', data: {
          'workId': workId,
          'sourceFile': file.path,
          'targetPath': originalPath
        });

        await file.copy(originalPath);

        // Process and save imported image
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
        await File(importedPath!).writeAsBytes(pngBytes);

        // Create thumbnail for this image
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
        await File(thumbnailPath!).writeAsBytes(jpgBytes);

        // Add image info
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

      // 创建作品缩略图
      if (processedImages.isNotEmpty) {
        final workThumbnailPath =
            await PathHelper.getWorkCoverThumbnailPath(workId);
        AppLogger.debug('创建作品缩略图',
            tag: 'ImageService',
            data: {'workId': workId, 'path': workThumbnailPath});

        try {
          final firstImageFile = File(processedImages[0].path);
          final firstImageBytes = await firstImageFile.readAsBytes();
          final firstImage = img.decodeImage(firstImageBytes);

          if (firstImage != null) {
            final workThumbnail = _createThumbnail(firstImage);

            AppLogger.debug('作品缩略图创建成功', tag: 'ImageService', data: {
              'workId': workId,
              'size': '${workThumbnail.width}x${workThumbnail.height}'
            });

            final thumbnailFile = File(workThumbnailPath);
            final thumbnailParentDir =
                Directory(path.dirname(workThumbnailPath));
            if (!await thumbnailParentDir.exists()) {
              await thumbnailParentDir.create(recursive: true);
            }

            final thumbnailBytes = img.encodeJpg(workThumbnail, quality: 85);
            await thumbnailFile.writeAsBytes(thumbnailBytes);

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

  Future<File> rotateImage(File file, int angle) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片');

    // Rotate image
    image = img.copyRotate(image, angle: angle);

    // Create temp file with unique name
    final dir = path.dirname(file.path);
    final ext = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rotatedPath = path.join(dir, 'rotated_$timestamp$ext');

    // Save rotated image
    final rotatedFile = File(rotatedPath);
    await rotatedFile.writeAsBytes(img.encodeJpg(image));

    // Delete original file if it's a temp file
    if (file.path.contains('temp_')) {
      await file.delete();
    }

    return rotatedFile;
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
}
