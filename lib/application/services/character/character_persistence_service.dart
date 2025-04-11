import 'dart:io';
import 'dart:typed_data';

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../storage/cache_manager.dart';
import '../storage/character_storage_service.dart';

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

  // 保存字符数据
  Future<CharacterEntity> createCharacter(
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
      print('保存字符失败: $e');
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

  // 更新字符数据
  Future<void> updateCharacter(String id, CharacterRegion region,
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
