import '../../../domain/models/practice/practice_entity.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../domain/repositories/practice_repository.dart';

/// 字帖练习服务
class PracticeService {
  final PracticeRepository _repository;

  const PracticeService({
    required PracticeRepository repository,
  }) : _repository = repository;

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

  /// 查询字帖练习
  Future<List<PracticeEntity>> queryPractices(PracticeFilter filter) {
    return _repository.query(filter);
  }

  /// 搜索字帖练习
  Future<List<PracticeEntity>> searchPractices(String query, {int? limit}) {
    return _repository.search(query, limit: limit);
  }

  /// 获取标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) {
    return _repository.suggestTags(prefix, limit: limit);
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
