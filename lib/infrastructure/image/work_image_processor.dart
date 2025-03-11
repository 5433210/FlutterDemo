import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/models/work/work_image.dart';
import '../../domain/services/work_image_processing_interface.dart';
import '../../domain/services/work_image_storage_interface.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/storage/storage_interface.dart';
import './base_image_processor.dart';

class WorkImageProcessor extends BaseImageProcessor
    implements IWorkImageProcessing {
  static const int _thumbnailSize = 256;
  static const int _quality = 85;
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1080;

  final IStorage _storage;
  final IWorkImageStorage _workImageStorage;
  final _uuid = const Uuid();

  WorkImageProcessor(this._storage, this._workImageStorage);

  @override
  Future<File> generateWorkThumbnail(File image) async {
    try {
      // 读取图片
      final bytes = await image.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('无法解码图片');

      // 计算缩略图尺寸
      final aspectRatio = decoded.width / decoded.height;
      int thumbWidth, thumbHeight;

      if (aspectRatio > 1) {
        thumbWidth = _thumbnailSize;
        thumbHeight = (_thumbnailSize / aspectRatio).round();
      } else {
        thumbHeight = _thumbnailSize;
        thumbWidth = (_thumbnailSize * aspectRatio).round();
      }

      // 调整大小
      final resized = img.copyResize(
        decoded,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.average,
      );

      // 创建临时文件
      final tempDir = await _storage.getTempDirectory();
      final thumbnailPath = path.join(
          tempDir.path, 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final thumbnailFile = File(thumbnailPath);

      // 保存为JPEG
      await thumbnailFile
          .writeAsBytes(img.encodeJpg(resized, quality: _quality));

      return thumbnailFile;
    } catch (e, stack) {
      AppLogger.error('生成缩略图失败',
          tag: 'WorkImageProcessor',
          error: e,
          stackTrace: stack,
          data: {'path': image.path});
      rethrow;
    }
  }

  @override
  Future<List<WorkImage>> processWorkImages(
      String workId, List<File> images) async {
    try {
      AppLogger.info('开始处理作品图片',
          tag: 'WorkImageProcessor',
          data: {'workId': workId, 'count': images.length});

      final processed = <WorkImage>[];

      for (var i = 0; i < images.length; i++) {
        final file = images[i];

        // 优化原图
        final optimized = await optimize(file, _quality);

        // 调整尺寸（如果需要）
        final bytes = await optimized.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('无法解码图片');

        File resizedFile = optimized;
        if (image.width > _maxImageWidth || image.height > _maxImageHeight) {
          resizedFile = await resize(
            optimized,
            width: _maxImageWidth,
            height: _maxImageHeight,
          );
        }

        // 生成缩略图
        final thumbnail = await generateWorkThumbnail(resizedFile);

        // 移动到永久存储目录
        final imageDir =
            await _workImageStorage.getWorkImageDir(workId, i.toString());
        await _storage.ensureDirectoryExists(imageDir);

        final imagePath =
            path.join(imageDir, 'image${path.extension(resizedFile.path)}');
        final thumbnailPath = path.join(imageDir, 'thumbnail.jpg');

        await resizedFile.copy(imagePath);
        await thumbnail.copy(thumbnailPath);

        // 清理临时文件
        await optimized.delete();
        if (resizedFile.path != optimized.path) await resizedFile.delete();
        await thumbnail.delete();

        // 添加到处理结果
        processed.add(WorkImage.create(
            id: _uuid.v4(),
            workId: workId,
            originalPath: file.path,
            path: imagePath,
            thumbnailPath: thumbnailPath,
            index: i,
            width: image.width,
            height: image.height,
            format: path.extension(file.path).toLowerCase().replaceAll('.', ''),
            size: await file.length()));

        AppLogger.debug('完成处理图片', tag: 'WorkImageProcessor', data: {
          'workId': workId,
          'index': i,
          'imagePath': imagePath,
          'thumbnailPath': thumbnailPath
        });
      }

      return processed;
    } catch (e, stack) {
      AppLogger.error('处理作品图片失败',
          tag: 'WorkImageProcessor',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }
}
