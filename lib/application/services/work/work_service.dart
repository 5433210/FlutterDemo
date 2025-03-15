import 'dart:io';

import '../../../domain/models/work/work_entity.dart';
import '../../../domain/models/work/work_filter.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/storage/storage_interface.dart';
import './service_errors.dart';
import './work_image_service.dart';

/// 作品服务
class WorkService with WorkServiceErrorHandler {
  final WorkRepository _repository;
  final WorkImageService _imageService;
  final IStorage _storage;
  final WorkImageRepository _workImageRepository;

  WorkService({
    required WorkRepository repository,
    required WorkImageService imageService,
    required IStorage storage,
    required WorkImageRepository workImageRepository,
  })  : _repository = repository,
        _imageService = imageService,
        _storage = storage,
        _workImageRepository = workImageRepository;

  /// 统计作品数量
  Future<int> count(WorkFilter? filter) async {
    return handleOperation(
      'count',
      () => _repository.count(filter),
      data: {'filter': filter?.toString()},
    );
  }

  /// 删除作品
  Future<void> deleteWork(String workId) async {
    return handleOperation(
      'deleteWork',
      () async {
        // 删除作品及图片
        await _repository.delete(workId);
        await _imageService.cleanupWorkImages(workId);
      },
      data: {'workId': workId},
    );
  }

  /// 获取所有作品
  Future<List<WorkEntity>> getAllWorks() async {
    return handleOperation(
      'getAllWorks',
      () => _repository.getAll(),
    );
  }

  /// 获取作品实体
  Future<WorkEntity?> getWork(String workId) async {
    return handleOperation(
      'getWorkEntity',
      () async {
        final work = await _repository.get(workId);
        if (work != null) {
          // Load work images
          final images = await _workImageRepository.getAllByWorkId(workId);
          AppLogger.debug(
            'Loading work with images',
            tag: 'WorkService',
            data: {
              'workId': workId,
              'imageCount': images.length,
              'imagePaths': images.map((img) => img.path).toList(),
            },
          );
          return work.copyWith(images: images);
        }
        return work;
      },
      data: {'workId': workId},
    );
  }

  /// 按标签获取作品
  Future<List<WorkEntity>> getWorksByTags(Set<String> tags) async {
    return handleOperation(
      'getWorksByTags',
      () => _repository.getByTags(tags),
      data: {'tags': tags.toList()},
    );
  }

  /// 导入作品
  Future<WorkEntity> importWork(List<File> files, WorkEntity work) async {
    return handleOperation(
      'importWork',
      () async {
        AppLogger.debug(
          '导入作品',
          tag: 'WorkService',
          data: {'fileCount': files.length, 'work': work.toJson()},
        );

        // 验证输入
        if (files.isEmpty) throw ArgumentError('图片文件不能为空');

        // 更新作品信息
        final updatedWork = work.copyWith(
          imageCount: files.length,
          updateTime: DateTime.now(),
          createTime: DateTime.now(),
        );

        // 保存到数据库
        final savedWork = await _repository.create(updatedWork);

        // 处理图片导入（包括生成封面）
        final imagesImported =
            await _imageService.processImport(work.id, files);

        return savedWork.copyWith(images: imagesImported);
      },
      data: {'workId': work.id, 'fileCount': files.length},
    );
  }

  /// 查询作品
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
          data: {'resultCount': results.length},
        );

        return results;
      },
      data: {'filter': filter.toString()},
    );
  }

  /// 更新作品实体
  Future<WorkEntity> updateWorkEntity(WorkEntity work) async {
    return handleOperation(
      'updateWorkEntity',
      () async {
        final updatedWork = work.copyWith(
          updateTime: DateTime.now(),
        );
        return await _repository.save(updatedWork);
      },
      data: {'workId': work.id},
    );
  }
}
