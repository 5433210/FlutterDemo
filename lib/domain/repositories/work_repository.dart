import '../models/work/work_entity.dart';
import '../models/work/work_filter.dart';

/// 作品仓库接口
abstract class WorkRepository {
  /// 关闭仓库
  Future<void> close();

  /// 获取作品数量
  Future<int> count(WorkFilter? filter);

  /// 创建作品
  Future<WorkEntity> create(WorkEntity work);

  /// 删除作品
  Future<void> delete(String id);

  /// 批量删除
  Future<void> deleteMany(List<String> ids);

  /// 复制作品
  Future<WorkEntity> duplicate(String id, {String? newId});

  /// 获取作品
  Future<WorkEntity?> get(String id);

  /// 获取所有作品
  Future<List<WorkEntity>> getAll();

  /// 获取所有标签
  Future<Set<String>> getAllTags();

  /// 获取某些标签的作品
  Future<List<WorkEntity>> getByTags(Set<String> tags);

  /// 查询作品
  Future<List<WorkEntity>> query(WorkFilter filter);

  /// 更新作品
  Future<WorkEntity> save(WorkEntity work);

  /// 批量更新
  Future<List<WorkEntity>> saveMany(List<WorkEntity> works);

  /// 搜索作品
  Future<List<WorkEntity>> search(String query, {int? limit});

  /// 标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10});

  /// 更新作品的图片统计信息
  Future<void> updateImageStats({
    required String workId,
    required int imageCount,
    String? firstImageId,
    DateTime? lastImageUpdateTime,
  });
}
