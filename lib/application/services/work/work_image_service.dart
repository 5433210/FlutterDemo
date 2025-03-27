import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
        return await file.readAsBytes();
      },
      data: {
        'workId': workId,
        'pageId': pageId,
      },
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

        AppLogger.debug('封面图片检查', tag: 'WorkImageService', data: {
          'currentFirstImageId': existingFirstImageId,
          'newFirstImageId': newFirstImageId,
          'currentFirstImageIndex':
              existingImages.isNotEmpty ? existingImages[0].index : null,
          'newFirstImageIndex': images.isNotEmpty ? images[0].index : null,
          'imagesReordered': imagesReordered,
        });

        // 确定是否需要更新封面
        // 如果首图ID变了，或者图片顺序发生变化，都需要更新封面
        final shouldUpdateCover = newFirstImageId != null &&
            (existingFirstImageId != newFirstImageId ||
                imagesReordered ||
                existingFirstImageId == null);

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
            final usedPaths = savedImages
                .expand(
                    (img) => [img.path, img.originalPath, img.thumbnailPath])
                .toList();
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

        // 获取源图片路径并验证
        final importedPath = _storage.getImportedPath(workId, imageId);
        final sourceFile = File(importedPath);
        if (!await sourceFile.exists()) {
          AppLogger.error('源图片不存在', tag: 'WorkImageService', data: {
            'workId': workId,
            'imageId': imageId,
            'importedPath': importedPath
          });
          throw FileSystemException('源图片不存在', importedPath);
        }

        try {
          // 记录源图片信息，有助于调试
          final sourceSize = await sourceFile.length();
          AppLogger.debug('源图片文件信息', tag: 'WorkImageService', data: {
            'sourceSize': sourceSize,
            'sourcePath': importedPath,
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

  /// 确保封面文件存在
  Future<bool> _ensureCoverFilesExist(String workId) async {
    final coverPath = _storage.getWorkCoverImportedPath(workId);
    final thumbnailPath = _storage.getWorkCoverThumbnailPath(workId);

    // 尝试多次检查文件是否存在，允许文件系统操作完成
    for (int i = 0; i < 3; i++) {
      final coverExists = await File(coverPath).exists();
      final thumbnailExists = await File(thumbnailPath).exists();

      if (coverExists && thumbnailExists) {
        return true;
      }

      AppLogger.debug('等待封面文件写入完成', tag: 'WorkImageService', data: {
        'attempt': i + 1,
        'coverExists': coverExists,
        'thumbnailExists': thumbnailExists
      });

      // 等待文件系统操作完成
      await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
    }

    return false;
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
