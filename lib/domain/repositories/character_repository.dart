import '../entities/character.dart';
import '../models/character/character_filter.dart';
import '../models/collected_character.dart';

abstract class CharacterRepository {
  Future<void> deleteCharacter(String id);
  Future<void> deleteCharacters(List<String> ids);
  Future<Character?> getCharacter(String id);
  Future<List<CollectedCharacter>> getCharacters({
    CharacterFilter? filter,
    bool forceRefresh = false,
  });
  Future<List<Character>> getCharactersByWorkId(String workId);

  Future<String> insertCharacter(Character character);

  Future<void> updateCharacter(Character character);
}
