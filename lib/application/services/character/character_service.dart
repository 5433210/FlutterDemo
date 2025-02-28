import '../../../domain/entities/character.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../infrastructure/logging/logger.dart';

class CharacterService {
  final CharacterRepository _characterRepository;
  final WorkRepository _workRepository;

  CharacterService(this._characterRepository, this._workRepository);

  Future<String> createCharacter(Character character) async {
    return '';
  }

  Future<bool> deleteCharacter(String id) async {
    AppLogger.info('Deleting character',
        tag: 'CharacterService', data: {'characterId': id});

    final character = await _characterRepository.getCharacter(id);
    if (character == null) {
      AppLogger.debug('Character not found',
          tag: 'CharacterService', data: {'characterId': id});
      return false;
    }

    await _characterRepository.deleteCharacter(id);
    return true;
  }

  Future<String> extractCharacter({
    required String workId,
    required String char,
    required Map<String, dynamic> sourceRegion,
    required Map<String, dynamic> image,
    String? style,
    String? tool,
    Map<String, dynamic>? metadata,
  }) async {
    return '';
  }

  Future<List<Character>> getAll() async {
    return [];
  }

  Future<Character?> getCharacter(String id) async {
    try {
      AppLogger.debug('Fetching character',
          tag: 'CharacterService', data: {'characterId': id});
      final character = await _characterRepository.getCharacter(id);
      if (character == null) {
        AppLogger.debug('Character not found',
            tag: 'CharacterService', data: {'characterId': id});
        return null;
      }
      AppLogger.debug('Character found',
          tag: 'CharacterService',
          data: {'characterId': id, 'character': character.char});
      return character;
    } catch (e, stack) {
      AppLogger.error('Failed to get character',
          tag: 'CharacterService',
          error: e,
          stackTrace: stack,
          data: {'characterId': id});
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

  Future<List<Character>> getCharactersByWorkId(String workId) async {
    try {
      AppLogger.debug('Fetching characters by workId',
          tag: 'CharacterService', data: {'workId': workId});
      final list = await _characterRepository.getCharactersByWorkId(workId);
      AppLogger.debug('Fetched ${list.length} characters for workId $workId',
          tag: 'CharacterService');
      return list;
    } catch (e, stack) {
      AppLogger.error('Failed to get characters by workId',
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

  Future<void> updateCharacter(String id, Character character) async {
    return;
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
