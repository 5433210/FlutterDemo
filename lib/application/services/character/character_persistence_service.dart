import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../providers/repository_providers.dart';
import '../storage/cache_manager.dart';
import '../storage/character_storage_service.dart';

final characterPersistenceServiceProvider =
    Provider<CharacterPersistenceService>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final storageService = ref.watch(characterStorageServiceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);

  return CharacterPersistenceService(
    repository: repository,
    storageService: storageService,
    cacheManager: cacheManager,
  );
});

class CharacterPersistenceService {
  final CharacterRepository _repository;
  final CharacterStorageService _storageService;
  final CacheManager _cacheManager;

  CharacterPersistenceService({
    required CharacterRepository repository,
    required CharacterStorageService storageService,
    required CacheManager cacheManager,
  })  : _repository = repository,
        _storageService = storageService,
        _cacheManager = cacheManager;

  /// 从字符区域创建字符实体
  Future<CharacterEntity> createFromRegion(
    CharacterRegion region,
    Uint8List originalImage,
    Uint8List binaryImage,
    Uint8List thumbnail,
    String? svgOutline,
  ) async {
    try {
      // 保存图片文件
      await _storageService.saveOriginalImage(region.id, originalImage);
      await _storageService.saveBinaryImage(region.id, binaryImage);
      await _storageService.saveThumbnail(region.id, thumbnail);

      if (svgOutline != null) {
        await _storageService.saveSvgOutline(region.id, svgOutline);
      }

      // 创建实体并保存到数据库
      final entity = CharacterEntity.create(
        workId: 'temp', // TODO: 替换为实际的workId，暂时使用临时ID以满足外键约束
        pageId: region.pageId,
        region: region,
        character: region.character,
      );

      return await _repository.create(entity);
    } catch (e) {
      print('从区域创建字符实体失败: $e');
      rethrow;
    }
  }

  // 删除字符数据
  Future<void> deleteCharacter(String id) async {
    try {
      await _repository.delete(id);
      _cacheManager.invalidate(id);
    } catch (e) {
      print('删除字符失败: $e');
      rethrow;
    }
  }

  /// 复制字形
  Future<CharacterEntity> duplicateCharacter(String id, {String? newId}) async {
    try {
      // 获取原始字符
      final original = await _repository.findById(id);
      if (original == null) {
        throw Exception('Character not found: $id');
      }

      final generatedId =
          newId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // 复制文件
      final originalImageData =
          await getCharacterImage(id, CharacterImageType.original);
      final binaryImageData =
          await getCharacterImage(id, CharacterImageType.binary);
      final thumbnailData =
          await getCharacterImage(id, CharacterImageType.thumbnail);

      if (originalImageData == null ||
          binaryImageData == null ||
          thumbnailData == null) {
        throw Exception('Failed to load character images');
      }

      await _storageService.saveOriginalImage(generatedId, originalImageData);
      await _storageService.saveBinaryImage(generatedId, binaryImageData);
      await _storageService.saveThumbnail(generatedId, thumbnailData);

      // 创建新实体
      final now = DateTime.now();
      final duplicated = original.copyWith(
        id: generatedId,
        createTime: now,
        updateTime: now,
        isFavorite: false,
        region: original.region.copyWith(
          id: generatedId,
          createTime: now,
          updateTime: now,
        ),
      );

      // 保存到数据库
      await _repository.create(duplicated);
      return duplicated;
    } catch (e) {
      print('复制字符失败: $e');
      rethrow;
    }
  }

  /// 获取字符图像数据
  Future<Uint8List?> getCharacterImage(
      String id, CharacterImageType type) async {
    try {
      String? filePath;
      switch (type) {
        case CharacterImageType.original:
          filePath = await _storageService.getOriginalImagePath(id);
          break;
        case CharacterImageType.binary:
          filePath = await _storageService.getBinaryImagePath(id);
          break;
        case CharacterImageType.thumbnail:
          filePath = await _storageService.getThumbnailPath(id);
          break;
      }

      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }

      return null;
    } catch (e) {
      print('获取字符图像失败: $e');
      rethrow;
    }
  }

  /// 获取字符缩略图路径
  Future<String> getThumbnailPath(String id) async {
    return await _storageService.getThumbnailPath(id);
  }

  // 保存字符数据
  Future<CharacterEntity> saveCharacter(
      CharacterRegion region, ProcessingResult result, String workId) async {
    try {
      await _storageService.saveOriginalImage(region.id, result.originalCrop);
      await _storageService.saveBinaryImage(region.id, result.binaryImage);
      await _storageService.saveThumbnail(region.id, result.thumbnail);

      if (result.svgOutline != null) {
        await _storageService.saveSvgOutline(region.id, result.svgOutline!);
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
      print('保存字符失败: $e');
      rethrow;
    }
  }

  // 更新字符数据
  Future<void> updateCharacter(String id, CharacterRegion region,
      ProcessingResult? newResult, String character) async {
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
        bool hasValidThumbnail = newResult.thumbnail.isNotEmpty;

        AppLogger.debug('更新字符图像文件检查', data: {
          'characterId': id,
          'hasValidOriginal': hasValidOriginal,
          'hasValidBinary': hasValidBinary,
          'hasValidThumbnail': hasValidThumbnail,
          'originalLength': newResult.originalCrop.length,
          'binaryLength': newResult.binaryImage.length,
          'thumbnailLength': newResult.thumbnail.length,
        });

        if (hasValidOriginal && hasValidBinary && hasValidThumbnail) {
          try {
            // Use await on each save operation to ensure they complete
            await _storageService.saveOriginalImage(id, newResult.originalCrop);
            await _storageService.saveBinaryImage(id, newResult.binaryImage);
            await _storageService.saveThumbnail(id, newResult.thumbnail);

            // Always save SVG outline if available, regardless of showContour setting
            if (newResult.svgOutline != null) {
              await _storageService.saveSvgOutline(id, newResult.svgOutline!);
              AppLogger.debug('字符SVG轮廓保存成功', data: {
                'characterId': id,
                'svgLength': newResult.svgOutline!.length,
              });
            } else {
              AppLogger.warning('处理结果中没有SVG轮廓数据', data: {'characterId': id});
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

      // 记录擦除路径数据状态
      if (updatedRegion.erasePoints != null) {
        AppLogger.debug('字符数据包含擦除路径', data: {
          'characterId': id,
          'erasePathsCount': updatedRegion.erasePoints!.length,
        });
      }

      // 更新区域数据
      await _repository.save(updatedEntity);

      // 清除缓存
      _cacheManager.invalidate(id);

      // Also invalidate related cache keys
      _cacheManager.invalidate('${id}_original');
      _cacheManager.invalidate('${id}_binary');
      _cacheManager.invalidate('${id}_thumbnail');

      AppLogger.debug('字符数据更新完成，缓存已清除', data: {'characterId': id});
    } catch (e) {
      AppLogger.error('更新字符失败', error: e, data: {'characterId': id});
      throw Exception('更新字符失败: $e');
    }
  }
}
