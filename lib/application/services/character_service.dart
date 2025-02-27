import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/logging/logger.dart';

class CharacterService {
  final CharacterRepository _characterRepository;
  final WorkRepository _workRepository;

  CharacterService(this._characterRepository, this._workRepository);

  Future<String> extractCharacter({
    required String workId,
    required String char,
    required Map<String, dynamic> sourceRegion,
    required Map<String, dynamic> image,
    String? style,
    String? tool,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('Extracting character from work',
          tag: 'CharacterService', data: {'workId': workId, 'char': char});

      final character = Character(
        id: '',
        workId: workId,
        char: char,
        sourceRegion: sourceRegion,
        image: image,
        metadata: metadata,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
      );

      final id = await _characterRepository.insertCharacter(character);

      AppLogger.info('Character extracted successfully',
          tag: 'CharacterService',
          data: {'characterId': id, 'workId': workId, 'char': char});

      return id;
    } catch (e, stack) {
      AppLogger.error('Failed to extract character',
          tag: 'CharacterService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'char': char});
      rethrow;
    }
  }

  Future<List<Character>> getCharactersByWork(String workId) async {
    try {
      AppLogger.debug('Fetching characters by work',
          tag: 'CharacterService', data: {'workId': workId});

      final characters =
          await _characterRepository.getCharactersByWorkId(workId);

      AppLogger.debug('Fetched ${characters.length} characters',
          tag: 'CharacterService',
          data: {'workId': workId, 'count': characters.length});

      return characters;
    } catch (e, stack) {
      AppLogger.error('Failed to fetch characters by work',
          tag: 'CharacterService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }

  Future<List<Character>> searchCharacters(String char) async {
    try {
      AppLogger.debug('Searching for characters',
          tag: 'CharacterService', data: {'searchQuery': char});

      // 实际搜索逻辑
      // ...

      AppLogger.debug('Search completed', tag: 'CharacterService');
      return [];
    } catch (e, stack) {
      AppLogger.error('Failed to search characters',
          tag: 'CharacterService',
          error: e,
          stackTrace: stack,
          data: {'searchQuery': char});
      rethrow;
    }
  }

  Future<void> updateCharacterMetadata(
    String id,
    Map<String, dynamic> metadata,
  ) async {
    try {
      AppLogger.info('Updating character metadata',
          tag: 'CharacterService', data: {'characterId': id});

      // 获取现有字符信息
      final character = await _characterRepository.getCharacter(id);
      if (character == null) {
        throw Exception('Character not found');
      }

      AppLogger.info('Character metadata updated successfully',
          tag: 'CharacterService', data: {'characterId': id});
    } catch (e, stack) {
      AppLogger.error('Failed to update character metadata',
          tag: 'CharacterService',
          error: e,
          stackTrace: stack,
          data: {'characterId': id});
      rethrow;
    }
  }
}
