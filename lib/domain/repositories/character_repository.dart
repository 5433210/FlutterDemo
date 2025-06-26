import '../models/character/character_entity.dart';
import '../models/character/character_filter.dart';
import '../models/character/character_region.dart';

/// 字形仓库接口
abstract class CharacterRepository {
  /// 获取字形数量
  Future<int> count(CharacterFilter? filter);

  /// 创建字形
  Future<CharacterEntity> create(CharacterEntity character);

  /// 删除字形
  Future<void> delete(String id);

  /// 批量删除字符
  Future<void> deleteBatch(List<String> ids);

  /// 批量删除
  Future<void> deleteMany(List<String> ids);

  /// 根据ID查找单个字符
  Future<CharacterEntity?> findById(String id);

  /// 根据作品ID查找字符
  Future<List<CharacterEntity>> findByWorkId(String workId);

  /// 获取字形
  Future<CharacterEntity?> get(String id);

  /// 获取所有字形
  Future<List<CharacterEntity>> getAll();

  /// 根据作品ID获取字形
  Future<List<CharacterEntity>> getByWorkId(String workId);

  /// 根据页面ID获取字符区域
  Future<List<CharacterRegion>> getRegionsByPageId(String pageId);

  /// 获取字符的所有区域信息
  Future<List<CharacterRegion>> getRegionsByWorkId(String workId);

  /// 条件查询
  Future<List<CharacterEntity>> query(CharacterFilter filter);

  /// 更新字形
  Future<CharacterEntity> save(CharacterEntity character);

  /// 批量更新
  Future<List<CharacterEntity>> saveMany(List<CharacterEntity> characters);

  /// 搜索字形
  Future<List<CharacterEntity>> search(String query, {int? limit});

  /// 精确匹配搜索字形（查找字符字段精确等于查询词的记录）
  Future<List<CharacterEntity>> searchExact(String query, {int? limit});

  /// 更新字符区域
  Future<void> updateRegion(CharacterRegion region);
}
