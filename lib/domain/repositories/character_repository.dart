import '../entities/character.dart';

abstract class CharacterRepository {
  Future<String> insertCharacter(Character character);
  Future<Character?> getCharacter(String id);
  Future<List<Character>> getCharactersByWorkId(String workId);
  Future<void> updateCharacter(Character character);
  Future<void> deleteCharacter(String id);
}

