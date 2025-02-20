import 'package:demo/infrastructure/persistence/database_interface.dart';

import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final DatabaseInterface _db;

  CharacterRepositoryImpl(this._db);

  @override
  Future<String> insertCharacter(Character character) async {
    return await _db.insertCharacter(character.toMap());
  }

  @override
  Future<Character?> getCharacter(String id) async {
    final map = await _db.getCharacter(id);
    if (map == null) return null;
    return Character.fromMap(map);
  }

  @override
  Future<List<Character>> getCharactersByWorkId(String workId) async {
    final maps = await _db.getCharactersByWorkId(workId);
    return maps.map((map) => Character.fromMap(map)).toList();
  }

  @override
  Future<void> updateCharacter(Character character) async {
    await _db.updateCharacter(character.id, character.toMap());
  }

  @override
  Future<void> deleteCharacter(String id) async {
    await _db.deleteCharacter(id);
  }
}