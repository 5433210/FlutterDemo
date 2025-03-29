import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../domain/models/work/work_image.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../../infrastructure/image/image_processor.dart';
import '../../../infrastructure/logging/logger.dart';
import '../storage/work_storage_service.dart';
import './service_errors.dart';

typedef ProgressCallback = void Function(double progress, String message);

/// 作品图片服务
class WorkImageService with WorkServiceErrorHandler {
  final WorkStorageService _storage;
  final ImageProcessor _processor;
  final WorkImageRepository _repository;

  WorkImageService({
    required WorkStorageService storage,
    required ImageProcessor processor,
    required WorkImageRepository repository,
  })  : _storage = storage,
        _processor = processor,
        _repository = repository;

  /// 清理未使用的图片文件
  Future<void> cleanupUnusedFiles(String workId, List<String> usedPaths) async {
    return handleOperation(
      'cleanupUnusedFiles',
      () async {
        AppLogger.debug('开始清理未使用的图片文件', tag: 'WorkImageService', data: {
          'workId': workId,
          'usedPathsCount': usedPaths.length,
        });

        final allFiles = await _storage.listWorkFiles(workId);
        final unusedFiles =
            allFiles.where((f) => !usedPaths.contains(f)).toList();

        if (unusedFiles.isNotEmpty) {
          AppLogger.debug('发现未使用的文件', tag: 'WorkImageService', data: {
            'count': unusedFiles.length,
            'files': unusedFiles,
          });

          for (final file in unusedFiles) {
            try {
              await File(file).delete();
            } catch (e) {
              AppLogger.warning('删除未使用文件失败',
                  tag: 'WorkImageService', error: e, data: {'file': file});
            }
          }
        }
      },
      data: {'workId': workId},
    );
  }

  /// 清理作品图片
  Future<void> cleanupWorkImages(String workId) async {
    return handleOperation(
      'cleanupWorkImages',
      () async {
        AppLogger.info('开始清理作品图片', tag: 'WorkImageService', data: {
          'workId': workId,
        });

        // 删除图片文件
        await _storage.deleteWorkDirectory(workId);

        // 删除数据库记录
        await _repository.getAllByWorkId(workId).then((images) {
          if (images.isNotEmpty) {
            final imageIds = images.map((e) => e.id).toList();
            return _repository.deleteMany(workId, imageIds);
          }
        });

        AppLogger.info('图片清理完成', tag: 'WorkImageService');
      },
      data: {'workId': workId},
    );
  }

