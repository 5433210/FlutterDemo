import 'dart:collection';
import 'dart:io';

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

  /// 删除图片（不立即更新数据库）
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

        AppLogger.info('图片文件删除完成', tag: 'WorkImageService');
      },
      data: {'workId': workId, 'imageId': imageId},
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

  /// 导入新图片（返回临时状态，不立即保存）
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

  /// 批量导入图片（不立即保存）
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

        // 首先获取当前所有图片，用于清理未使用的图片
        final existingImages = await _repository.getAllByWorkId(workId);
        final existingIds = existingImages.map((img) => img.id).toSet();
        final newIds = images.map((img) => img.id).toSet();

        // 获取当前的首张图片ID（用于后续检查是否需要更新封面）
        final existingFirstImage =
            existingImages.isNotEmpty ? existingImages[0] : null;
        final newFirstImageId = images.isNotEmpty ? images[0].id : null;

        // 清理已删除的图片记录
        final deletedIds = existingIds.difference(newIds).toList();
        if (deletedIds.isNotEmpty) {
          await _repository.deleteMany(workId, deletedIds);
        }

        final processedImages = <WorkImage>[];
        final tempFiles = <String>[];
        var index = 0;
        final total = images.length;

        try {
          // 处理每个图片
          for (final image in images) {
            onProgress?.call(
              index / total,
              '处理图片 ${index + 1}/$total',
            );

            AppLogger.debug('处理图片', tag: 'WorkImageService', data: {
              'imageId': image.id,
              'isNew': image.path == image.originalPath,
              'index': index,
            });

            if (image.path == image.originalPath) {
              // 新图片: 需要完整的处理流程
              try {
                final file = File(image.path);
                if (!await file.exists()) {
                  throw FileSystemException('源文件不存在', image.path);
                }

                // 1. 保存原始文件
                final originalPath = await _storage.saveOriginalImage(
                  workId,
                  image.id,
                  file,
                );
                tempFiles.add(originalPath);

                // 2. 处理并保存导入图片
                final processedFile = await _processor.processImage(
                  file,
                  maxWidth: 2400,
                  maxHeight: 2400,
                  quality: 90,
                );
                final importedPath = await _storage.saveImportedImage(
                  workId,
                  image.id,
                  processedFile,
                );
                tempFiles.add(importedPath);

                // 3. 生成并保存缩略图
                final thumbnail = await _processor.processImage(
                  file,
                  maxWidth: 200,
                  maxHeight: 200,
                  quality: 80,
                );
                final thumbnailPath = await _storage.saveThumbnail(
                  workId,
                  image.id,
                  thumbnail,
                );
                tempFiles.add(thumbnailPath);

                // 4. 获取图片信息
                final info = await _storage.getWorkImageInfo(importedPath);

                processedImages.add(image.copyWith(
                  path: importedPath,
                  originalPath: originalPath,
                  thumbnailPath: thumbnailPath,
                  width: info['width'] ?? 0,
                  height: info['height'] ?? 0,
                  size: info['size'] ?? 0,
                  index: index++,
                  updateTime: DateTime.now(),
                ));

                AppLogger.debug('新图片处理完成', tag: 'WorkImageService', data: {
                  'imageId': image.id,
                  'size': info['size'],
                });
              } catch (e, stack) {
                AppLogger.error('处理新图片失败',
                    tag: 'WorkImageService',
                    error: e,
                    stackTrace: stack,
                    data: {
                      'imageId': image.id,
                      'path': image.path,
                    });
                rethrow;
              }
            } else {
              // 已存在的图片: 只更新索引
              processedImages.add(image.copyWith(
                index: index++,
                updateTime: DateTime.now(),
              ));
            }
          }

          onProgress?.call(0.9, '保存到数据库...');

          AppLogger.debug('所有图片处理完成', tag: 'WorkImageService', data: {
            'totalProcessed': processedImages.length,
          });

          try {
            // 批量保存到数据库
            final savedImages = await _repository.saveMany(processedImages);

            // 检查是否需要更新封面（首图变化时）
            if (savedImages.isNotEmpty) {
              final newFirstImage = savedImages[0];
              if (existingFirstImage == null ||
                  existingFirstImage.id != newFirstImageId) {
                AppLogger.debug('首张图片已更改，重新生成封面',
                    tag: 'WorkImageService',
                    data: {
                      'oldImageId': existingFirstImage?.id,
                      'newImageId': newFirstImage.id,
                    });

                try {
                  await updateCover(workId, newFirstImage.id);
                } catch (e) {
                  AppLogger.error('生成封面失败', tag: 'WorkImageService', error: e);
                  // 继续执行，不中断保存流程
                }
              }
            }

            // 清理未使用的文件
            final usedPaths = savedImages
                .expand(
                    (img) => [img.path, img.originalPath, img.thumbnailPath])
                .toList();
            await cleanupUnusedFiles(workId, usedPaths);

            onProgress?.call(1.0, '完成');

            AppLogger.info('图片保存完成', tag: 'WorkImageService', data: {
              'savedCount': savedImages.length,
            });

            return savedImages;
          } catch (e, stack) {
            AppLogger.error('保存到数据库失败',
                tag: 'WorkImageService', error: e, stackTrace: stack);
            // 清理临时文件
            for (final path in tempFiles) {
              try {
                await File(path).delete();
              } catch (e) {
                AppLogger.warning('清理临时文件失败',
                    tag: 'WorkImageService', error: e, data: {'path': path});
              }
            }
            rethrow;
          }
        } catch (e) {
          // 确保进度回调显示错误状态
          onProgress?.call(0, '保存失败: ${e.toString()}');
          rethrow;
        }
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
        });

        // 确保封面目录存在
        await _storage.ensureWorkDirectoryExists(workId);

        // 获取源图片路径并验证
        final importedPath = _storage.getImportedPath(workId, imageId);
        final sourceFile = File(importedPath);
        if (!await sourceFile.exists()) {
          throw FileSystemException('源图片不存在', importedPath);
        }

        try {
          // 生成并保存封面导入图
          final coverImportedPath =
              await _storage.saveCoverImported(workId, sourceFile);

          // 生成并保存封面缩略图
          final thumbnail = await _processor.processImage(
            sourceFile,
            maxWidth: 200,
            maxHeight: 200,
            quality: 80,
          );
          final coverThumbnailPath =
              await _storage.saveCoverThumbnail(workId, thumbnail);

          // 验证封面文件是否成功生成
          final coverFiles = [
            File(coverImportedPath),
            File(coverThumbnailPath),
          ];

          for (final file in coverFiles) {
            if (!await file.exists()) {
              throw FileSystemException('封面文件生成失败', file.path);
            }
          }

          AppLogger.info('作品封面更新完成', tag: 'WorkImageService', data: {
            'workId': workId,
            'imageId': imageId,
            'coverImported': coverImportedPath,
            'coverThumbnail': coverThumbnailPath,
          });
        } catch (e, stack) {
          AppLogger.error('生成封面失败',
              tag: 'WorkImageService',
              error: e,
              stackTrace: stack,
              data: {
                'workId': workId,
                'imageId': imageId,
                'sourcePath': importedPath,
              });
          rethrow;
        }
      },
      data: {'workId': workId, 'imageId': imageId},
    );
  }

  /// 获取图片格式
  String _getImageFormat(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// 获取下一个图片索引
  Future<int> _getNextImageIndex(String workId) async {
    return await _repository.getNextIndex(workId);
  }
}
