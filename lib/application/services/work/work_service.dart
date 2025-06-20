import 'dart:io';

import '../../../domain/models/common/paginated_result.dart';
import '../../../domain/models/work/work_entity.dart';
import '../../../domain/models/work/work_filter.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../character/character_service.dart';
import './service_errors.dart';
import './work_image_service.dart';

/// 作品服务
class WorkService with WorkServiceErrorHandler {
  final WorkRepository _repository;
  final WorkImageService _imageService;
  final CharacterService _characterService;

  final WorkImageRepository _workImageRepository;
  final CharacterRepository _characterRepository;

  WorkService({
    required WorkRepository repository,
    required WorkImageService imageService,
    required CharacterService characterService,
    required WorkImageRepository workImageRepository,
    required CharacterRepository characterRepository,
  })  : _repository = repository,
        _imageService = imageService,
        _characterService = characterService,
        _workImageRepository = workImageRepository,
        _characterRepository = characterRepository;

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
        AppLogger.debug(
          '开始删除作品及关联数据',
          tag: 'WorkService',
          data: {'workId': workId},
        );

        // 1. 先查找并删除所有关联的集字数据
        try {
          final characters = await _characterRepository.findByWorkId(workId);
          if (characters.isNotEmpty) {
            final characterIds = characters.map((c) => c.id).toList();
            AppLogger.debug(
              '删除作品关联的集字数据',
              tag: 'WorkService',
              data: {
                'workId': workId,
                'characterCount': characters.length,
                'characterIds': characterIds,
              },
            );

            // 批量删除集字数据（包括数据库记录、图片文件和缓存）
            await _characterService.deleteBatchCharacters(characterIds);

            AppLogger.info(
              '成功删除作品关联的集字数据',
              tag: 'WorkService',
              data: {
                'workId': workId,
                'deletedCharacterCount': characters.length,
              },
            );
          } else {
            AppLogger.debug(
              '作品无关联集字数据',
              tag: 'WorkService',
              data: {'workId': workId},
            );
          }
        } catch (e) {
          AppLogger.error(
            '删除作品关联集字数据失败',
            tag: 'WorkService',
            error: e,
            data: {'workId': workId},
          );
          // 继续执行作品删除，不因集字删除失败而中断
        }

        // 2. 删除作品数据库记录
        await _repository.delete(workId);

        // 3. 清理作品图片文件
        await _imageService.cleanupWorkImages(workId);

        AppLogger.info(
          '成功删除作品及所有关联数据',
          tag: 'WorkService',
          data: {'workId': workId},
        );
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
        // 获取基本作品数据
        final work = await _repository.get(workId);
        if (work != null) {
          // 加载作品图片和字符数据
          final images = await _workImageRepository.getAllByWorkId(workId);
          // 从作品关联的字符ID列表中获取字符数据
          final characters = await _characterRepository
              .getAll(); // 暂时获取所有字符，稍后需要实现按workId筛选的方法
          final workCharacters =
              characters.where((c) => c.workId == workId).toList();

          AppLogger.debug(
            'Found characters for work',
            tag: 'WorkService',
            data: {
              'workId': workId,
              'totalChars': characters.length,
              'workChars': workCharacters.length,
            },
          );

          AppLogger.debug(
            'Loading work with all relations',
            tag: 'WorkService',
            data: {
              'workId': workId,
              'imageCount': images.length,
              'imagePaths': images.map((img) => img.path).toList(),
              'collectedCharsCount': characters.length,
              'collectedCharIds': characters.map((c) => c.id).toList(),
            },
          );

          // 复制作品实体，包含图片和字符数据
          return work.copyWith(
            images: images,
            collectedChars: workCharacters,
          );
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
  Future<WorkEntity> importWork(
    List<File> files,
    WorkEntity work, {
    Map<String, String>? libraryItemIds, // filePath -> libraryItemId 的映射
  }) async {
    return handleOperation(
      'importWork',
      () async {
        AppLogger.debug(
          '导入作品',
          tag: 'WorkService',
          data: {
            'fileCount': files.length,
            'work': work.toJson(),
            'libraryItemIdsCount': libraryItemIds?.length ?? 0,
          },
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

        // 处理图片导入（包括生成封面），传递libraryItemIds映射
        final imagesImported = await _imageService.processImport(
          work.id,
          files,
          libraryItemIds: libraryItemIds,
        );

        // 注意：不需要在这里显式调用updateCover，
        // processImport内部的saveChanges已经处理了封面生成

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
              'style': filter.style,
              'tool': filter.tool,
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

  /// 分页查询作品
  Future<PaginatedResult<WorkEntity>> queryWorksPaginated({
    required WorkFilter filter,
    required int page,
    required int pageSize,
  }) async {
    return handleOperation(
      'queryWorksPaginated',
      () async {
        AppLogger.debug(
          '开始分页查询作品',
          tag: 'WorkService',
          data: {
            'filter': {
              'style': filter.style,
              'tool': filter.tool,
              'keyword': filter.keyword,
              'tags': filter.tags.toList(),
              'sortOption': {
                'field': filter.sortOption.field.name,
                'descending': filter.sortOption.descending,
              },
            },
            'page': page,
            'pageSize': pageSize,
          },
        );

        // 添加分页参数到过滤器
        final paginatedFilter = filter.copyWith(
          limit: pageSize,
          offset: (page - 1) * pageSize,
        );

        // 查询当前页数据
        final results = await _repository.query(paginatedFilter);

        // 获取总记录数
        final totalCount = await _repository.count(filter);

        AppLogger.debug(
          '分页查询作品完成',
          tag: 'WorkService',
          data: {
            'resultCount': results.length,
            'totalCount': totalCount,
            'page': page,
            'pageSize': pageSize,
          },
        );

        return PaginatedResult<WorkEntity>(
          items: results,
          totalCount: totalCount,
          currentPage: page,
          pageSize: pageSize,
        );
      },
      data: {
        'filter': filter.toString(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 切换作品收藏状态
  Future<WorkEntity> toggleFavorite(String workId) async {
    return handleOperation(
      'toggleFavorite',
      () async {
        // 获取作品
        final work = await getWork(workId);
        if (work == null) {
          throw Exception('作品不存在: $workId');
        }

        // 切换收藏状态
        final updatedWork = work.toggleFavorite();

        // 保存更改
        return await _repository.save(updatedWork);
      },
      data: {'workId': workId},
    );
  }

  /// 更新作品实体
  Future<WorkEntity> updateWorkEntity(WorkEntity work) async {
    return handleOperation(
      'updateWorkEntity',
      () async {
        AppLogger.debug('开始更新作品信息', tag: 'WorkService', data: {
          'workId': work.id,
          'imageCount': work.images.length,
          'hasImages': work.images.isNotEmpty,
        });

        // 更新基本信息
        final updatedWork = work.copyWith(
          updateTime: DateTime.now(),
          imageCount: work.images.length,
        );

        // 保存作品信息
        return await _repository.save(updatedWork);
      },
      data: {'workId': work.id},
    );
  }
}
