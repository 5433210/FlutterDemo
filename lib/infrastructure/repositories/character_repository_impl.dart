import '../../domain/entities/character.dart';
import '../../domain/models/character/character_filter.dart';
import '../../domain/models/collected_character.dart';
import '../../domain/repositories/character_repository.dart';
import '../persistence/database_interface.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final DatabaseInterface _db;

  CharacterRepositoryImpl(this._db);

  @override
  Future<void> deleteCharacter(String id) async {
    await _db.deleteCharacter(id);
  }

  @override
  Future<void> deleteCharacters(List<String> ids) async {
    // 批量删除字符
    for (final id in ids) {
      await _db.deleteCharacter(id);
    }
  }

  @override
  Future<Character?> getCharacter(String id) async {
    final map = await _db.getCharacter(id);
    if (map == null) return null;
    return Character.fromMap(map);
  }

  @override
  Future<List<CollectedCharacter>> getCharacters({
    CharacterFilter? filter,
    bool forceRefresh = false,
  }) async {
    // 构建查询条件
    final conditions = <String, dynamic>{};
    if (filter != null) {
      if (filter.searchQuery?.isNotEmpty == true) {
        conditions['search'] = filter.searchQuery;
      }
      if (filter.styles.isNotEmpty) {
        conditions['styles'] = filter.styles;
      }
      if (filter.tools.isNotEmpty) {
        conditions['tools'] = filter.tools;
      }
    }

    // 添加排序条件
    final sortField =
        filter?.sortOption == SortOption.character ? 'char' : 'create_time';

    // 从数据库获取数据
    final maps = await _db.queryCharacters(
      conditions: conditions,
      orderBy: '$sortField DESC',
    );

    // 转换为领域模型
    return maps
        .map((map) => CollectedCharacter.fromCharacter(
              Character.fromMap(map),
            ))
        .toList();
  }

  @override
  Future<List<Character>> getCharactersByWorkId(String workId) async {
    final maps = await _db.getCharactersByWorkId(workId);
    return maps.map((map) => Character.fromMap(map)).toList();
  }

  @override
  Future<String> insertCharacter(Character character) async {
    return await _db.insertCharacter(character.toMap());
  }

  @override
  Future<void> updateCharacter(Character character) async {
    await _db.updateCharacter(character.id!, character.toMap());
  }
}
