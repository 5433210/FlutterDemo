import 'dart:typed_data';

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

  /// 检查标题是否存在
  Future<bool> isTitleExists(String title, {String? excludeId});

  /// 加载字帖（包含解析后的页面数据）
  Future<Map<String, dynamic>?> loadPractice(String id);

  /// 查询练习
  Future<List<PracticeEntity>> query(PracticeFilter filter);

  /// 查询练习列表（不包含 pages 字段，优化性能）
  Future<List<PracticeEntity>> queryList(PracticeFilter filter);

  /// 根据字段查询
  Future<List<Map<String, dynamic>>> queryByField(
    String field,
    String operator,
    dynamic value,
  );

  /// 更新练习
  Future<PracticeEntity> save(PracticeEntity practice);

  /// 批量更新
  Future<List<PracticeEntity>> saveMany(List<PracticeEntity> practices);

  /// 保存字帖（原始数据版本）
  Future<Map<String, dynamic>> savePracticeRaw({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    Map<String, dynamic>? metadata,
    Uint8List? thumbnail,
  });

  /// 搜索练习
  Future<List<PracticeEntity>> search(String query, {int? limit});

  /// 修复现有字帖的pageCount字段（一次性数据迁移）
  Future<void> fixPageCountForAllPractices();

  /// 标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10});
}
