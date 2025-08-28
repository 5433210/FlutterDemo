import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../../domain/models/practice/practice_entity.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../domain/repositories/practice_repository.dart';
import '../../../utils/image_path_converter.dart';
import '../../repositories/practice_repository_impl.dart';
import '../storage/practice_storage_service.dart';

/// 字帖练习服务
class PracticeService {
  // 领域层仓库
  final PracticeRepository _repository;
  // 存储服务
  final PracticeStorageService _storageService;

  /// 构造函数
  const PracticeService({
    required PracticeRepository repository,
    required PracticeStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  /// 获取字帖练习数量
  Future<int> count(PracticeFilter? filter) {
    return _repository.count(filter);
  }

  /// 创建字帖练习
  Future<PracticeEntity> createPractice({
    required String title,
    List<String> tags = const [],
    String status = 'active',
  }) async {
    debugPrint('=== PracticeService.createPractice 开始 ===');
    debugPrint('参数: title=$title, tags=$tags, status=$status');

    final practice = PracticeEntity.create(
      title: title,
      tags: tags,
      status: status,
    );
    debugPrint('已创建实体，生成的ID=${practice.id}, 准备调用 _repository.save...');

    try {
      final result = await _repository.save(practice);
      debugPrint('_repository.save 调用成功，返回ID=${result.id}');
      debugPrint('=== PracticeService.createPractice 完成 ===');
      return result;
    } catch (e) {
      debugPrint('错误: createPractice 失败 - $e');
      rethrow;
    }
  }

  /// 删除字帖练习
  Future<void> deletePractice(String id) {
    return _repository.delete(id);
  }

  /// 批量删除字帖练习
  Future<void> deletePractices(List<String> ids) {
    return _repository.deleteMany(ids);
  }

  /// 复制字帖练习
  Future<PracticeEntity> duplicatePractice(String id) {
    return _repository.duplicate(id);
  }

  /// 获取所有字帖练习
  Future<List<PracticeEntity>> getAllPractices() {
    return _repository.getAll();
  }

  /// 获取所有标签
  Future<Set<String>> getAllTags() {
    return _repository.getAllTags();
  }

  /// 获取字帖练习
  Future<PracticeEntity?> getPractice(String id) {
    return _repository.get(id);
  }

  /// 检查标题是否已存在
  ///
  /// 如果提供了 excludeId，则排除该ID的记录
  Future<bool> isTitleExists(String title, {String? excludeId}) {
    return _repository.isTitleExists(title, excludeId: excludeId);
  }

  /// 加载字帖（包含解析后的页面数据）
  Future<Map<String, dynamic>?> loadPractice(String id) {
    return _repository.loadPractice(id);
  }

  /// 根据字段查询字帖记录
  Future<List<Map<String, dynamic>>> queryByField(
    String field,
    String operator,
    dynamic value,
  ) {
    return _repository.queryByField(field, operator, value);
  }

  /// 查询字帖练习
  Future<List<PracticeEntity>> queryPractices(PracticeFilter filter) {
    return _repository.query(filter);
  }

  /// 保存字帖练习
  Future<PracticeEntity> savePractice({
    String? id,
    required String title,
    List<Map<String, dynamic>> pages = const [],
    List<String> tags = const [],
    Uint8List? thumbnail,
  }) async {
    debugPrint('=== PracticeService.savePractice 开始 ===');
    debugPrint(
        '参数: id=$id, title=$title, pages数量=${pages.length}, tags=$tags, 有缩略图=${thumbnail != null}');

    // 如果是新字帖或ID为空，创建新的字帖
    if (id == null || id.isEmpty) {
      debugPrint('检测到空 ID，将创建新字帖');
      final newPractice = await createPractice(
        title: title,
        tags: tags,
      );
      debugPrint('创建完成，新ID=${newPractice.id}');

      // 如果提供了页面数据，更新页面
      if (pages.isNotEmpty) {
        debugPrint('检测到页面数据，将更新页面');
        final updatedPractice = newPractice.copyWith(pages: pages);
        debugPrint('准备保存更新后的实体，调用 _repository.save...');
        final result = await _repository.save(updatedPractice);
        debugPrint('_repository.save 调用成功，返回ID=${result.id}');

        // 保存缩略图
        if (thumbnail != null && thumbnail.isNotEmpty) {
          debugPrint('准备保存缩略图, 大小=${thumbnail.length} 字节');
          final compressedThumbnail = await _compressThumbnail(thumbnail);
          debugPrint('压缩后缩略图大小=${compressedThumbnail.length} 字节');
          await _storageService.saveCoverThumbnail(
              result.id, compressedThumbnail);
          debugPrint('已保存新字帖缩略图到文件系统: ${result.id}');
        }

        debugPrint('=== PracticeService.savePractice 完成(更新页面分支) ===');
        return result;
      }

      // 保存缩略图
      if (thumbnail != null && thumbnail.isNotEmpty) {
        debugPrint('准备保存缩略图, 大小=${thumbnail.length} 字节');
        final compressedThumbnail = await _compressThumbnail(thumbnail);
        debugPrint('压缩后缩略图大小=${compressedThumbnail.length} 字节');
        await _storageService.saveCoverThumbnail(
            newPractice.id, compressedThumbnail);
        debugPrint('已保存新字帖缩略图到文件系统: ${newPractice.id}');
      }

      debugPrint('=== PracticeService.savePractice 完成(无页面分支) ===');
      return newPractice;
    }

    // 如果是现有字帖，获取字帖数据
    debugPrint('检测到现有ID=$id，将更新字帖');
    final existingPractice = await _repository.get(id);
    if (existingPractice == null) {
      debugPrint('错误: 无法找到ID=$id的字帖');
      throw Exception('无法找到指定的字帖: $id');
    }
    debugPrint(
        '找到现有字帖: ${existingPractice.title}, 创建时间=${existingPractice.createTime}');

    // 更新字帖数据
    final updatedPractice = existingPractice.copyWith(
      title: title,
      pages: pages,
      tags: tags,
      updateTime: DateTime.now(),
    );
    debugPrint('创建了更新后的实体, 准备调用 _repository.save...');

    // 保存到数据库
    final result = await _repository.save(updatedPractice);
    debugPrint('_repository.save 调用成功，返回ID=${result.id}');

    // 保存缩略图
    if (thumbnail != null && thumbnail.isNotEmpty) {
      debugPrint('准备保存缩略图, 大小=${thumbnail.length} 字节');
      final compressedThumbnail = await _compressThumbnail(thumbnail);
      debugPrint('压缩后缩略图大小=${compressedThumbnail.length} 字节');
      await _storageService.saveCoverThumbnail(result.id, compressedThumbnail);
      debugPrint('已保存现有字帖缩略图到文件系统: ${result.id}');
    }

    debugPrint('=== PracticeService.savePractice 完成(更新字帖分支) ===');
    return result;
  }

  /// - thumbnail: 缩略图数据
  ///
  /// 返回包含id的Map
  Future<Map<String, dynamic>> savePracticeRaw({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    Uint8List? thumbnail,
  }) async {
    // 确保每个页面都有ID
    for (final page in pages) {
      if (!page.containsKey('id') || page['id'] == null) {
        page['id'] = const Uuid().v4();
      }
    }

    // 先保存到数据库，但不包含缩略图
    final result = await _repository.savePracticeRaw(
      id: id,
      title: title,
      pages: pages,
      thumbnail: null, // 不再将缩略图保存到数据库
    );

    // 如果有缩略图，单独保存到文件系统
    if (thumbnail != null && thumbnail.isNotEmpty && result.containsKey('id')) {
      final practiceId = result['id'] as String;
      await _storageService.saveCoverThumbnail(practiceId, thumbnail);
      debugPrint('已保存缩略图到文件系统: $practiceId');
    }

    return result;
  }

  /// 搜索字帖练习
  Future<List<PracticeEntity>> searchPractices(String query, {int? limit}) {
    return _repository.search(query, limit: limit);
  }

  /// 获取标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) {
    return _repository.suggestTags(prefix, limit: limit);
  }

  /// 切换收藏状态
  Future<PracticeEntity?> toggleFavorite(String id) async {
    try {
      debugPrint('PracticeService.toggleFavorite 开始: ID=$id');
      // 获取当前字帖
      final practice = await _repository.get(id);
      debugPrint('获取字帖结果: ${practice != null ? '成功' : '未找到字帖'}');
      if (practice == null) return null;

      // 打印当前收藏状态
      debugPrint('当前收藏状态: ${practice.isFavorite}');

      // 新的收藏状态
      final newFavoriteStatus = !practice.isFavorite;
      debugPrint('新的收藏状态: $newFavoriteStatus');

      // 尝试使用轻量级方法更新收藏状态
      if (_repository is PracticeRepositoryImpl) {
        final repo = _repository as PracticeRepositoryImpl;
        final success = await repo.updateFavoriteStatus(id, newFavoriteStatus);

        if (success) {
          debugPrint('使用轻量级方法更新收藏状态成功');
          // 返回更新后的实体
          return practice.copyWith(isFavorite: newFavoriteStatus);
        } else {
          debugPrint('轻量级方法失败，尝试完整保存');
        }
      } // 如果轻量级方法不可用或失败，则使用完整的实体保存
      final updated = practice.copyWith(isFavorite: newFavoriteStatus);
      final result = await _repository.save(updated);
      debugPrint('保存结果: 成功');
      return result;
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      return null;
    }
  }

  /// 更新字帖练习
  Future<PracticeEntity> updatePractice(PracticeEntity practice) {
    return _repository.save(practice);
  }

  /// 批量更新字帖练习
  Future<List<PracticeEntity>> updatePractices(List<PracticeEntity> practices) {
    return _repository.saveMany(practices);
  }

  /// 保存字帖
  ///
  /// 参数:
  /// - id: 字帖ID，为null时创建新字帖
  /// - title: 字帖标题
  /// - pages: 字帖页面数据

  /// 压缩缩略图
  ///
  /// 将图片等比例压缩，使其最大边长为300像素，并转换为JPG格式
  Future<Uint8List> _compressThumbnail(Uint8List originalBytes) async {
    // 解码图片
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) {
      debugPrint('警告: 无法解码缩略图，将使用原始数据');
      return originalBytes;
    }

    // 计算新尺寸，保持纵横比
    const int maxDimension = 300;
    int newWidth, newHeight;

    if (originalImage.width > originalImage.height) {
      // 宽度为主要维度
      newWidth = maxDimension;
      newHeight =
          (originalImage.height * maxDimension / originalImage.width).round();
    } else {
      // 高度为主要维度
      newHeight = maxDimension;
      newWidth =
          (originalImage.width * maxDimension / originalImage.height).round();
    }

    // 调整图片大小
    final resizedImage = img.copyResize(
      originalImage,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // 编码为JPG格式，质量范围0-100
    final jpgBytes = img.encodeJpg(resizedImage, quality: 85);

    debugPrint(
        '缩略图已压缩: ${originalImage.width}x${originalImage.height} -> ${newWidth}x$newHeight');
    debugPrint('文件大小: ${originalBytes.length} -> ${jpgBytes.length} 字节');

    return Uint8List.fromList(jpgBytes);
  }
  
  /// 迁移数据库中的图像路径从绝对路径到相对路径
  /// 
  /// 用于数据迁移，将存储在数据库中的绝对路径转换为相对路径以提高可移植性
  Future<PathMigrationResult> migrateImagePathsToRelative({
    void Function(int processed, int total)? onProgress,
  }) async {
    if (_repository is PracticeRepositoryImpl) {
      final repo = _repository as PracticeRepositoryImpl;
      return await repo.migrateImagePathsToRelative(onProgress: onProgress);
    } else {
      // 如果不是具体实现类，返回失败结果
      return PathMigrationResult.failure(
        errorMessage: '当前Repository实现不支持路径迁移功能',
      );
    }
  }
}
