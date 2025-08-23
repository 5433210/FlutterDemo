import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/cache/interfaces/i_cache.dart';
import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/cache_providers.dart';
import '../../../presentation/viewmodels/states/character_grid_state.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../image/character_image_processor.dart';
import '../storage/character_storage_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final imageProcessor = ref.watch(characterImageProcessorProvider);
  final binaryCache = ref.watch(tieredImageCacheProvider);
  final storageService = ref.watch(characterStorageServiceProvider);
  final imageCacheService = ref.watch(imageCacheServiceProvider);

  return CharacterService(
    repository: repository,
    imageProcessor: imageProcessor,
    storageService: storageService,
    binaryCache: binaryCache,
    imageCacheService: imageCacheService,
  );
});

class CharacterService {
  final CharacterRepository _repository;
  final CharacterImageProcessor _imageProcessor;
  final CharacterStorageService _storageService;
  final ICache<String, Uint8List> _binaryCache;
  final ImageCacheService _imageCacheService;

  CharacterService({
    required CharacterRepository repository,
    required CharacterImageProcessor imageProcessor,
    required CharacterStorageService storageService,
    required ICache<String, Uint8List> binaryCache,
    required ImageCacheService imageCacheService,
  })  : _repository = repository,
        _imageProcessor = imageProcessor,
        _storageService = storageService,
        _binaryCache = binaryCache,
        _imageCacheService = imageCacheService;

  /// Add a tag to a character
  Future<bool> addTag(String id, String tag) async {
    try {
      // Validate tag - non-empty and trimmed
      final trimmedTag = tag.trim();
      if (trimmedTag.isEmpty) {
        return false;
      }

      // Get character entity
      final character = await _repository.findById(id);
      if (character == null) {
        AppLogger.error('Failed to add tag: character not found',
            data: {'characterId': id});
        return false;
      }

      // Check if tag already exists
      if (character.tags.contains(trimmedTag)) {
        // Tag already exists, no need to add
        return true;
      }

      // Add the tag and save
      final updatedTags = [...character.tags, trimmedTag];
      final updatedCharacter = character.copyWith(tags: updatedTags);
      await _repository.save(updatedCharacter);

      AppLogger.info('Tag added to character',
          data: {'characterId': id, 'tag': trimmedTag});
      return true;
    } catch (e) {
      AppLogger.error('Failed to add tag',
          error: e, data: {'characterId': id, 'tag': tag});
      return false;
    }
  }

  /// 根据页面ID获取字符列表
  Future<List<CharacterEntity>> getCharactersByPageId(String pageId) async {
    try {
      final filter = CharacterFilter(pageId: pageId);
      final characters = await _repository.query(filter);
      AppLogger.debug('获取页面字符', data: {
        'pageId': pageId,
        'characterCount': characters.length,
      });
      return characters;
    } catch (e) {
      AppLogger.error('获取页面字符失败', error: e, data: {'pageId': pageId});
      return [];
    }
  }

  /// Clear character-specific image caches
  /// 
  /// This method clears all cache entries related to a specific character ID
  /// including binary cache, UI image cache, and Flutter image cache
  Future<void> clearCharacterImageCaches(String characterId) async {
    try {
      // Clear binary cache entries for this character
      await Future.wait([
        _binaryCache.invalidate(characterId),
        _binaryCache.invalidate('${characterId}_original'),
        _binaryCache.invalidate('${characterId}_binary'),
        _binaryCache.invalidate('${characterId}_thumbnail'),
        _binaryCache.invalidate('${characterId}_squareBinary'),
        _binaryCache.invalidate('${characterId}_squareTransparent'),
        _binaryCache.invalidate('${characterId}_outline'),
        _binaryCache.invalidate('${characterId}_squareOutline'),
        _binaryCache.invalidate('${characterId}_transparent'),
      ]);

      // Clear UI image cache entries for this character
      await _imageCacheService.clearCharacterImageCaches(characterId);

      // Clear specific file-based caches
      try {
        final imagePaths = await Future.wait([
          _storageService.getOriginalImagePath(characterId),
          _storageService.getBinaryImagePath(characterId),
          _storageService.getThumbnailPath(characterId),
          _storageService.getSquareBinaryPath(characterId),
          _storageService.getSquareTransparentPngPath(characterId),
          _storageService.getSvgOutlinePath(characterId),
          _storageService.getSquareSvgOutlinePath(characterId),
          _storageService.getTransparentPngPath(characterId),
        ]);

        // Evict each image path from Flutter cache
        for (final path in imagePaths) {
          _imageCacheService.evictImage(path);
        }
      } catch (e) {
        AppLogger.warning('清除文件路径缓存时出现错误', error: e, data: {
          'characterId': characterId,
        });
      }

      AppLogger.info('字符图像缓存已全部清除', data: {'characterId': characterId});
    } catch (e) {
      AppLogger.error('清除字符图像缓存失败', error: e, data: {'characterId': characterId});
      rethrow;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _binaryCache.clear();
    } catch (e) {
      AppLogger.error('清理缓存失败', error: e);
    }
  }

