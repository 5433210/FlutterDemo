import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/repositories/character_repository.dart';

/// 字形管理服务
class CharacterService {
  final CharacterRepository _repository;

  CharacterService({
    required CharacterRepository repository,
  }) : _repository = repository;

  /// 创建新字形
  Future<CharacterEntity> createCharacter({
    required String char,
    required String workId,
    CharacterRegion? region,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final character = CharacterEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      char: char,
      workId: workId,
      region: region,
      tags: tags,
      createTime: now,
      updateTime: now,
    );
    return await _repository.save(character);
  }

  /// 删除字形
  Future<void> deleteCharacter(String id) {
    return _repository.delete(id);
  }

  /// 批量删除字形
  Future<void> deleteCharacters(List<String> ids) {
    return _repository.deleteMany(ids);
  }

  /// 复制字形
  Future<CharacterEntity> duplicateCharacter(String id,
      {String? newWorkId}) async {
    final character = await _repository.get(id);
    if (character == null) {
      throw Exception('Character not found');
    }

    final now = DateTime.now();
    final copy = character.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workId: newWorkId,
      createTime: now,
      updateTime: now,
    );

    return _repository.save(copy);
  }

  /// 获取所有标签
  Future<Set<String>> getAllTags() {
    return _repository.getAllTags();
  }

  /// 获取单个字形
  Future<CharacterEntity?> getCharacter(String id) {
    return _repository.get(id);
  }

  /// 获取字形列表
  Future<List<CharacterEntity>> getCharacters({
    CharacterFilter? filter,
    bool forceRefresh = false,
  }) {
    if (filter != null) {
      return _repository.query(filter);
    }
    return _repository.getAll();
  }

  /// 按标签搜索字形
  Future<List<CharacterEntity>> getCharactersByTags(List<String> tags) {
    return _repository.getByTags(tags.toSet());
  }

  /// 获取作品相关字形
  Future<List<CharacterEntity>> getCharactersByWork(String workId) {
    return _repository.getByWorkId(workId);
  }

  /// 获取字形统计信息
  Future<Map<String, int>> getCharacterStats() async {
    final characters = await _repository.getAll();
    final tags = await _repository.getAllTags();

    return {
      'total': characters.length,
      'tags': tags.length,
      'works': characters
          .where((c) => c.workId != null)
          .map((c) => c.workId!)
          .toSet()
          .length,
      'unassigned': characters.where((c) => c.workId == null).length,
    };
  }

  /// 获取字形数量
  Future<int> getCount({CharacterFilter? filter}) {
    return _repository.count(filter);
  }

  /// 搜索字形
  Future<List<CharacterEntity>> searchCharacters(String query, {int? limit}) {
    return _repository.search(query, limit: limit);
  }

  /// 获取标签建议
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) {
    return _repository.suggestTags(prefix, limit: limit);
  }

  /// 更新字形
  Future<CharacterEntity> updateCharacter(CharacterEntity character) {
    return _repository.save(character.copyWith(
      updateTime: DateTime.now(),
    ));
  }

  /// 批量更新字形
  Future<List<CharacterEntity>> updateCharacters(
      List<CharacterEntity> characters) {
    final now = DateTime.now();
    final updated = characters.map((c) => c.copyWith(updateTime: now)).toList();
    return _repository.saveMany(updated);
  }
}
