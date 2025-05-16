import 'package:flutter/foundation.dart';

import '../../../domain/models/practice/practice_entity.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../domain/repositories/practice_repository.dart';
import '../../repositories/practice_repository_impl.dart';

/// 字帖练习服务
class PracticeService {
  // 领域层仓库
  final PracticeRepository _repository;

  /// 构造函数
  const PracticeService({
    required PracticeRepository repository,
  }) : _repository = repository;

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
    final practice = PracticeEntity.create(
      title: title,
      tags: tags,
      status: status,
    );
    return _repository.save(practice);
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

  /// 保存字帖
  ///
  /// 参数:
  /// - id: 字帖ID，为null时创建新字帖
  /// - title: 字帖标题
  /// - pages: 字帖页面数据
  /// - thumbnail: 缩略图数据
  ///
  /// 返回包含id的Map
  Future<Map<String, dynamic>> savePractice({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    Uint8List? thumbnail,
  }) {
    // 确保每个页面都有ID
    for (final page in pages) {
      if (!page.containsKey('id') || page['id'] == null) {
        page['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
    }

    return _repository.savePracticeRaw(
      id: id,
      title: title,
      pages: pages,
      thumbnail: thumbnail,
    );
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
}
