import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../presentation/viewmodels/character_collection_viewmodel.dart';
import '../../../utils/image/image_cache_util.dart';
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
  Future<CharacterEntity> extractCharacter(
      String workId,
      String pageId,
      Rect region,
      double rotation,
      ProcessingOptions options,
      Uint8List imageData,
      String character,
      {ProcessingResult? processingResult}) async {
    try {
      AppLogger.debug('开始提取字符区域', data: {
        'workId': workId,
        'pageId': pageId,
        'region':
            '${region.left},${region.top},${region.width},${region.height}',
        'imageDataLength': imageData.length,
        'hasProcessingResult': processingResult != null,
      });

      // 如果提供了处理结果，就直接使用，否则处理图像
      final result = processingResult ??
          await _imageProcessor.processCharacterRegion(
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
        character: character,
        isModified: false, // 新创建的字符区域默认为未修改
        rotation: rotation,
      );

      AppLogger.debug('字符区域创建完成', data: {
        'regionId': characterRegion.id,
      });

      // 保存字符和图像
      final characterEntity = await _persistenceService.saveCharacter(
        characterRegion,
        result,
        workId,
      );
      AppLogger.debug('字符和图像保存完成', data: {'characterId': characterEntity.id});

      // 缓存图像数据
      final id = characterEntity.id;
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

      return characterEntity.copyWith(workId: workId);
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
      print('CharacterService - 获取缩略图路径: $characterId');
      // 从持久化服务获取缩略图路径
      final path = await _persistenceService.getThumbnailPath(characterId);

      // 检查缩略图文件是否存在
      final file = File(path);
      final exists = await file.exists();

      // 如果缩略图不存在，尝试从原始图像生成
      if (!exists) {
        print('CharacterService - 缩略图不存在，尝试重新生成: $path');
        try {
          // 获取字符详情
          final character = await _repository.findById(characterId);
          if (character == null) {
            print('CharacterService - 字符不存在，无法重新生成缩略图: $characterId');
            return path; // 即使文件不存在，也返回路径供上层处理
          }

          // 获取原始图像数据
          final originalData =
              await getCharacterImage(characterId, CharacterImageType.original);
          if (originalData == null) {
            print('CharacterService - 原始图像数据为空，无法重新生成缩略图');
            return path;
          }

          // 生成新的缩略图
          // 将原始图像解码为img.Image
          final image = img.decodeImage(originalData);
          if (image == null) {
            print('CharacterService - 无法解码原始图像');
            return path;
          }

          // 生成缩略图
          final thumbnail = img.copyResize(image,
              width: 100,
              height: 100,
              interpolation: img.Interpolation.average);

          // 编码为JPEG数据
          final thumbnailData =
              Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));

          // 保存到文件系统 - 直接写入文件而不是调用可能不存在的服务方法
          await file.create(recursive: true);
          await file.writeAsBytes(thumbnailData);

          print('CharacterService - 缩略图重新生成成功: $path');
          return path;
        } catch (regenerateError) {
          print('CharacterService - 重新生成缩略图失败: $regenerateError');
          AppLogger.error('重新生成缩略图失败',
              error: regenerateError, data: {'characterId': characterId});
          return path; // 即使重新生成失败，也返回路径供上层处理
        }
      }

      return path;
    } catch (e) {
      AppLogger.error('获取缩略图路径失败',
          error: e, data: {'characterId': characterId});
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
      // Log update attempt with image info
      AppLogger.debug('更新字符开始', data: {
        'characterId': id,
        'character': character,
        'hasNewResult': newResult != null,
        'imageDataSize': newResult?.originalCrop.length,
      });

      // Get the thumbnail path before update to clean up cache after
      String? thumbnailPath;
      try {
        thumbnailPath = await _persistenceService.getThumbnailPath(id);
      } catch (e) {
        AppLogger.warning('获取缩略图路径失败，无法清除缓存', error: e);
      }

      // 更新字符和处理结果
      await _persistenceService.updateCharacter(
        id,
        region.copyWith(character: character),
        newResult,
        character,
      );

      // Explicitly invalidate any cached images
      await Future.wait([
        _cacheManager.invalidate('${id}_original'),
        _cacheManager.invalidate('${id}_binary'),
        _cacheManager.invalidate('${id}_thumbnail'),
      ]);

      // Clear the UI image cache of the thumbnail file
      if (thumbnailPath != null) {
        ImageCacheUtil.evictImage(thumbnailPath);
      }

      // Clear any memory image caches if we have a new result
      if (newResult != null) {
        if (newResult.thumbnail.isNotEmpty) {
          ImageCacheUtil.evictMemoryImage(newResult.thumbnail);
        }
        if (newResult.originalCrop.isNotEmpty) {
          ImageCacheUtil.evictMemoryImage(newResult.originalCrop);
        }
      }

      AppLogger.debug('更新字符完成，缓存已失效', data: {'characterId': id});
    } catch (e) {
      AppLogger.error('更新字符失败',
          error: e, data: {'characterId': id, 'character': character});
      rethrow;
    }
  }
}
