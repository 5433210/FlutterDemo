import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../domain/models/work/work_entity.dart';
import '../../../domain/models/work/work_filter.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/repository_providers.dart';
import '../../../utils/path_helper.dart';
import './service_errors.dart';
import './work_image_service.dart';

/// Work Service Provider
final workServiceProvider = Provider<WorkService>((ref) {
  return WorkService(
    repository: ref.watch(workRepositoryProvider),
    imageService: ref.watch(workImageServiceProvider),
  );
});

/// Work Service Implementation
class WorkService with WorkServiceErrorHandler {
  final WorkRepository _repository;
  final WorkImageService _imageService;

  WorkService({
    required WorkRepository repository,
    required WorkImageService imageService,
  })  : _repository = repository,
        _imageService = imageService;

  /// Count works
  Future<int> count(WorkFilter? filter) async {
    return handleOperation(
      'count',
      () => _repository.count(filter),
      data: {'filter': filter?.toString()},
    );
  }

  /// Delete work and its images
  Future<void> deleteWork(String workId) async {
    return handleOperation(
      'deleteWork',
      () async {
        // 先删除封面缩略图
        final coverPath = await PathHelper.getWorkCoverThumbnailPath(workId);
        if (await PathHelper.isFileExists(coverPath)) {
          await File(coverPath).delete();
        }

        // 删除作品及其图片
        await _repository.delete(workId);
        await _imageService.cleanupWorkImages(workId);
      },
      data: {'workId': workId},
    );
  }

  /// Get all works
  Future<List<WorkEntity>> getAllWorks() async {
    return handleOperation(
      'getAllWorks',
      () => _repository.getAll(),
    );
  }

  /// Get work entity with all related data
  Future<WorkEntity?> getWorkEntity(String id) async {
    return handleOperation(
      'getWorkEntity',
      () => _repository.get(id),
      data: {'workId': id},
    );
  }

  /// Get works by tags
  Future<List<WorkEntity>> getWorksByTags(Set<String> tags) async {
    return handleOperation(
      'getWorksByTags',
      () => _repository.getByTags(tags),
      data: {'tags': tags.toList()},
    );
  }

  /// Get work thumbnail path
  Future<String?> getWorkThumbnail(String workId) async {
    return handleOperation(
      'getWorkThumbnail',
      () async {
        final thumbnailPath =
            await PathHelper.getWorkCoverThumbnailPath(workId);

        // 检查缩略图是否存在
        final file = File(thumbnailPath);
        if (await file.exists()) {
          // 检查文件是否为空
          if (await file.length() == 0) {
            await PathHelper.createPlaceholderImage(thumbnailPath);
          }
          return thumbnailPath;
        } else {
          // 如果文件不存在但目录存在，创建占位图
          final dir = Directory(path.dirname(thumbnailPath));
          if (await dir.exists()) {
            await PathHelper.createPlaceholderImage(thumbnailPath);
            return thumbnailPath;
          }
        }
        return null;
      },
      data: {'workId': workId},
    );
  }

  /// Import work with images
  Future<WorkEntity> importWork(List<File> files, WorkEntity work) async {
    return handleOperation(
      'importWork',
      () async {
        // 验证输入
        if (files.isEmpty) throw ArgumentError('图片文件不能为空');

        // 处理图片
        final images =
            await _imageService.processImagesInBatches(work.id, files);

        // 确保生成并保存封面缩略图
        if (files.isNotEmpty) {
          final coverThumb = await _imageService.createThumbnail(files[0]);
          final coverPath = await PathHelper.getWorkCoverThumbnailPath(work.id);
          await coverThumb.copy(coverPath);
          AppLogger.debug('已生成作品封面缩略图',
              tag: 'WorkService',
              data: {'workId': work.id, 'coverPath': coverPath});
        }

        // 更新作品信息
        final updatedWork = work.copyWith(
          imageCount: images.length,
          updateTime: DateTime.now(),
        );

        // 保存到数据库
        return await _repository.create(updatedWork);
      },
      data: {'workId': work.id, 'fileCount': files.length},
    );
  }

  /// Query works with filter
  Future<List<WorkEntity>> queryWorks(WorkFilter filter) async {
    return handleOperation(
      'queryWorks',
      () async {
        AppLogger.debug(
          '开始查询作品',
          tag: 'WorkService',
          data: {
            'filter': {
              'style': filter.style?.name,
              'tool': filter.tool?.name,
              'keyword': filter.keyword,
              'tags': filter.tags.toList(),
              'sortOption': {
                'field': filter.sortOption.field.name,
                'descending': filter.sortOption.descending,
              },
            },
          },
        );

        final results = await _repository.query(filter);

        AppLogger.debug(
          '查询作品完成',
          tag: 'WorkService',
          data: {
            'resultCount': results.length,
          },
        );

        return results;
      },
      data: {'filter': filter.toString()},
    );
  }

  /// Search works
  Future<List<WorkEntity>> searchWorks(String query, {int? limit}) async {
    return handleOperation(
      'searchWorks',
      () => _repository.search(query, limit: limit),
      data: {'query': query, 'limit': limit},
    );
  }

  /// Update complete work entity
  Future<WorkEntity> updateWorkEntity(WorkEntity work) async {
    return handleOperation(
      'updateWorkEntity',
      () async {
        final now = DateTime.now();
        final updatedWork = work.copyWith(
          updateTime: now,
        );

        return await _repository.save(updatedWork);
      },
      data: {'workId': work.id},
    );
  }
}