  /// 提取字符区域并处理
  Future<CharacterEntity> createCharacter(
    String workId,
    String pageId,
    Rect region,
    double rotation,
    ProcessingOptions options,
    Uint8List imageData,
    List<Map<String, dynamic>>? eraseData,
    String character,
  ) async {
    try {
      AppLogger.debug('开始提取字符区域', data: {
        'workId': workId,
        'pageId': pageId,
        'region':
            '${region.left},${region.top},${region.width},${region.height}',
        'imageDataLength': imageData.length,
      });

      // 添加详细的调试信息
      AppLogger.debug('传递给图像处理器的擦除数据', data: {
        'hasEraseData': eraseData != null,
        'eraseDataCount': eraseData?.length ?? 0,
        'eraseDataSample': eraseData?.take(1).toList(),
        'eraseDataFull': eraseData, // 完整的擦除数据
      });

      // 如果提供了处理结果，就直接使用，否则处理图像
      final result = await _imageProcessor.processForSave(
        imageData,
        region,
        options,
        eraseData, // 新创建的字符没有擦除点
        rotation,
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
        eraseData: eraseData,
        isModified: false, // 新创建的字符区域默认为未修改
        isSelected: false,
        rotation: rotation,
      );

      AppLogger.debug('字符区域创建完成', data: {
        'regionId': characterRegion.id,
      });

      // 保存字符和图像
      final characterEntity =
          await _saveCharacterWithImages(characterRegion, result, workId);

      AppLogger.debug('字符和图像保存完成', data: {'characterId': characterEntity.id});

      // 缓存图像数据
      final id = characterEntity.id;
      try {
        await Future.wait([
          _binaryCache.put('${id}_original', result.originalCrop),
          _binaryCache.put('${id}_binary', result.binaryImage),
          _binaryCache.put('${id}_thumbnail', result.thumbnail),
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

  /// 批量删除字符
  Future<void> deleteBatchCharacters(List<String> ids) async {
    try {
      // 批量删除数据库记录
      await _repository.deleteBatch(ids);

      // 批量删除文件
      for (final id in ids) {
        await _deleteCharacterImages(id);
        // 使用综合缓存清理方法
        await clearCharacterImageCaches(id);
      }
    } catch (e) {
      AppLogger.error('批量删除字符失败', error: e);
      rethrow;
    }
  }

  /// 删除字符
  Future<void> deleteCharacter(String id) async {
    try {
      // 删除数据库记录
      await _repository.delete(id);

      // 删除相关文件
      await _deleteCharacterImages(id);

      // 使用综合缓存清理方法
      await clearCharacterImageCaches(id);
    } catch (e) {
      AppLogger.error('删除字符失败', error: e);
      rethrow;
    }
  }

  /// 获取所有字符
  Future<List<CharacterEntity>> getAllCharacters() async {
    try {
      return await _repository.getAll();
    } catch (e) {
      AppLogger.error('获取所有字符失败', error: e);
      return [];
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
      AppLogger.error('获取字符详情失败', error: e);
      rethrow;
    }
  }

  /// 获取字符原始图像
  Future<Uint8List?> getCharacterImage(
      String id, CharacterImageType type) async {
    try {
      // 尝试从缓存获取
      final cacheKey = '${id}_${type.toString()}';
      final cached = await _binaryCache.get(cacheKey);
      if (cached != null) {
        return cached;
      }

      // 从文件系统获取
      final file = File(await getCharacterImagePath(id, type));
      if (await file.exists()) {
        final imageData = await file.readAsBytes();

        // 缓存结果
        if (imageData.isNotEmpty) {
          await _binaryCache.put(cacheKey, imageData);
        }

        return imageData;
      }

      return null;
    } catch (e) {
      AppLogger.error('获取字符图像失败', error: e);
      rethrow;
    }
  }

  Future<String> getCharacterImagePath(
      String characterId, CharacterImageType type) async {
    switch (type) {
      case CharacterImageType.original:
        return _storageService.getOriginalImagePath(characterId);
      case CharacterImageType.binary:
        return _storageService.getBinaryImagePath(characterId);
      case CharacterImageType.thumbnail:
        return _storageService.getThumbnailPath(characterId);
      case CharacterImageType.squareBinary:
        return _storageService.getSquareBinaryPath(characterId);
      case CharacterImageType.squareTransparent:
        return _storageService.getSquareTransparentPngPath(characterId);
      case CharacterImageType.outline:
        return _storageService.getSvgOutlinePath(characterId);
      case CharacterImageType.squareOutline:
        return _storageService.getSquareSvgOutlinePath(characterId);
      case CharacterImageType.transparent:
        return _storageService.getTransparentPngPath(characterId);
    }
  }

  /// 获取页面上的所有区域
  Future<List<CharacterRegion>> getPageRegions(String pageId) async {
    try {
      return await _repository.getRegionsByPageId(pageId);
    } catch (e) {
      AppLogger.error('获取页面区域失败', error: e);
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
        final thumbnailPath = await _storageService.getThumbnailPath(entity.id);

        return CharacterViewModel(
          id: entity.id,
          pageId: entity.pageId,
          character: entity.character,
          thumbnailPath: thumbnailPath,
          createdAt: entity.createTime,
          updatedAt: entity.updateTime,
          isFavorite: false,
        );
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      AppLogger.error('获取字符列表失败', error: e);
      rethrow;
    }
  }

  /// Remove a tag from a character
  Future<bool> removeTag(String id, String tag) async {
    try {
      // Get character entity
      final character = await _repository.findById(id);
      if (character == null) {
        AppLogger.error('Failed to remove tag: character not found',
            data: {'characterId': id});
        return false;
      }

      // Check if tag exists
      if (!character.tags.contains(tag)) {
        // Tag doesn't exist, no need to remove
        return true;
      }

      // Remove the tag and save
      final updatedTags = character.tags.where((t) => t != tag).toList();
      final updatedCharacter = character.copyWith(tags: updatedTags);
      await _repository.save(updatedCharacter);

      AppLogger.info('Tag removed from character',
          data: {'characterId': id, 'tag': tag});
      return true;
    } catch (e) {
      AppLogger.error('Failed to remove tag',
          error: e, data: {'characterId': id, 'tag': tag});
      return false;
    }
  }

  /// 搜索字符
  Future<List<CharacterViewModel>> searchCharacters(String query) async {
    try {
      final characters = await _repository.search(query);

      // 将结果转换为视图模型
      final futures = characters.map((entity) async {
        final thumbnailPath = await _storageService.getThumbnailPath(entity.id);

        return CharacterViewModel(
          id: entity.id,
          pageId: entity.pageId,
          character: entity.character,
          thumbnailPath: thumbnailPath,
          createdAt: entity.createTime,
          updatedAt: entity.updateTime,
          isFavorite: false,
        );
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      AppLogger.error('搜索字符失败', error: e);
      return [];
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(String id) async {
    try {
      // 获取字符实体
      final character = await _repository.findById(id);
      if (character == null) {
        AppLogger.error('切换收藏状态失败：找不到字符', data: {'characterId': id});
        return false;
      }

      // 切换收藏状态
      final updatedCharacter = character.copyWith(
        isFavorite: !character.isFavorite,
      );

      // 保存更新后的字符
      await _repository.save(updatedCharacter);

      AppLogger.info('字符收藏状态已更新',
          data: {'characterId': id, 'isFavorite': updatedCharacter.isFavorite});

      return true;
    } catch (e) {
      AppLogger.error('切换收藏状态失败', error: e, data: {'characterId': id});
      return false;
    }
  }

  /// 更新字符
  Future<void> updateCharacter(
    String id,
    CharacterRegion region,
    String character,
    ProcessingOptions options,
    Uint8List imageData,
  ) async {
    try {
      // Log update attempt with image info
      AppLogger.debug('更新字符开始', data: {
        'characterId': id,
        'character': character,
        'imageDataLength': imageData.length,
      });

      // 如果提供了处理结果，就直接使用，否则处理图像
      final result = await _imageProcessor.processForSave(
          imageData,
          region.rect,
          options,
          region.eraseData, // 新创建的字符没有擦除点
          region.rotation);

      // 更新字符和处理结果
      await _updateCharacterWithImages(
        id,
        region.copyWith(character: character),
        result,
        character,
      );

      // 🔧 NEW: 使用新的综合缓存清理方法，清除该字符ID相关的所有图像缓存
      await clearCharacterImageCaches(id);

      AppLogger.debug('更新字符完成，所有相关缓存已清除', data: {'characterId': id});
    } catch (e) {
      AppLogger.error('更新字符失败',
          error: e, data: {'characterId': id, 'character': character});
      rethrow;
    }
  }

  /// 删除字符图像文件 (从CharacterPersistenceService集成的功能)
  Future<void> _deleteCharacterImages(String id) async {
    try {
      await _storageService.deleteCharacterImage(id);
    } catch (e) {
      AppLogger.error('删除字符图像文件失败', error: e, data: {'characterId': id});
      rethrow;
    }
  }

  /// 保存字符数据及相关图像 (从CharacterPersistenceService集成的功能)
  Future<CharacterEntity> _saveCharacterWithImages(
      CharacterRegion region, ResultForSave result, String workId) async {
    try {
      // 保存原始长宽比图像
      await _storageService.saveOriginalImage(region.id, result.originalCrop);
      await _storageService.saveBinaryImage(region.id, result.binaryImage);

      // 保存正方形图像
      await _storageService.saveSquareBinary(region.id, result.squareBinary);
      await _storageService.saveThumbnail(region.id, result.thumbnail);

      // 保存SVG轮廓
      if (result.svgOutline != null) {
        await _storageService.saveSvgOutline(region.id, result.svgOutline!);
      }

      // 保存方形SVG轮廓
      if (result.squareSvgOutline != null) {
        await _storageService.saveSquareSvgOutline(
            region.id, result.squareSvgOutline!);
      }

      // 保存透明PNG
      if (result.transparentPng != null) {
        await _storageService.saveTransparentPng(
            region.id, result.transparentPng!);
      }

      // 保存方形透明PNG
      if (result.squareTransparentPng != null) {
        await _storageService.saveSquareTransparentPng(
            region.id, result.squareTransparentPng!);
      }

      // 创建实体并保存到数据库
      // 🔧 NEW: 在region中添加字符真实宽高比信息
      final regionWithAspectRatio = result.characterAspectRatio != null
          ? region.copyWith(characterId: region.id).addCharacterAspectRatio(result.characterAspectRatio!)
          : region.copyWith(characterId: region.id);
      
      final entity = CharacterEntity.create(
        workId: workId,
        pageId: region.pageId,
        region: regionWithAspectRatio,
        character: region.character,
      );

      AppLogger.debug('字符实体创建完成，包含宽高比信息', data: {
        'characterId': region.id,
        'characterAspectRatio': result.characterAspectRatio,
        'hasAspectRatio': result.characterAspectRatio != null,
      });

      return await _repository.create(entity);
    } catch (e) {
      AppLogger.error('保存字符失败', error: e);
      rethrow;
    }
  }

  /// 更新字符数据 (从CharacterPersistenceService集成的功能)
  Future<void> _updateCharacterWithImages(String id, CharacterRegion region,
      ResultForSave? newResult, String character) async {
    try {
      // 使用更新后的字符内容和时间戳
      final now = DateTime.now();
      var updatedRegion = region.copyWith(
        character: character,
        updateTime: now,
      );

      // 🔧 NEW: 如果有新的处理结果且包含字符宽高比，更新region中的宽高比信息
      if (newResult?.characterAspectRatio != null) {
        updatedRegion = updatedRegion.addCharacterAspectRatio(newResult!.characterAspectRatio!);
        AppLogger.debug('更新字符宽高比信息', data: {
          'characterId': id,
          'newAspectRatio': newResult.characterAspectRatio,
        });
      }

      // 如果有新的处理结果，则更新图像文件
      if (newResult != null) {
        // Explicitly check each component of the result
        bool hasValidOriginal = newResult.originalCrop.isNotEmpty;
        bool hasValidBinary = newResult.binaryImage.isNotEmpty;
        bool hasValidSquareBinary = newResult.squareBinary.isNotEmpty;
        bool hasValidThumbnail = newResult.thumbnail.isNotEmpty;

        AppLogger.debug('更新字符图像文件检查', data: {
          'characterId': id,
          'hasValidOriginal': hasValidOriginal,
          'hasValidBinary': hasValidBinary,
          'hasValidSquareBinary': hasValidSquareBinary,
          'hasValidThumbnail': hasValidThumbnail,
          'originalLength': newResult.originalCrop.length,
          'binaryLength': newResult.binaryImage.length,
          'thumbnailLength': newResult.thumbnail.length,
        });

        if (hasValidOriginal && hasValidBinary && hasValidThumbnail) {
          try {
            // 保存原始长宽比图像
            await _storageService.saveOriginalImage(id, newResult.originalCrop);
            await _storageService.saveBinaryImage(id, newResult.binaryImage);

            // 保存正方形图像
            await _storageService.saveSquareBinary(id, newResult.squareBinary);
            await _storageService.saveThumbnail(id, newResult.thumbnail);

            // 保存SVG轮廓
            if (newResult.svgOutline != null) {
              await _storageService.saveSvgOutline(id, newResult.svgOutline!);
            }

            // 保存方形SVG轮廓
            if (newResult.squareSvgOutline != null) {
              await _storageService.saveSquareSvgOutline(
                  id, newResult.squareSvgOutline!);
            }

            // 保存透明PNG
            if (newResult.transparentPng != null) {
              await _storageService.saveTransparentPng(
                  id, newResult.transparentPng!);
            }

            // 保存方形透明PNG
            if (newResult.squareTransparentPng != null) {
              await _storageService.saveSquareTransparentPng(
                  id, newResult.squareTransparentPng!);
            }

            AppLogger.debug('字符图像文件更新成功', data: {'characterId': id});
          } catch (e) {
            AppLogger.error('保存图像文件失败', error: e, data: {'characterId': id});
            throw Exception('保存图像文件失败: $e');
          }
        } else {
          AppLogger.warning('处理结果包含无效数据，跳过图像更新', data: {
            'characterId': id,
            'originalValid': hasValidOriginal,
            'binaryValid': hasValidBinary,
            'thumbnailValid': hasValidThumbnail,
          });
        }
      } else {
        AppLogger.debug('没有新的图像数据，保持原有图像', data: {'characterId': id});
      }

      // Update character entity in the database
      final characterEntity = await _repository.findById(id);
      if (characterEntity == null) {
        throw Exception('Character not found: $id');
      }

      final updatedEntity = characterEntity.copyWith(
        character: character,
        region: updatedRegion.copyWith(isModified: false, isSelected: false),
        updateTime: now,
      );

      // 更新区域数据
      await _repository.save(updatedEntity);
    } catch (e) {
      AppLogger.error('更新字符失败', error: e, data: {'characterId': id});
      throw Exception('更新字符失败: $e');
    }
  }
}
