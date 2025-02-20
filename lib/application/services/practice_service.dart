import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/character_repository.dart';

class PracticeService {
  final PracticeRepository _practiceRepository;
  final CharacterRepository _characterRepository;

  PracticeService(this._practiceRepository, this._characterRepository);

  Future<String> createPractice(String title, List<Map<String, dynamic>> pages) async {
    final practice = Practice(
      id: '',
      title: title,
      pages: pages,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      metadata: {
        'version': '1.0',
        'lastPrintTime': null,
        'printCount': 0,
      },
    );
    
    return await _practiceRepository.insertPractice(practice);
  }

  Future<void> addCharacterToPractice(String practiceId, String charId, Map<String, dynamic> position) async {
    final practice = await _practiceRepository.getPractice(practiceId);
    if (practice == null) throw Exception('Practice not found');

    final character = await _characterRepository.getCharacter(charId);
    if (character == null) throw Exception('Character not found');

    // Update practice metadata to track character usage
    final metadata = practice.metadata ?? {};
    final usedChars = (metadata['usedCharacters'] as List<dynamic>?) ?? [];
    usedChars.add({
      'charId': charId,
      'useTime': DateTime.now().toIso8601String(),
      'position': position,
    });
    metadata['usedCharacters'] = usedChars;

    // Update practice
    final updatedPractice = Practice(
      id: practice.id,
      title: practice.title,
      pages: practice.pages,
      metadata: metadata,
      createTime: practice.createTime,
      updateTime: DateTime.now(),
    );

    await _practiceRepository.updatePractice(updatedPractice);
  }

  Future<List<Practice>> getRecentPractices({int limit = 10}) async {
    return await _practiceRepository.getPractices(
      limit: limit,
    );
  }

  Future<List<Practice>> searchPractices(String query) async {
    return await _practiceRepository.getPractices(
      title: query,
    );
  }

  Future<void> updatePracticePages(String id, List<Map<String, dynamic>> pages) async {
    final practice = await _practiceRepository.getPractice(id);
    if (practice == null) throw Exception('Practice not found');

    final updatedPractice = Practice(
      id: practice.id,
      title: practice.title,
      pages: pages,
      metadata: practice.metadata,
      createTime: practice.createTime,
      updateTime: DateTime.now(),
    );

    await _practiceRepository.updatePractice(updatedPractice);
  }

  Future<List<Practice>> getPracticesByCharacters(List<String> characterIds) async {
    if (characterIds.isEmpty) {
      return [];
    }

    // Get practices that contain any of the specified characters
    final practices = await _practiceRepository.getPractices(
      characterIds: characterIds,
    );

    // Sort by updateTime descending (most recent first)
    practices.sort((a, b) => b.updateTime.compareTo(a.updateTime));

    return practices;
  }

}