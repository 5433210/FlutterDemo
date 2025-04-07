import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../presentation/viewmodels/character_collection_viewmodel.dart';
import '../../providers/repository_providers.dart';
import '../image/character_image_processor.dart';
import '../storage/cache_manager.dart';
import 'character_persistence_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final imageProcessor = ref.watch(characterImageProcessorProvider);
  final persistenceService = ref.watch(characterPersistenceServiceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);

  return CharacterService(
    repository: repository,
    imageProcessor: imageProcessor,
    persistenceService: persistenceService,
    cacheManager: cacheManager,
  );
});

class CharacterService {
  final CharacterRepository _repository;
  final CharacterImageProcessor _imageProcessor;
  final CharacterPersistenceService _persistenceService;
  final CacheManager _cacheManager;

  CharacterService({
    required CharacterRepository repository,
    required CharacterImageProcessor imageProcessor,
    required CharacterPersistenceService persistenceService,
    required CacheManager cacheManager,
  })  : _repository = repository,
        _imageProcessor = imageProcessor,
        _persistenceService = persistenceService,
        _cacheManager = cacheManager;

  /// 应用擦除操作
  Future<ProcessingResult> applyErase(
    String characterId,
    CharacterRegion region,
    List<Offset> erasePoints,
    Uint8List originalImage,
  ) async {
    // 将擦除点转换为正确的格式
    final allErasePoints = <Map<String, dynamic>>[
      if (region.erasePoints != null)
        {'points': region.erasePoints!, 'brushSize': region.options.brushSize},
      {
        'points': erasePoints,
        'brushSize': region.options.brushSize,
      }
    ];

    // 重新处理图像
    final result = await _imageProcessor.processCharacterRegion(
      originalImage,
      region.rect,
      region.options,
      allErasePoints,
    );

    return result;
  }

