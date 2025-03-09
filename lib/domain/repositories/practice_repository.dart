import '../models/practice/practice_entity.dart';
import '../models/practice/practice_filter.dart';

/// 字帖练习仓库接口
abstract class PracticeRepository {
  /// 关闭仓库
  Future<void> close();

  /// 获取练习数量
  Future<int> count(PracticeFilter? filter);

  /// 创建练习
  Future<PracticeEntity> create(PracticeEntity practice);

  /// 删除练习
  Future<void> delete(String id);

  /// 批量删除
  Future<void> deleteMany(List<String> ids);

  /// 复制练习
  Future<PracticeEntity> duplicate(String id, {String? newId});

  /// 获取练习
  Future<PracticeEntity?> get(String id);

  /// 获取所有练习
  Future<List<PracticeEntity>> getAll();

  /// 获取所有标签
  Future<Set<String>> getAllTags();

  /// 获取某些标签的练习
  Future<List<PracticeEntity>> getByTags(Set<String> tags);

  /// 查询练习
  Future<List<PracticeEntity>> query(PracticeFilter filter);

  /// 更新练习
  Future<PracticeEntity> save(PracticeEntity practice);

  /// 批量更新
  Future<List<PracticeEntity>> saveMany(List<PracticeEntity> practices);

  /// 搜索练习
  Future<List<PracticeEntity>> search(String query, {int? limit});

  /// 标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10});
}
