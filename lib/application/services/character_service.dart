import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/work_repository.dart';

class CharacterService {
  final CharacterRepository _characterRepository;
  final WorkRepository _workRepository;

  CharacterService(this._characterRepository, this._workRepository);

  Future<String> extractCharacter(
    String workId,
    String char,
    Map<String, dynamic> sourceRegion,
    Map<String, dynamic> image, {
    String? pinyin,
    Map<String, dynamic>? metadata,
  }) async {
    // Verify work exists
    final work = await _workRepository.getWork(workId);
    if (work == null) throw Exception('Work not found');

    final character = Character(
      id: '',
      workId: workId,
      char: char,
      pinyin: pinyin,
      sourceRegion: sourceRegion,
      image: image,
      metadata: metadata ?? {
        'extractTime': DateTime.now().toIso8601String(),
        'confidence': 1.0,
        'tags': [],
      },
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );

    return await _characterRepository.insertCharacter(character);
  }

  Future<List<Character>> getCharactersByWork(String workId) async {
    return await _characterRepository.getCharactersByWorkId(workId);
  }

  Future<List<Character>> searchCharacters(String char) async {
    // TODO: Implement character search
    throw UnimplementedError();
  }

  Future<void> updateCharacterMetadata(
    String id, 
    Map<String, dynamic> metadata,
  ) async {
    final character = await _characterRepository.getCharacter(id);
    if (character == null) throw Exception('Character not found');

    final updatedCharacter = Character(
      id: character.id,
      workId: character.workId,
      char: character.char,
      pinyin: character.pinyin,
      sourceRegion: character.sourceRegion,
      image: character.image,
      metadata: {...character.metadata ?? {}, ...metadata},
      createTime: character.createTime,
      updateTime: DateTime.now(),
    );

    await _characterRepository.updateCharacter(updatedCharacter);
  }

  Future<Map<String, List<Character>>> getCharactersUsageInPractices(
    String charId,
  ) async {
    // TODO: Implement character usage tracking
    throw UnimplementedError();
  }
}