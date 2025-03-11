import '../../domain/models/character/character_entity.dart';
import '../../domain/models/character/character_filter.dart';
import '../../domain/repositories/character_repository.dart';
import '../persistence/database_interface.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final DatabaseInterface _database;

  CharacterRepositoryImpl(this._database);

  @override
  Future<void> close() => _database.close();

  @override
  Future<int> count(CharacterFilter? filter) async {
    return _database.count('characters', filter?.toJson() ?? {});
  }

  @override
  Future<CharacterEntity> create(CharacterEntity character) async {
    await _database.save('characters', character.id!, character.toJson());
    return character;
  }

  @override
  Future<void> delete(String id) => _database.delete('characters', id);

  @override
  Future<void> deleteMany(List<String> ids) =>
      _database.deleteMany('characters', ids);

  @override
  Future<CharacterEntity> duplicate(String id, {String? newId}) async {
    final character = await get(id);
    if (character == null) throw Exception('Character not found: $id');

    final now = DateTime.now();
    return create(character.copyWith(
      id: newId,
      createTime: now,
      updateTime: now,
    ));
  }

  @override
  Future<CharacterEntity?> get(String id) async {
    final json = await _database.get('characters', id);
    if (json == null) return null;
    return CharacterEntity.fromJson(json);
  }

  @override
  Future<List<CharacterEntity>> getAll() async {
    final items = await _database.getAll('characters');
    return items.map((e) => CharacterEntity.fromJson(e)).toList();
  }

  @override
  Future<Set<String>> getAllTags() async {
    final items = await _database.getAll('characters');
    return items
        .map((e) => CharacterEntity.fromJson(e))
        .expand((e) => e.tags)
        .toSet();
  }

  @override
  Future<List<CharacterEntity>> getByTags(Set<String> tags) async {
    const filter = CharacterFilter();
    return query(filter);
  }

  @override
  Future<List<CharacterEntity>> getByWorkId(String workId) async {
    const filter = CharacterFilter();
    return query(filter);
  }

  @override
  Future<List<CharacterEntity>> query(CharacterFilter filter) async {
    final items = await _database.query('characters', filter.toJson());
    return items.map((e) => CharacterEntity.fromJson(e)).toList();
  }

  @override
  Future<CharacterEntity> save(CharacterEntity character) async {
    await _database.save('characters', character.id!, character.toJson());
    return character;
  }

  @override
  Future<List<CharacterEntity>> saveMany(
      List<CharacterEntity> characters) async {
    final data =
        Map.fromEntries(characters.map((e) => MapEntry(e.id!, e.toJson())));
    await _database.saveMany('characters', data);
    return characters;
  }

  @override
  Future<List<CharacterEntity>> search(String query, {int? limit}) async {
    const filter = CharacterFilter();
    return this.query(filter);
  }

  @override
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) async {
    final allTags = await getAllTags();
    return allTags.where((tag) => tag.startsWith(prefix)).take(limit).toList();
  }
}
