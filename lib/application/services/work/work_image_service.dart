import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

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
        AppLogger.info('开始清理未使用的图片文件', tag: 'WorkImageService', data: {
          'workId': workId,
          'usedPathsCount': usedPaths.length,
          'usedPaths': usedPaths.take(5).toList(),
        });

        final allFiles = await _storage.listWorkFiles(workId);
        AppLogger.info('发现所有文件', tag: 'WorkImageService', data: {
          'workId': workId,
          'allFilesCount': allFiles.length,
          'allFiles': allFiles.take(10).toList(),
        });

        // 路径标准化：统一使用绝对路径进行比较
        final normalizedUsedPaths =
            usedPaths.map((path) => File(path).absolute.path).toSet();
        final normalizedAllFiles =
            allFiles.map((path) => File(path).absolute.path).toList();

        AppLogger.info('路径标准化完成', tag: 'WorkImageService', data: {
          'workId': workId,
          'originalUsedPaths': usedPaths.take(3).toList(),
          'normalizedUsedPaths': normalizedUsedPaths.take(3).toList(),
          'originalAllFiles': allFiles.take(3).toList(),
          'normalizedAllFiles': normalizedAllFiles.take(3).toList(),
        });

        // 详细检查每个文件是否被使用
        final detailedFileCheck = <String, Map<String, dynamic>>{};
        for (final file in normalizedAllFiles) {
          final isUsed = normalizedUsedPaths.contains(file);
          detailedFileCheck[file] = {
            'isUsed': isUsed,
            'originalPath': allFiles[normalizedAllFiles.indexOf(file)],
            'matchingUsedPath': isUsed ? file : null,
          };
        }

        AppLogger.info('详细文件使用状态检查', tag: 'WorkImageService', data: {
          'workId': workId,
          'fileCheckSample': detailedFileCheck.entries
              .take(3)
              .map((e) => {
                    'file': e.key,
                    'status': e.value,
                  })
              .toList(),
        });

        final unusedFiles = normalizedAllFiles
            .where((f) => !normalizedUsedPaths.contains(f))
            .toList();

        if (unusedFiles.isNotEmpty) {
          // 在删除之前，进行额外的安全检查
          final safeToDelete = <String>[];
          final unsafeToDelete = <String>[];

          // 在删除之前，记录所有文件的详细信息
          final fileDetails = <String, Map<String, dynamic>>{};
          for (final file in normalizedAllFiles) {
            final fileObj = File(file);
            final exists = await fileObj.exists();
            final fileName = file.split(Platform.pathSeparator).last;
            final isUsed = normalizedUsedPaths.contains(file);

            fileDetails[file] = {
              'exists': exists,
              'size': exists ? await fileObj.length() : 0,
              'fileName': fileName,
              'isUsed': isUsed,
              'isCover': file.contains('cover'),
              'isImported': fileName.contains('imported'),
              'isOriginal': fileName.contains('original'),
              'isThumbnail': fileName.contains('thumbnail'),
            };
          }

          AppLogger.info('所有文件详细信息', tag: 'WorkImageService', data: {
            'workId': workId,
            'fileDetails': fileDetails.entries
                .take(10)
                .map((e) => {
                      'path': e.key,
                      'info': e.value,
                    })
                .toList(),
          });

          // 特别检查封面文件
          final coverImportedPath = _storage.getWorkCoverImportedPath(workId);
          final coverThumbnailPath = _storage.getWorkCoverThumbnailPath(workId);

          AppLogger.info('封面文件检查', tag: 'WorkImageService', data: {
            'workId': workId,
            'coverImportedPath': coverImportedPath,
            'coverThumbnailPath': coverThumbnailPath,
            'coverImportedInUsedPaths': normalizedUsedPaths
                .contains(File(coverImportedPath).absolute.path),
            'coverThumbnailInUsedPaths': normalizedUsedPaths
                .contains(File(coverThumbnailPath).absolute.path),
            'coverImportedInAllFiles': normalizedAllFiles
                .contains(File(coverImportedPath).absolute.path),
            'coverThumbnailInAllFiles': normalizedAllFiles
                .contains(File(coverThumbnailPath).absolute.path),
          });

          for (final file in unusedFiles) {
            // 检查是否是系统文件或重要文件
            final fileName =
                file.split(Platform.pathSeparator).last.toLowerCase();
            if (fileName.startsWith('cover_') ||
                fileName.contains('thumbnail') ||
                fileName.contains('imported') ||
                fileName.contains('original')) {
              // 对于重要文件，进行额外验证
              bool shouldKeep = false;

              // 检查是否可能是当前使用的文件的不同路径表示
              for (final usedPath in normalizedUsedPaths) {
                final usedFileName =
                    usedPath.split(Platform.pathSeparator).last;
                if (usedFileName == fileName) {
                  shouldKeep = true;
                  AppLogger.warning('发现可能的路径匹配冲突',
                      tag: 'WorkImageService',
                      data: {
                        'candidateForDeletion': file,
                        'matchingUsedPath': usedPath,
                        'fileName': fileName,
                      });
                  break;
                }
              }

              if (shouldKeep) {
                unsafeToDelete.add(file);
              } else {
                safeToDelete.add(file);
              }
            } else {
              safeToDelete.add(file);
            }
          }

          AppLogger.warning('文件删除安全检查完成', tag: 'WorkImageService', data: {
            'workId': workId,
            'totalUnusedFiles': unusedFiles.length,
            'safeToDelete': safeToDelete.length,
            'unsafeToDelete': unsafeToDelete.length,
            'safeFiles': safeToDelete.take(5).toList(),
            'unsafeFiles': unsafeToDelete.take(5).toList(),
          });

          // 只删除安全的文件
          for (final file in safeToDelete) {
            try {
              final fileObj = File(file);
              final existsBefore = await fileObj.exists();
              AppLogger.info('准备删除未使用文件', tag: 'WorkImageService', data: {
                'file': file,
                'existsBefore': existsBefore,
                'size': existsBefore ? await fileObj.length() : 0,
              });

              if (existsBefore) {
                await fileObj.delete();
                AppLogger.info('已删除未使用文件', tag: 'WorkImageService', data: {
                  'file': file,
                  'existsAfter': await fileObj.exists(),
                });
              }
            } catch (e) {
              AppLogger.warning('删除未使用文件失败',
                  tag: 'WorkImageService', error: e, data: {'file': file});
            }
          }

          // 报告不安全的文件
          if (unsafeToDelete.isNotEmpty) {
            AppLogger.warning('跳过删除不安全的文件', tag: 'WorkImageService', data: {
              'workId': workId,
              'skippedFiles': unsafeToDelete,
              'reason': '可能与当前使用的文件有路径冲突',
            });
          }
        } else {
          AppLogger.info('没有发现未使用的文件', tag: 'WorkImageService', data: {
            'workId': workId,
            'allFilesCount': allFiles.length,
            'usedPathsCount': usedPaths.length,
          });
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

  /// Gets the all image ids for a work
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

  /// Gets the image data for a specific page of a work
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

  /// 导入新图片（返回临时状态，不立即保存）
  Future<WorkImage> importImage(
    String workId,
    File file, {
    String? libraryItemId,
  }) async {
    return handleOperation(
      'importImage',
      () async {
        final imageId = const Uuid().v4();

        AppLogger.debug('准备导入新图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'imageId': imageId,
          'filePath': file.path,
          'libraryItemId': libraryItemId,
        });

        if (!await file.exists()) {
          throw FileSystemException('源文件不存在', file.path);
        }

        // 先创建临时图片对象
        final nextIndex = await _getNextImageIndex(workId);
        final tempImage = WorkImage(
          id: imageId,
          workId: workId,
          libraryItemId: libraryItemId,
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
          'libraryItemId': libraryItemId,
        });

        return tempImage;
      },
      data: {
        'workId': workId,
        'file': file.path,
        'libraryItemId': libraryItemId
      },
    );
  }

  /// 批量导入图片（不立即保存）
  Future<List<WorkImage>> importImages(
    String workId,
    List<File> files, {
    Map<String, String>? libraryItemIds, // filePath -> libraryItemId 的映射
  }) async {
    return handleOperation(
      'importImages',
      () async {
        AppLogger.info('开始批量导入图片', tag: 'WorkImageService', data: {
          'workId': workId,
          'fileCount': files.length,
          'libraryItemIdsCount': libraryItemIds?.length ?? 0,
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
          final libraryItemId = libraryItemIds?[file.path];
          final image =
              await importImage(workId, file, libraryItemId: libraryItemId);
          images.add(image);
        }

        return images;
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }

  /// 处理完整的图片导入流程
  Future<List<WorkImage>> processImport(
    String workId,
    List<File> files, {
    Map<String, String>? libraryItemIds, // filePath -> libraryItemId 的映射
  }) async {
    return handleOperation(
      'processImport',
      () async {
        AppLogger.info('开始处理图片导入', tag: 'WorkImageService', data: {
          'workId': workId,
          'fileCount': files.length,
          'libraryItemIdsCount': libraryItemIds?.length ?? 0,
        });

        // 1. 确保作品目录结构
        await _storage.ensureWorkDirectoryExists(workId);

        // 2. 导入所有图片
        final tempImages =
            await importImages(workId, files, libraryItemIds: libraryItemIds);

        // 3. 处理并保存图片
        final savedImages = await saveChanges(workId, tempImages);

        // 4. 强制验证封面是否已正确生成
        if (savedImages.isNotEmpty) {
          AppLogger.info('导入完成后验证封面', tag: 'WorkImageService');

          final coverPath = _storage.getWorkCoverImportedPath(workId);
          final coverThumbnailPath = _storage.getWorkCoverThumbnailPath(workId);

          // 检查封面和缩略图
          final coverExists = await _storage.verifyWorkImageExists(coverPath);
          final thumbnailExists =
              await _storage.verifyWorkImageExists(coverThumbnailPath);

          AppLogger.debug('导入后封面状态', tag: 'WorkImageService', data: {
            'coverExists': coverExists,
            'thumbnailExists': thumbnailExists,
            'coverPath': coverPath,
            'thumbnailPath': coverThumbnailPath,
          });

          // 如果封面或缩略图不存在，重新生成
          if (!coverExists || !thumbnailExists) {
            AppLogger.warning('导入后封面验证失败，重新生成', tag: 'WorkImageService', data: {
              'workId': workId,
              'firstImageId': savedImages[0].id,
              'coverMissing': !coverExists,
              'thumbnailMissing': !thumbnailExists,
            });

            await updateCover(workId, savedImages[0].id);

            // 再次验证封面是否生成成功
            final coverRegenerated =
                await _storage.verifyWorkImageExists(coverPath);
            final thumbnailRegenerated =
                await _storage.verifyWorkImageExists(coverThumbnailPath);

            if (!coverRegenerated || !thumbnailRegenerated) {
              AppLogger.error('封面重新生成后仍然缺失', tag: 'WorkImageService', data: {
                'workId': workId,
                'coverMissing': !coverRegenerated,
                'thumbnailMissing': !thumbnailRegenerated,
              });
            }
          }
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
          'imageOrder':
              images.map((img) => '${img.id}(${img.index})').take(5).toList(),
          'firstImageId': images.isNotEmpty ? images[0].id : null,
        });

        // 首先获取当前所有图片，用于清理未使用的图片
        final existingImages = await _repository.getAllByWorkId(workId);
        final existingIds = existingImages.map((img) => img.id).toSet();
        final newIds = images.map((img) => img.id).toSet();

        // 获取当前的首张图片ID
        final existingFirstImageId =
            existingImages.isNotEmpty ? existingImages[0].id : null;
        final newFirstImageId = images.isNotEmpty ? images[0].id : null;

        // 检测图片顺序是否变化
        final imagesReordered =
            _haveImagesBeenReordered(existingImages, images);

        AppLogger.info('图片顺序变化检测', tag: 'WorkImageService', data: {
          'currentFirstImageId': existingFirstImageId,
          'newFirstImageId': newFirstImageId,
          'currentFirstImageIndex':
              existingImages.isNotEmpty ? existingImages[0].index : null,
          'newFirstImageIndex': images.isNotEmpty ? images[0].index : null,
          'imagesReordered': imagesReordered,
          'existingOrder': existingImages
              .map((img) => '${img.id}(${img.index})')
              .take(5)
              .toList(),
          'newOrder':
              images.map((img) => '${img.id}(${img.index})').take(5).toList(),
        });

        // 确定是否需要更新封面
        // 只有当首图真的变化时才更新封面，纯顺序调整且首图未变不需要更新
        final shouldUpdateCover = newFirstImageId != null &&
            existingFirstImageId != null &&
            existingFirstImageId != newFirstImageId;

        AppLogger.info('封面更新判断', tag: 'WorkImageService', data: {
          'existingFirstImageId': existingFirstImageId,
          'newFirstImageId': newFirstImageId,
          'shouldUpdateCover': shouldUpdateCover,
          'reason': shouldUpdateCover ? '首图ID变化' : '首图未变化，不需要更新封面',
        });

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

            AppLogger.info('处理图片', tag: 'WorkImageService', data: {
              'imageId': image.id,
              'isNew': image.path == image.originalPath,
              'index': index,
              'targetIndex': image.index,
              'path': image.path,
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
              // 已存在的图片: 只更新索引，同时验证文件是否存在
              AppLogger.info('处理现有图片（顺序调整）', tag: 'WorkImageService', data: {
                'imageId': image.id,
                'currentPath': image.path,
                'originalPath': image.originalPath,
                'thumbnailPath': image.thumbnailPath,
                'targetIndex': index,
              });

              // 验证当前图片的所有相关文件是否存在
              final pathsToCheck = [
                {'type': 'imported', 'path': image.path},
                {'type': 'original', 'path': image.originalPath},
                {'type': 'thumbnail', 'path': image.thumbnailPath},
              ];

              for (final pathInfo in pathsToCheck) {
                final file = File(pathInfo['path'] as String);
                final exists = await file.exists();
                AppLogger.info('验证现有图片文件', tag: 'WorkImageService', data: {
                  'imageId': image.id,
                  'fileType': pathInfo['type'],
                  'path': pathInfo['path'],
                  'exists': exists,
                  'fileSize': exists ? await file.length() : 0,
                });

                if (!exists) {
                  AppLogger.warning('现有图片文件缺失', tag: 'WorkImageService', data: {
                    'imageId': image.id,
                    'fileType': pathInfo['type'],
                    'missingPath': pathInfo['path'],
                    'reason': '顺序调整时发现文件缺失',
                  });
                }
              }

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
            if (shouldUpdateCover && savedImages.isNotEmpty) {
              AppLogger.info('需要更新封面', tag: 'WorkImageService', data: {
                'oldFirstImageId': existingFirstImageId,
                'newFirstImageId': newFirstImageId,
                'reason': existingFirstImageId != newFirstImageId
                    ? '首图ID变化'
                    : imagesReordered
                        ? '图片顺序变化'
                        : '其他原因'
              });

              try {
                // 使用当前首图更新封面
                await updateCover(workId, savedImages[0].id);

                AppLogger.debug('封面已更新', tag: 'WorkImageService', data: {
                  'usedImageId': savedImages[0].id,
                  'usedImageIndex': savedImages[0].index,
                });

                // 验证封面文件确实存在
                await _verifyCoverExists(workId);
              } catch (e, stack) {
                AppLogger.error('生成封面失败',
                    tag: 'WorkImageService',
                    error: e,
                    stackTrace: stack,
                    data: {
                      'workId': workId,
                      'firstImageId': savedImages[0].id,
                    });
                // 继续执行，不中断保存流程
              }
            } else {
              // 记录不需要更新封面的原因
              AppLogger.debug('不需要更新封面', tag: 'WorkImageService', data: {
                'existingFirstImageId': existingFirstImageId,
                'newFirstImageId': newFirstImageId,
                'imagesReordered': imagesReordered,
                'shouldUpdateCover': shouldUpdateCover,
              });

              // 即使不需要更新封面，也验证封面存在
              if (savedImages.isNotEmpty) {
                await _verifyCoverExists(workId);
              }
            }

            // 清理未使用的文件
            final usedPaths = <String>[];

            // 收集所有图片相关的路径
            for (final img in savedImages) {
              usedPaths.addAll([img.path, img.originalPath, img.thumbnailPath]);
            }

            // 添加封面文件路径
            try {
              final coverImportedPath =
                  _storage.getWorkCoverImportedPath(workId);
              final coverThumbnailPath =
                  _storage.getWorkCoverThumbnailPath(workId);
              usedPaths.addAll([coverImportedPath, coverThumbnailPath]);

              AppLogger.info('添加封面文件到保护列表', tag: 'WorkImageService', data: {
                'coverImportedPath': coverImportedPath,
                'coverThumbnailPath': coverThumbnailPath,
                'coverImportedExists': await File(coverImportedPath).exists(),
                'coverThumbnailExists': await File(coverThumbnailPath).exists(),
              });
            } catch (e) {
              AppLogger.warning('获取封面文件路径失败',
                  tag: 'WorkImageService', error: e);
            }

            AppLogger.info('收集所有应该保留的文件路径', tag: 'WorkImageService', data: {
              'workId': workId,
              'savedImagesCount': savedImages.length,
              'usedPathsCount': usedPaths.length,
              'usedPaths': usedPaths.take(10).toList(),
              'imageDetails': savedImages
                  .map((img) => {
                        'id': img.id,
                        'path': img.path,
                        'originalPath': img.originalPath,
                        'thumbnailPath': img.thumbnailPath,
                      })
                  .take(3)
                  .toList(),
            });

            await cleanupUnusedFiles(workId, usedPaths);

            // Verify all processed files
            await _verifyAllProcessedFiles(tempFiles);

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
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // 确保封面目录存在
        await _storage.ensureWorkDirectoryExists(workId);

        // 尝试多个可能的源图片路径
        final importedPath = _storage.getImportedPath(workId, imageId);
        final originalPath = _storage.getOriginalPath(workId, imageId);

        File? sourceFile;
        String sourcePath = '';

        // 首先尝试 imported.png
        if (await File(importedPath).exists()) {
          sourceFile = File(importedPath);
          sourcePath = importedPath;
          AppLogger.debug('使用导入图片作为封面源', tag: 'WorkImageService', data: {
            'sourcePath': sourcePath,
          });
        }
        // 如果 imported.png 不存在，尝试 original.jpg/png/etc
        else if (await File(originalPath).exists()) {
          sourceFile = File(originalPath);
          sourcePath = originalPath;
          AppLogger.debug('使用原始图片作为封面源', tag: 'WorkImageService', data: {
            'sourcePath': sourcePath,
          });
        }
        // 最后尝试从数据库中获取图片的实际路径
        else {
          final image = await _repository.get(imageId);
          if (image != null && await File(image.path).exists()) {
            sourceFile = File(image.path);
            sourcePath = image.path;
            AppLogger.debug('使用数据库路径作为封面源', tag: 'WorkImageService', data: {
              'sourcePath': sourcePath,
            });
          }
        }

        if (sourceFile == null || !await sourceFile.exists()) {
          AppLogger.error('无法找到有效的源图片文件', tag: 'WorkImageService', data: {
            'workId': workId,
            'imageId': imageId,
            'importedPath': importedPath,
            'originalPath': originalPath,
          });
          throw FileSystemException('无法找到有效的源图片文件', importedPath);
        }

        try {
          // 记录源图片信息，有助于调试
          final sourceSize = await sourceFile.length();
          AppLogger.debug('源图片文件信息', tag: 'WorkImageService', data: {
            'sourceSize': sourceSize,
            'sourcePath': sourcePath,
          });

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

          bool allFilesExist = true;
          for (final file in coverFiles) {
            final exists = await file.exists();
            if (!exists) {
              allFilesExist = false;
              AppLogger.error('封面文件生成后不存在',
                  tag: 'WorkImageService', data: {'path': file.path});
            } else {
              // 记录文件大小用于调试
              final size = await file.length();
              AppLogger.debug('生成的封面文件信息', tag: 'WorkImageService', data: {
                'path': file.path,
                'size': size,
              });
            }
          }

          if (!allFilesExist) {
            throw const FileSystemException('封面文件生成失败');
          }

          AppLogger.info('作品封面更新完成', tag: 'WorkImageService', data: {
            'workId': workId,
            'imageId': imageId,
            'coverImported': coverImportedPath,
            'coverThumbnail': coverThumbnailPath,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
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

  /// 确保文件写入完成
  Future<void> _ensureFileWritten(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // 尝试打开文件并读取一部分来确保它已完全写入
        final raf = await file.open(mode: FileMode.read);
        try {
          await raf.read(4); // 读取几个字节以确认文件可访问
        } finally {
          await raf.close();
        }
      } else {
        AppLogger.warning(
          '文件不存在，无法确认写入状态',
          tag: 'WorkImageService',
          data: {'path': filePath},
        );
      }
    } catch (e) {
      AppLogger.warning(
        '确认文件写入状态失败',
        tag: 'WorkImageService',
        error: e,
        data: {'path': filePath},
      );
    }
  }

  /// 获取图片格式
  String _getImageFormat(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// 获取下一个图片索引
  Future<int> _getNextImageIndex(String workId) async {
    return await _repository.getNextIndex(workId);
  }

  /// 检查图片是否被重新排序
  bool _haveImagesBeenReordered(
      List<WorkImage> oldImages, List<WorkImage> newImages) {
    // 没有足够的图片，不算重排
    if (oldImages.isEmpty || newImages.isEmpty) {
      return false;
    }

    // 创建映射以快速查找旧图片的索引
    final oldImageMap = {for (var img in oldImages) img.id: img.index};

    // 特别检查第一张图是否变了位置
    if (oldImages.isNotEmpty && newImages.isNotEmpty) {
      if (oldImages[0].id != newImages[0].id) {
        return true; // 首图变了
      }
    }

    // 检查前几张图的顺序是否变化
    final checkCount = math.min(oldImages.length, newImages.length);

    // 检查其他图片的顺序
    for (int i = 0; i < checkCount; i++) {
      final newImg = newImages[i];
      // 如果新顺序中的图片在旧数据中有不同的索引，说明发生了重排
      if (oldImageMap.containsKey(newImg.id) && oldImageMap[newImg.id] != i) {
        return true;
      }
    }

    return false;
  }

  /// 在文件保存后验证所有已处理文件
  Future<void> _verifyAllProcessedFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        await _ensureFileWritten(path);
      } catch (e) {
        AppLogger.warning(
          '验证文件失败',
          tag: 'WorkImageService',
          error: e,
          data: {'path': path},
        );
      }
    }
  }

  /// 验证封面文件是否存在，如果不存在则重新生成
  Future<bool> _verifyCoverExists(String workId) async {
    final coverPath = _storage.getWorkCoverImportedPath(workId);
    final coverExists = await _storage.verifyWorkImageExists(coverPath);

    AppLogger.debug('验证封面文件', tag: 'WorkImageService', data: {
      'workId': workId,
      'coverPath': coverPath,
      'exists': coverExists
    });

    // 如果封面不存在，找出当前的第一张图并重新生成封面
    if (!coverExists) {
      try {
        final images = await _repository.getAllByWorkId(workId);
        if (images.isNotEmpty) {
          AppLogger.warning('封面文件丢失，重新生成',
              tag: 'WorkImageService',
              data: {'workId': workId, 'firstImageId': images[0].id});
          await updateCover(workId, images[0].id);
          return true;
        }
      } catch (e, stack) {
        AppLogger.error('验证并重新生成封面失败',
            tag: 'WorkImageService',
            error: e,
            stackTrace: stack,
            data: {'workId': workId});
      }
      return false;
    }

    return true;
  }
}
