import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_entity.dart';
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

/// 字符服务
///
/// 集字匹配模式说明：
///
/// 1. 词匹配优先模式（默认）：
///    - 输入"你好" → 先查找character字段精确等于"你好"的记录
///    - 如：character="你好世界" ✗, character="世界你好" ✗, character="你好" ✓
///    - 如果没有结果，回退到字符匹配
///
/// 2. 字符匹配模式：
///    - 输入"你好" → 查找包含"你"的记录 + 查找包含"好"的记录
///    - 然后去重合并所有结果
///
/// 3. 使用场景：
///    - 词匹配：适合查找完整词语，如"春风"、"明月"等
///    - 字符匹配：适合查找单个字符或获取更广泛的结果
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

  /// 清理缓存
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
        await _binaryCache.invalidate(id);
        await _binaryCache.invalidate('${id}_original');
        await _binaryCache.invalidate('${id}_binary');
        await _binaryCache.invalidate('${id}_thumbnail');
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

      // 清除缓存
      await _binaryCache.invalidate(id);
      await _binaryCache.invalidate('${id}_original');
      await _binaryCache.invalidate('${id}_binary');
      await _binaryCache.invalidate('${id}_thumbnail');
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

  /// 智能搜索字符 - 词匹配优先，字符匹配回退
  Future<List<CharacterViewModel>> searchCharactersWithMode(
    String query, {
    bool wordMatchingPriority = true,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      List<CharacterEntity> characters = [];

      if (wordMatchingPriority && query.length > 1) {
        // 词匹配优先模式：先尝试精确匹配（查找字符字段精确等于查询词的记录）
        AppLogger.info('尝试精确匹配', data: {'query': query});
        characters = await _repository.searchExact(query);

        AppLogger.info('精确匹配结果', data: {
          'query': query,
          'resultCount': characters.length,
          'results': characters.map((c) => c.character).take(5).toList(),
        });

        // 如果没有精确匹配结果，尝试智能分词搜索
        if (characters.isEmpty) {
          AppLogger.info('精确匹配无结果，尝试智能分词搜索');
          characters = await _searchWithSmartSegmentation(query);
        }
      } else {
        // 仅字符匹配模式：对单个字符使用精确匹配
        AppLogger.info('使用字符匹配模式', data: {'query': query});
        characters = await _searchByCharacters(query, exactMatch: true);
      }

      AppLogger.info('最终搜索结果', data: {
        'query': query,
        'mode': wordMatchingPriority ? 'word_priority' : 'character_only',
        'resultCount': characters.length,
      });

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
      AppLogger.error('智能搜索字符失败', error: e);
      return [];
    }
  }

  /// 智能分词搜索 - 处理混合词语的情况
  Future<List<CharacterEntity>> _searchWithSmartSegmentation(
      String query) async {
    final allResults = <CharacterEntity>[];
    final addedIds = <String>{};

    AppLogger.info('开始智能分词搜索', data: {
      'query': query,
      'queryLength': query.length,
    });

    // 先按空格分割，处理明确的词边界
    final spaceSeparatedParts =
        query.split(' ').where((part) => part.trim().isNotEmpty).toList();

    if (spaceSeparatedParts.length > 1) {
      AppLogger.info('检测到空格分隔的词语', data: {
        'parts': spaceSeparatedParts,
        'count': spaceSeparatedParts.length,
      });

      // 对每个空格分隔的部分进行词匹配
      for (final part in spaceSeparatedParts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isEmpty) continue;

        // 先尝试精确匹配这个部分
        final exactResults = await _repository.searchExact(trimmedPart);
        AppLogger.debug('部分精确匹配', data: {
          'part': trimmedPart,
          'resultCount': exactResults.length,
        });

        // 如果精确匹配有结果，添加到结果中
        if (exactResults.isNotEmpty) {
          for (final result in exactResults) {
            if (!addedIds.contains(result.id)) {
              allResults.add(result);
              addedIds.add(result.id);
            }
          }
        } else {
          // 如果精确匹配无结果，对这个部分进行字符匹配
          AppLogger.debug('部分精确匹配无结果，进行字符匹配', data: {'part': trimmedPart});
          final charResults = await _searchByCharacters(trimmedPart);
          for (final result in charResults) {
            if (!addedIds.contains(result.id)) {
              allResults.add(result);
              addedIds.add(result.id);
            }
          }
        }
      }
    } else {
      // 没有空格分隔，尝试其他分词策略
      AppLogger.info('单一词语，尝试其他分词策略');

      // 检测是否有中英文混合
      final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(query);
      final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(query);

      if (hasChinese && hasEnglish) {
        AppLogger.info('检测到中英文混合，进行智能分割');
        final segments = _segmentMixedText(query);

        for (final segment in segments) {
          if (segment.trim().isEmpty) continue;

          // 对每个分段先尝试精确匹配
          final exactResults = await _repository.searchExact(segment);
          if (exactResults.isNotEmpty) {
            for (final result in exactResults) {
              if (!addedIds.contains(result.id)) {
                allResults.add(result);
                addedIds.add(result.id);
              }
            }
          } else {
            // 精确匹配无结果，进行字符匹配
            final charResults = await _searchByCharacters(segment);
            for (final result in charResults) {
              if (!addedIds.contains(result.id)) {
                allResults.add(result);
                addedIds.add(result.id);
              }
            }
          }
        }
      } else {
        // 单一语言，先尝试精确匹配，再回退到字符匹配
        AppLogger.info('[NA_FIX_DEBUG] 单一语言，先尝试精确匹配', data: {'query': query});

        // 先尝试精确匹配整个查询词
        final exactResults = await _repository.searchExact(query);
        AppLogger.debug('[NA_FIX_DEBUG] 单一语言精确匹配结果', data: {
          'query': query,
          'resultCount': exactResults.length,
        });

        if (exactResults.isNotEmpty) {
          // 精确匹配有结果，使用精确匹配的结果
          AppLogger.info('[NA_FIX_DEBUG] 使用精确匹配结果', data: {
            'query': query,
            'resultCount': exactResults.length,
          });
          for (final result in exactResults) {
            if (!addedIds.contains(result.id)) {
              allResults.add(result);
              addedIds.add(result.id);
            }
          }
        } else {
          // 精确匹配无结果，回退到字符匹配
          AppLogger.info('[NA_FIX_DEBUG] 精确匹配无结果，回退到字符匹配',
              data: {'query': query});
          final charResults = await _searchByCharacters(query);
          allResults.addAll(charResults);
        }
      }
    }

    AppLogger.info('智能分词搜索完成', data: {
      'query': query,
      'totalResults': allResults.length,
      'uniqueResults': addedIds.length,
    });

    return allResults;
  }

  /// 分割中英文混合文本
  List<String> _segmentMixedText(String text) {
    final segments = <String>[];
    StringBuffer currentSegment = StringBuffer();
    bool? isCurrentChinese;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(char);
      final isEnglish = RegExp(r'[a-zA-Z]').hasMatch(char);

      if (isEnglish || isChinese) {
        // 如果当前字符类型与之前不同，结束当前分段
        if (isCurrentChinese != null && isCurrentChinese != isChinese) {
          if (currentSegment.isNotEmpty) {
            segments.add(currentSegment.toString());
            currentSegment.clear();
          }
        }

        currentSegment.write(char);
        isCurrentChinese = isChinese;
      } else {
        // 非字母和汉字的字符（如数字、标点等）
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment.toString());
          currentSegment.clear();
          isCurrentChinese = null;
        }

        // 对于空格等分隔符，直接跳过
        if (char.trim().isNotEmpty) {
          segments.add(char);
        }
      }
    }

    // 添加最后的分段
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment.toString());
    }

    return segments.where((s) => s.trim().isNotEmpty).toList();
  }

  /// 按字符逐个搜索
  Future<List<CharacterEntity>> _searchByCharacters(String query,
      {bool exactMatch = false}) async {
    final allResults = <CharacterEntity>[];
    final addedIds = <String>{};

    AppLogger.info('[NA_FIX_DEBUG] 开始字符逐个搜索', data: {
      'query': query,
      'queryLength': query.length,
      'exactMatch': exactMatch,
    });

    // 对每个字符进行搜索
    for (int i = 0; i < query.length; i++) {
      final char = query[i];

      // 跳过空白字符
      if (char.trim().isEmpty) continue;

      AppLogger.debug('[NA_FIX_DEBUG] 搜索单个字符',
          data: {'char': char, 'index': i, 'exactMatch': exactMatch});

      // 根据exactMatch参数选择搜索方式
      List<CharacterEntity> results;
      if (exactMatch) {
        // 精确匹配：只查找字符字段精确等于该字符的记录
        results = await _repository.searchExact(char);
        AppLogger.debug('[NA_FIX_DEBUG] 单个字符精确搜索结果', data: {
          'char': char,
          'resultCount': results.length,
        });
      } else {
        // 模糊匹配：查找包含该字符的所有记录
        results = await _repository.search(char);
        AppLogger.debug('[NA_FIX_DEBUG] 单个字符模糊搜索结果', data: {
          'char': char,
          'resultCount': results.length,
        });
      }

      // 去重添加结果
      for (final result in results) {
        if (!addedIds.contains(result.id)) {
          allResults.add(result);
          addedIds.add(result.id);
        }
      }
    }

    AppLogger.info('字符搜索完成', data: {
      'query': query,
      'totalResults': allResults.length,
      'uniqueResults': addedIds.length,
    });

    return allResults;
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

      // Explicitly invalidate any cached images
      await Future.wait([
        _binaryCache.invalidate(id),
        _binaryCache.invalidate('${id}_original'),
        _binaryCache.invalidate('${id}_binary'),
        _binaryCache.invalidate('${id}_thumbnail'),
      ]);

      final thumbnailPath = await _storageService.getThumbnailPath(id);
      // Clear the UI image cache of the thumbnail file
      _imageCacheService.evictImage(thumbnailPath);

      // Clear any memory image caches if we have a new result
      if (result.thumbnail.isNotEmpty) {
        _imageCacheService.evictMemoryImage(result.thumbnail);
      }
      if (result.originalCrop.isNotEmpty) {
        _imageCacheService.evictMemoryImage(result.originalCrop);
      }

      AppLogger.debug('更新字符完成，缓存已失效', data: {'characterId': id});
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
      final entity = CharacterEntity.create(
        workId: workId,
        pageId: region.pageId,
        region: region.copyWith(characterId: region.id),
        character: region.character,
      );

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
      final updatedRegion = region.copyWith(
        character: character,
        updateTime: now,
      );

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
