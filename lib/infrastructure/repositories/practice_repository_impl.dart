import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';
import '../persistence/database_interface.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final DatabaseInterface _db;

  PracticeRepositoryImpl(this._db);

  @override
  Future<void> deletePractice(String id) async {
    await _db.deletePractice(id);
  }

  @override
  Future<Practice?> getPractice(String id) async {
    final map = await _db.getPractice(id);
    if (map == null) return null;
    return Practice.fromMap(map);
  }

  @override
  Future<List<Practice>> getPractices({
    List<String>? characterIds,
    String? title,
    int? limit,
    int? offset,
  }) async {
    final maps = await _db.getPractices(
      characterIds: characterIds,
      title: title,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Practice.fromMap(map)).toList();
  }

  @override
  Future<String> insertPractice(Practice practice) async {
    return await _db.insertPractice(practice.toMap());
  }

  @override
  Future<void> updatePractice(Practice practice) async {
    await _db.updatePractice(practice.id, practice.toMap());
  }
}
