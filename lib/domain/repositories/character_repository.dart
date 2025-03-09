import '../models/character/character_entity.dart';
import '../models/character/character_filter.dart';

/// 字形仓库接口
abstract class CharacterRepository {
  /// 关闭仓库
  Future<void> close();

  /// 获取字形数量
  Future<int> count(CharacterFilter? filter);

  /// 创建字形
  Future<CharacterEntity> create(CharacterEntity character);

  /// 删除字形
  Future<void> delete(String id);

  /// 批量删除
  Future<void> deleteMany(List<String> ids);

  /// 复制字形
  Future<CharacterEntity> duplicate(String id, {String? newId});

  /// 获取字形
  Future<CharacterEntity?> get(String id);

  /// 获取所有字形
  Future<List<CharacterEntity>> getAll();

  /// 获取所有标签
  Future<Set<String>> getAllTags();

  /// 根据标签获取字形
  Future<List<CharacterEntity>> getByTags(Set<String> tags);

  /// 根据作品ID获取字形
  Future<List<CharacterEntity>> getByWorkId(String workId);

  /// 条件查询
  Future<List<CharacterEntity>> query(CharacterFilter filter);

  /// 更新字形
  Future<CharacterEntity> save(CharacterEntity character);

  /// 批量更新
  Future<List<CharacterEntity>> saveMany(List<CharacterEntity> characters);

  /// 搜索字形
  Future<List<CharacterEntity>> search(String query, {int? limit});

  /// 标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10});
}