  /// 清理缓存
  Future<void> clearCache() async {
    try {
      await _cacheManager.clear();
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }

  /// 批量删除字符
  Future<void> deleteBatchCharacters(List<String> ids) async {
    try {
      // 批量删除数据库记录
      await _repository.deleteBatch(ids);

      // 批量删除文件
      for (final id in ids) {
        await _persistenceService.deleteCharacter(id);
        _cacheManager.invalidate(id);
      }
    } catch (e) {
      print('批量删除字符失败: $e');
      rethrow;
    }
  }

  /// 删除字符
  Future<void> deleteCharacter(String id) async {
    try {
      // 删除数据库记录
      await _repository.delete(id);

      // 删除相关文件
      await _persistenceService.deleteCharacter(id);

      // 清除缓存
      _cacheManager.invalidate(id);
    } catch (e) {
      print('删除字符失败: $e');
      rethrow;
    }
  }

  /// 提取字符区域并处理
  Future<CharacterEntity> extractCharacter(String workId, String pageId,
      Rect region, ProcessingOptions options, Uint8List imageData,
      {bool isSaved = false}) async {
    try {
      AppLogger.debug('开始提取字符区域', data: {
        'workId': workId,
        'pageId': pageId,
        'region':
            '${region.left},${region.top},${region.width},${region.height}',
        'imageDataLength': imageData.length,
        'isSaved': isSaved,
      });
      // 处理字符区域
      final result = await _imageProcessor.processCharacterRegion(
        imageData,
        region,
        options,
        null, // 新创建的字符没有擦除点
      );
      AppLogger.debug('字符区域处理完成', data: {
        'originalCropLength': result.originalCrop.length,
        'binaryImageLength': result.binaryImage.length,
        'thumbnailLength': result.thumbnail.length
      });

      // 创建字符区域，设置保存状态
      final characterRegion = CharacterRegion.create(
        pageId: pageId,
        rect: region,
        options: options,
      ).copyWith(isSaved: isSaved);

      AppLogger.debug('字符区域创建完成', data: {
        'regionId': characterRegion.id,
        'isSaved': characterRegion.isSaved,
      });

      // 保存字符和图像
      final character = await _persistenceService.saveCharacter(
        characterRegion,
        result,
        workId,
      );
      AppLogger.debug('字符和图像保存完成', data: {'characterId': character.id});

      // 缓存图像数据
      final id = character.id;
      try {
        await Future.wait([
          _cacheManager.put('${id}_original', result.originalCrop),
          _cacheManager.put('${id}_binary', result.binaryImage),
          _cacheManager.put('${id}_thumbnail', result.thumbnail),
        ]);

        AppLogger.debug('图像数据缓存完成', data: {'characterId': id});
      } catch (e) {
        AppLogger.error('缓存图像数据失败', error: e, data: {'characterId': id});
      }

      return character.copyWith(workId: workId);
    } catch (e) {
      AppLogger.error('提取字符失败', error: e);
      rethrow;
    }
  }

  /// 获取字符详情
  Future<CharacterEntity?> getCharacterDetails(String id) async {
    try {
      final character = await _repository.findById(id);
      if (character == null) {
        throw Exception('Character not found: $id');
      }
      return character;
    } catch (e) {
      print('获取字符详情失败: $e');
      rethrow;
    }
  }

  /// 获取字符原始图像
  Future<Uint8List?> getCharacterImage(
      String id, CharacterImageType type) async {
    try {
      // 尝试从缓存获取
      final cacheKey = '${id}_${type.toString()}';
      final cached = await _cacheManager.get(cacheKey);
      if (cached != null) {
        return cached;
      }

      // 从仓库获取
      final imageData = await _persistenceService.getCharacterImage(id, type);

      // 缓存结果
      if (imageData != null) {
        await _cacheManager.put(cacheKey, imageData);
      }

      return imageData;
    } catch (e) {
      print('获取字符图像失败: $e');
      rethrow;
    }
  }

  /// 获取字符缩略图路径
  Future<String?> getCharacterThumbnailPath(String characterId) async {
    try {
      return await _persistenceService.getThumbnailPath(characterId);
    } catch (e) {
      AppLogger.error('获取缩略图路径失败', error: e);
      return null;
    }
  }

  /// 获取页面上的所有区域
  Future<List<CharacterRegion>> getPageRegions(String pageId) async {
    try {
      return await _repository.getRegionsByPageId(pageId);
    } catch (e) {
      print('获取页面区域失败: $e');
      return [];
    }
  }

  /// 获取作品中的字符列表
  Future<List<CharacterViewModel>> listCharacters(String workId) async {
    try {
      final characters = await _repository.findByWorkId(workId);

      // 将字符实体转换为视图模型
      final futures = characters.map((entity) async {
        // 构建缩略图路径
        final thumbnailPath =
            await _persistenceService.getThumbnailPath(entity.id);

        return CharacterViewModel(
          id: entity.id,
          pageId: entity.pageId,
          character: entity.character,
          rect: entity.region.rect,
          thumbnailPath: thumbnailPath,
          createdAt: entity.createTime,
          updatedAt: entity.updateTime,
          isFavorite: false,
        );
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      print('获取字符列表失败: $e');
      rethrow;
    }
  }

  /// 搜索字符
  Future<List<CharacterViewModel>> searchCharacters(String query) async {
    try {
      final characters = await _repository.search(query);

      // 将结果转换为视图模型
      final futures = characters.map((entity) async {
        final thumbnailPath =
            await _persistenceService.getThumbnailPath(entity.id);

        return CharacterViewModel(
          id: entity.id,
          pageId: entity.pageId,
          character: entity.character,
          rect: entity.region.rect,
          thumbnailPath: thumbnailPath,
          createdAt: entity.createTime,
          updatedAt: entity.updateTime,
          isFavorite: false,
        );
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      print('搜索字符失败: $e');
      return [];
    }
  }

  /// 更新字符
  Future<void> updateCharacter(
      String id, CharacterRegion region, String character,
      {ProcessingResult? newResult}) async {
    try {
      // 更新字符和处理结果
      await _persistenceService.updateCharacter(
        id,
        region.copyWith(character: character),
        newResult,
        character,
      );
    } catch (e) {
      print('更新字符失败: $e');
      rethrow;
    }
  }
}