  /// 删除图片
  Future<void> deleteImage(String workId, String imageId) async {
    return handleOperation(
      'deleteImage',
      () async {
        AppLogger.info('开始删除图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'imageId': imageId,
        });

        // 删除文件
        await _storage.deleteWorkImage(workId, imageId);

        // 删除数据库记录
        await _repository.delete(workId, imageId);

        AppLogger.info('图片删除完成', tag: 'WorkImageService');
      },
      data: {'workId': workId, 'imageId': imageId},
    );
  }

  /// 获取页面缩略图路径
  Future<String?> getPageThumbnailPath(String pageId) async {
    return handleOperation(
      'getPageThumbnailPath',
      () async {
        try {
          final workImage = await _repository.get(pageId);
          if (workImage == null) {
            AppLogger.warning('图片记录不存在', tag: 'WorkImageService', data: {
              'pageId': pageId,
            });
            return null;
          }

          final workId = workImage.workId;
          final thumbnailPath = _storage.getThumbnailPath(workId, pageId);

          // 验证文件是否存在
          final exists = await _storage.verifyWorkImageExists(thumbnailPath);
          if (!exists) {
            AppLogger.warning('缩略图文件不存在', tag: 'WorkImageService', data: {
              'pageId': pageId,
              'path': thumbnailPath,
            });
            return null;
          }

          return thumbnailPath;
        } catch (e, stack) {
          AppLogger.error('获取缩略图路径失败',
              tag: 'WorkImageService',
              error: e,
              stackTrace: stack,
              data: {'pageId': pageId});
          return null;
        }
      },
      data: {'pageId': pageId},
    );
  }

  /// 获取作品的所有图片
  Future<List<WorkImage>> getWorkImages(String workId) async {
    return handleOperation(
      'getWorkImages',
      () => _repository.getAllByWorkId(workId),
      data: {'workId': workId},
    );
  }

  /// 获取作品页面ID列表
  Future<List<String>?> getWorkPageIds(String workId) async {
    return handleOperation(
      'getWorkPageIds',
      () async {
        AppLogger.debug('获取作品页面ID列表', tag: 'WorkImageService', data: {
          'workId': workId,
        });

        final images = await _repository.getAllByWorkId(workId);
        if (images.isEmpty) {
          return null;
        }

        // 按照索引排序并提取ID
        final sortedImages = [...images]
          ..sort((a, b) => a.index.compareTo(b.index));
        final ids = sortedImages.map((img) => img.id).toList();

        return ids;
      },
      data: {'workId': workId},
    );
  }

  /// 获取页面图片数据
  Future<Uint8List?> getWorkPageImage(String workId, String pageId) async {
    return handleOperation(
      'getWorkPageImage',
      () async {
        AppLogger.debug('获取作品页面图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'pageId': pageId,
        });

        // 获取导入后的图片路径
        final imagePath = _storage.getImportedPath(workId, pageId);
        final file = File(imagePath);

        if (!await file.exists()) {
          AppLogger.warning('图片文件不存在',
              tag: 'WorkImageService', data: {'path': imagePath});
          return null;
        }

        // 读取图片数据
        final imageBytes = await file.readAsBytes();

        AppLogger.debug('读取页面图片数据', tag: 'WorkImageService', data: {
          'workId': workId,
          'pageId': pageId,
          'imageSize': imageBytes.length,
        });

        // 验证图片数据
        try {
          final image = img.decodeImage(imageBytes);
          if (image != null) {
            AppLogger.debug('图片数据验证成功', tag: 'WorkImageService', data: {
              'width': image.width,
              'height': image.height,
            });
          }
        } catch (e, stack) {
          AppLogger.error('图片数据解码失败',
              tag: 'WorkImageService', error: e, stackTrace: stack);
        }

        return imageBytes;
      },
      data: {
        'workId': workId,
        'pageId': pageId,
      },
    );
  }

  /// 导入图片
  Future<WorkImage> importImage(String workId, File file) async {
    return handleOperation(
      'importImage',
      () async {
        final imageId = DateTime.now().millisecondsSinceEpoch.toString();

        AppLogger.debug('准备导入新图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'imageId': imageId,
          'filePath': file.path,
        });

        if (!await file.exists()) {
          throw FileSystemException('源文件不存在', file.path);
        }

        // 先创建临时图片对象
        final nextIndex = await _getNextImageIndex(workId);
        final tempImage = WorkImage(
          id: imageId,
          workId: workId,
          path: file.path,
          originalPath: file.path,
          thumbnailPath: file.path,
          format: _getImageFormat(file),
          size: await file.length(),
          width: 0,
          height: 0,
          index: nextIndex,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        );

        AppLogger.debug('创建临时图片对象', tag: 'WorkImageService', data: {
          'imageId': imageId,
          'index': nextIndex,
        });

        return tempImage;
      },
      data: {'workId': workId, 'file': file.path},
    );
  }

  /// 批量导入图片
  Future<List<WorkImage>> importImages(String workId, List<File> files) async {
    return handleOperation(
      'importImages',
      () async {
        AppLogger.info('开始批量导入图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'fileCount': files.length,
        });

        final images = <WorkImage>[];
        final uniqueFiles = LinkedHashSet<File>(
          equals: (a, b) => a.path == b.path,
          hashCode: (file) => file.absolute.path.hashCode,
        )..addAll(files);

        AppLogger.debug('文件去重完成', tag: 'WorkImageService', data: {
          'originalCount': files.length,
          'uniqueCount': uniqueFiles.length,
        });

        for (final file in uniqueFiles) {
          final image = await importImage(workId, file);
          images.add(image);
        }

        return images;
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }

  /// 处理完整的图片导入流程
  Future<List<WorkImage>> processImport(String workId, List<File> files) async {
    return handleOperation(
      'processImport',
      () async {
        AppLogger.info('开始处理图片导入', tag: 'WorkImageService', data: {
          'workId': workId,
          'fileCount': files.length,
        });

        // 1. 确保作品目录结构
        await _storage.ensureWorkDirectoryExists(workId);

        // 2. 导入所有图片
        final tempImages = await importImages(workId, files);

        // 3. 处理并保存图片
        final savedImages = await saveChanges(workId, tempImages);

        // 4. 强制验证封面是否已正确生成
        if (savedImages.isNotEmpty) {
          AppLogger.info('导入完成后验证封面', tag: 'WorkImageService');
          await _verifyCoverExists(workId);
        }

        AppLogger.info('图片导入处理完成', tag: 'WorkImageService', data: {
          'workId': workId,
          'totalSaved': savedImages.length,
        });

        return savedImages;
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }

  /// 保存图片更改
  Future<List<WorkImage>> saveChanges(
    String workId,
    List<WorkImage> images, {
    ProgressCallback? onProgress,
  }) async {
    return handleOperation(
      'saveChanges',
      () async {
        AppLogger.info('开始保存图片更改', tag: 'WorkImageService', data: {
          'workId': workId,
          'imageCount': images.length,
          'firstImageId': images.isNotEmpty ? images[0].id : null,
        });

        // 处理流程
        // [Previous implementation stays the same...]
        return images;
      },
      data: {'workId': workId, 'imageCount': images.length},
    );
  }

  /// 更新封面
  Future<void> updateCover(String workId, String imageId) async {
    return handleOperation(
      'updateCover',
      () async {
        AppLogger.debug('开始更新作品封面', tag: 'WorkImageService', data: {
          'workId': workId,
          'imageId': imageId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // [Previous implementation stays the same...]
      },
      data: {'workId': workId, 'imageId': imageId},
    );
  }

  String _getImageFormat(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  Future<int> _getNextImageIndex(String workId) async {
    return await _repository.getNextIndex(workId);
  }

  bool _haveImagesBeenReordered(
      List<WorkImage> oldImages, List<WorkImage> newImages) {
    // [Previous implementation stays the same...]
    return false;
  }

  Future<void> _verifyAllProcessedFiles(List<String> paths) async {
    // [Previous implementation stays the same...]
  }

  Future<bool> _verifyCoverExists(String workId) async {
    // [Previous implementation stays the same...]
    return true;
  }
}
