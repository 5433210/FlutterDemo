import '../entities/practice.dart';

abstract class PracticeRepository {
  Future<String> insertPractice(Practice practice);
  Future<Practice?> getPractice(String id);
  Future<List<Practice>> getPractices({
    String? title,
    List<String>? characterIds,
    int? limit,
    int? offset,
  });
  Future<void> updatePractice(Practice practice);
  Future<void> deletePractice(String id);
}

